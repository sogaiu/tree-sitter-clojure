(ns parse-cljd-code
  (:require [babashka.fs :as fs]
            [babashka.tasks :as t]
            [clojure.string :as cs]))

(def proj-root (fs/cwd))

(def repos-root 
  (str proj-root "/clojuredart-repos"))

(def ts-bin-path
  (str proj-root "/bin/tree-sitter"))

(def extension ".cljd")

(defn -main
  [& _args]
  (when (fs/exists? repos-root)
    (let [files (atom [])
          paths-file (fs/create-temp-file)
          _ (fs/delete-on-exit paths-file)]
      ;; find all .cljd files
      (fs/walk-file-tree repos-root
                         {:visit-file 
                          (fn [path _]
                            (when (cs/ends-with? (str path) extension)
                              (swap! files conj path))
                            :continue)})
      (println extension "files found:" (count @files))
      ;; save .cljd file paths to a file
      (fs/write-lines paths-file
                      (map str @files))
      ;; parse via the paths file
      (try
        (t/shell (str ts-bin-path " parse --quiet --paths " paths-file))
        (catch Exception e
          (println "Exception:" (.getMessage e)))))))
