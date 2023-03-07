(ns show-expected-misparses
  (:require [babashka.fs :as fs]
            [babashka.process :as proc]
            [clojure.string :as cs]
            [conf :as cnf]))

(def sources-dir
  (str cnf/misparses-root "/sources"))

(def correct-dir
  (str cnf/misparses-root "/correct"))

(defn -main
  [& _args]
  (when (fs/exists? cnf/fails-root)
    (fs/walk-file-tree 
     sources-dir
     {:visit-file
      (fn [path _]
        (println "Expecting misparsing for:" (fs/file-name path))
        (let [p
              (try
                (proc/shell {:out :string}
                            (str cnf/ts-bin-path " parse " path))
                (catch Exception e
                  (println "Unexpected result:" (.getMessage e))))
              actual (:out @p)
              expected-path
              (str correct-dir "/" (fs/file-name path))
              expected
              (try
                (slurp expected-path)
                (catch Exception e
                  (println "Exception:" (.getMessage e))
                  (println "Failed to slurp:" expected-path)))]
          (when (and actual expected)
            (if (not= (cs/trim actual) (cs/trim expected))
              (println "Parsing mistmatched as expected")
              (println "Unexpectedly parsing matched"))))
        :continue)})))
