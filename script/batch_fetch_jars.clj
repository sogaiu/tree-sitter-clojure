(ns batch-fetch-jars
  (:require [babashka.fs :as fs]
            [babashka.process :as proc]
            [clojure.java.io :as cji]
            [conf :as cnf]))

(def default-n 10)

;; XXX: duplicate code
(def skip-urls
  (do
    (when (not (fs/exists? cnf/clojars-skip-urls))
      (spit cnf/clojars-skip-urls ""))
    (set (fs/read-all-lines (fs/file cnf/clojars-skip-urls)))))

;; XXX: duplicate code
(defn skip-url?
  [url]
  (or (skip-urls url)
      ;; XXX: could also remove from latest-release-jar-urls.txt file?
      (re-matches #"^.*lein-template.*" url)))

(defn parse-url
  [url]
  (when-let [[_ container-path jar-name]
             (re-matches #"^https://repo.clojars.org/(.*)/([^/]+\.jar)" url)]
    [container-path jar-name]))

;; this allows us to use a single connection to fetch multple jars
(defn write-curl-file!
  [urls out-file-path]
  (let [out-fp (fs/path out-file-path)]
    (doseq [url urls]
      (when-let [[container-path jar-name] (parse-url url)]
        (let [jar-dir (str cnf/clojars-jars-root "/" container-path)
              jar-path (str jar-dir "/" jar-name)]
          (when-not (fs/exists? jar-path)
            (fs/create-dirs jar-dir)
            ;; XXX: too noisy?
            ;;(when cnf/verbose (println "jar-path:" jar-path))
            (fs/write-bytes out-fp 
                            (.getBytes (str "url = \"" url "\"\n"
                                            "--fail\n"
                                            "--location\n"
                                            "--output " jar-path "\n\n"))
                            {:append true})))))))

(defn -main
  [& _args]
  (when (not (fs/exists? cnf/clojars-jars-root))
    (fs/create-dir cnf/clojars-jars-root))
  (with-open [rdr (cji/reader cnf/clru-list-path)]
    ;; n = -1 means to fetch all remaining
    (let [n (if (empty? *command-line-args*)
              default-n
              (try
                (Integer/parseInt (first *command-line-args*))
                (catch Exception e
                  (println "Failed to parse as integer:"
                           (first *command-line-args*))
                  (System/exit 1))))
          do-all (= -1 n)
          counter (atom n)
          urls (atom [])]
      ;; try to collect enough urls
      (doseq [url (line-seq rdr)
              :while (or do-all (pos? @counter))]
        (when (and (uri? (java.net.URI. url))
                   (not (skip-url? url)))
          (when-let [[container-path jar-name] (parse-url url)]
            (let [jar-path 
                  (str cnf/clojars-jars-root "/" container-path "/" jar-name)]
              ;; XXX: could fetching have failed without cleaning up the jar?
              (when-not (fs/exists? jar-path)
                (swap! urls conj url)
                (swap! counter dec))))))
      (when cnf/verbose (println "Collected" (count @urls) "urls"))
      ;; make the curl file and ask curl to fetch using it
      (let [curl-file (fs/create-temp-file)
            _ (fs/delete-on-exit curl-file)
            _ (write-curl-file! @urls curl-file)]
        (if (zero? (fs/size curl-file))
          (println "Empty curl file, not invoking curl")
          (let [start-time (System/currentTimeMillis)
                p (proc/process "curl" 
                                "--fail-early" ;; want to stop at failures
                                "--config" (str curl-file))
                exit-code (:exit @p)
                duration (- (System/currentTimeMillis) start-time)]
            ;; guarded with this because if curl-file is big, don't
            ;; want to see it
            (when cnf/verbose
              (when-not (zero? exit-code)
                (println (slurp (fs/file curl-file)))))
            (println "Processed in" duration "ms"
                     "with exit code:" exit-code)))))))

