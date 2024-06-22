(ns corpus-test
  (:require [babashka.fs :as fs]
            [babashka.process :as proc]
            [conf :as cnf]
            [utils :as u]))

(defn -main
  [& _args]
  ;; precautions
  (u/exit-unless-tree-sitter-available)
  (u/exit-unless (u/cc-available?) "cc not found")
  (u/exit-unless (u/node-available?) "node not found")
  (u/exit-unless-grammar-dir-exists)
  ;; back to our regularly scheduled program
  (println "Running corpus tests")
  (try
    (let [p (proc/shell {:dir cnf/grammar-dir}
                        (str cnf/ts-bin-path " test"))
          exit-code (:exit @p)]
      (u/exit-unless-error-code-is exit-code #{0} "tree-sitter test"))
    (catch Exception e
      (u/report-exception-and-exit e))))

