(ns fetch-clojars-code
  (:require [babashka.fs :as fs]
            [babashka.process :as proc]
            [babashka.tasks :as t]
            [clojure.java.io :as cji]
            [conf :as cnf]))

;; default number of jars to fetch
(def default-n 10)

(def skip-urls
  (do
    (when (not (fs/exists? cnf/clojars-skip-urls))
      (spit cnf/clojars-skip-urls ""))
    (set (fs/read-all-lines (fs/file cnf/clojars-skip-urls)))))

(defn skip-url?
  [url]
  (or (skip-urls url)
      ;; XXX: could also remove from latest-release-jar-urls.txt file?
      (re-matches #"^.*lein-template.*" url)))

(defn url->subpath
  [url]
  (when-let [[_ subpath]
             (re-matches #"^https://repo.clojars.org/(.*)" url)]
    subpath))

;; adapted https://gist.github.com/mikeananev/b2026b712ecb73012e680805c56af45f
;; thanks to mikeananev
(defn unzip-file
  [input output]
  (with-open [stream (-> input
                         cji/input-stream
                         java.util.zip.ZipInputStream.)]
    (loop [entry (.getNextEntry stream)]
      (when entry
        (let [save-path (str output File/separatorChar (.getName entry))
              out-file (fs/file save-path)]
          (if (.isDirectory entry)
            (when-not (fs/exists? out-file)
              (fs/create-dirs out-file))
            (when (cnf/clojars-extensions (fs/extension save-path))
              (let [parent-dir
                    (fs/file
                     (.substring save-path 0
                                 (.lastIndexOf save-path
                                               (int File/separatorChar))))]
                (when-not (fs/exists? parent-dir)
                  (fs/create-dirs parent-dir))
                (cji/copy stream out-file))))
          (recur (.getNextEntry stream)))))))

(defn -main
  [& _args]
  (when (not (fs/exists? cnf/clojars-repos-root))
    (fs/create-dir cnf/clojars-repos-root))
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
          counter (atom (inc n))]
      ;; try to retrieve each jar and unzip
      (doseq [url (line-seq rdr)
              :while (or do-all (pos? @counter))]
        (when (and (uri? (java.net.URI. url))
                   (not (skip-url? url)))
          (when-let [subpath (url->subpath url)]
            (let [dest-dir (str cnf/clojars-repos-root "/" subpath)]
              ;; use directory existence to decide whether to process
              (if (fs/exists? dest-dir)
                ;; XXX: too noisy
                (when cnf/verbose #_(println "Skipping:" url) 1)
                (let [_ (when cnf/verbose (println "Fetching:" url))
                      jar-path (fs/create-temp-file)
                      _ (fs/delete-on-exit jar-path)
                      p (proc/process "curl" url
                                      "--fail"
                                      "--location"
                                      "--output" jar-path)
                      exit-code (:exit @p)]
                  (cond
                    ;; 22 is "HTTP page not retrieved" (includes 404)
                    (= 22 exit-code)
                    (do
                      (println "Did not retrieve:" url)
                      (println "curl exit code:" exit-code))
                    ;; XXX: doing this to observe what turns up
                    (not= 0 exit-code)
                    (do
                      (println "Unexpected problem fetching:" url)
                      (println "curl exit code:" exit-code)
                      ;; XXX: or skip?
                      (System/exit 1))
                    ;;
                    :else
                    (try
                      ;; crc (and other?) failures can occur
                      (unzip-file (fs/file jar-path) dest-dir)
                      (swap! counter dec)
                      (catch Exception e
                        (fs/delete-tree dest-dir)
                        (println "Problem unzipping jar for:" url)
                        (println "Exception:" (.getMessage e)))))))))))
      ;; report
      (when cnf/verbose (println "Number of jars fetched:" n)))))

