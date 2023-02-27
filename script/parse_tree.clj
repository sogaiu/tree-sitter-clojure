(ns parse-tree
  (:require [babashka.fs :as fs]
            [babashka.tasks :as t]
            [clojure.string :as cs]))

(def proj-root (fs/cwd))

(def repos-root 
  (str proj-root "/repos"))

(defn -main
  [& _args]
  (when (fs/exists? repos-root)
    (fs/walk-file-tree repos-root
                       {:visit-file 
                        (fn [path _]
                          (when (cs/ends-with? (str path) ".cljd")
                            (try
                              (t/shell "tree-sitter parse --quiet " 
                                       (str path))
                              (catch Exception e
                                (println "Exception:" (.getMessage e)))))
                          :continue)})))
