(ns extract-jars
  (:require [babashka.fs :as fs]
            [babashka.process :as proc]
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

(defn -main
  [& _args]
  (when (not (fs/exists? cnf/clojars-jars-root))
    (fs/create-dir cnf/clojars-jars-root))
  (when (fs/exists? cnf/clojars-jars-root)
    (let [start-time (System/currentTimeMillis)
          jar-paths (atom [])]
      ;; find all jar files
      (print "Looking for jar files ... ")
      (flush)
      (fs/walk-file-tree cnf/clojars-jars-root
                         {:visit-file
                          (fn [path _]
                            (when (= "jar" (fs/extension path))
                              (swap! jar-paths conj path))
                            :continue)})
      (println "found"
               (count @jar-paths) "jar files"
               "in" (- (System/currentTimeMillis) start-time) "ms")
      ;; unzip jar files
      (print "Unzipping jar files ... ")
      (flush)
      (let [start-time (System/currentTimeMillis)
            counter (atom 0)]
        (doseq [jar-path @jar-paths]
          (when-let [[subpath jar-name] (parse-jar-path (str jar-path))]
            (let [dest-dir (str cnf/clojars-repos-root "/" subpath)]
              (when-not (fs/exists? dest-dir)
                (fs/create-dirs dest-dir)
                (try
                  (fs/unzip (fs/file jar-path) dest-dir)
                  (swap! counter inc)
                  (catch Exception e
                    (fs/delete-tree dest-dir)
                    (println "Problem unzipping jar:" jar-path)
                    #_(println "Exception:" e)))))))
        ;; report summary
        (println "took" (- (System/currentTimeMillis) start-time) "ms"
                 "to unzip" @counter "jar files")))))

