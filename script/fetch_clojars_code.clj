(ns fetch-clojars-code
  (:require [babashka.fs :as fs]
            [babashka.process :as proc]
            [babashka.tasks :as t]
            [clojure.java.io :as cji]
            [conf :as cnf]))

;; default number of jars to fetch
(def default-n 10)

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
            (let [parent-dir
                  (fs/file
                   (.substring save-path 0
                               (.lastIndexOf save-path
                                             (int File/separatorChar))))]
              (when-not (fs/exists? parent-dir)
                (fs/create-dirs parent-dir))
              (cji/copy stream out-file)))
          (recur (.getNextEntry stream)))))))

(defn -main
  [& _args]
  (when (not (fs/exists? cnf/clojars-repos-root))
    (fs/create-dir cnf/clojars-repos-root))
  (with-open [rdr (cji/reader cnf/clru-list-path)]
    ;; XXX: can there be a special value to indicate fetch everything?
    (let [n (if (empty? *command-line-args*)
              default-n
              (try
                (Integer/parseInt (first *command-line-args*))
                (catch Exception e
                  (println "Failed to parse as integer:"
                           (first *command-line-args*))
                  (System/exit 1))))
          do-all (= -1 n)
          counter (atom (inc n))
          verbose (System/getenv "VERBOSE")]
      (doseq [url (line-seq rdr)
              :while (or do-all (pos? @counter))]
        (when (uri? (java.net.URI. url))
          (when-let [subpath (url->subpath url)]
            (let [dest-dir (str cnf/clojars-repos-root "/" subpath)]
              ;; use directory existence to decide whether to process
              (if (fs/exists? dest-dir)
                (when verbose (println "Skipping:" url))
                (let [_ (when verbose (println "Fetching:" url))
                      jar-path (fs/create-temp-file)
                      _ (fs/delete-on-exit jar-path)
                      p (proc/process "curl" url "-L" "-o" jar-path)
                      exit-code (:exit @p)]
                  (when-not (zero? exit-code)
                    (println "Problem fetching:" url)
                    ;; XXX: or skip?
                    (System/exit 1))
                  (unzip-file (fs/file jar-path) dest-dir)
                  (swap! counter dec)))))))
      (when verbose (println "Number of jars fetched:" n)))))

