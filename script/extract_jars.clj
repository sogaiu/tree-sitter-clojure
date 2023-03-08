(ns extract-jars
  (:require [babashka.fs :as fs]
            [babashka.process :as proc]
            [clojure.java.io :as cji]
            [conf :as cnf]))

(defn parse-jar-path
  [path]
  (let [regex (re-pattern (str "^"
                               cnf/clojars-jars-root
                               "/(.*)/"
                               "([^/]+\\.jar)"
                               "$"))]
    (when-let [[_ subpath jar-name] (re-matches regex path)]
      [subpath jar-name])))

;; adapted https://gist.github.com/mikeananev/b2026b712ecb73012e680805c56af45f
;; thanks to mikeananev
(defn extract-files
  [input output & [pred]]
  (let [pred-fn (or pred identity)]
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
              (when (pred-fn save-path)
                (let [parent-dir
                      (fs/file
                       (.substring save-path 0
                                   (.lastIndexOf save-path
                                                 (int File/separatorChar))))]
                  (when-not (fs/exists? parent-dir)
                    (fs/create-dirs parent-dir))
                  (cji/copy stream out-file))))
            (recur (.getNextEntry stream))))))))

(defn -main
  [& _args]
  ;; XXX: which dir(s) should this be done for here?
  (when (not (fs/exists? cnf/clojars-repos-root))
    (fs/create-dir cnf/clojars-repos-root))
  (when (fs/exists? cnf/clojars-jars-root)
    (let [start-time (System/currentTimeMillis)
          jar-paths (atom [])]
      ;; find all jar files
      (print "Looking for jar files ... ")
      (fs/walk-file-tree cnf/clojars-jars-root
                         {:visit-file
                          (fn [path _]
                            (when (= "jar" (fs/extension path))
                              (swap! jar-paths conj path))
                            :continue)})
      (println "found"
               (count @jar-paths) "jar files"
               "in" (- (System/currentTimeMillis) start-time) "ms")
      ;; XXX: save jar file paths to a file
      ;;(fs/write-lines cnf/clojars-jar-file-paths
      ;;                (map str @jar-paths))
      ;; unzip jar files
      (print "Unzipping jar files ... ")
      (let [start-time (System/currentTimeMillis)
            counter (atom 0)]
        (doseq [jar-path @jar-paths]
          (when-let [[subpath jar-name] (parse-jar-path (str jar-path))]
            (let [dest-dir (str cnf/clojars-repos-root "/" subpath)]
              (when-not (fs/exists? dest-dir)
                (try
                  (extract-files (fs/file jar-path) dest-dir
                                 ;; XXX: premature to be filtering?
                              #_  #(cnf/clojars-extensions (fs/extension %)))
                  (swap! counter inc)
                  (catch Exception e
                    (fs/delete-tree dest-dir)
                    (println "Problem unzipping jar:" jar-path)
                    (println "Exception:" (.getMessage e))))))))
        ;; report summary
        (println "took" (- (System/currentTimeMillis) start-time) "ms"
                 "to unzip" @counter "jar files")))))

