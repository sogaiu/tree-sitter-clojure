(ns generate-parser
  (:require [babashka.fs :as fs]
            [babashka.process :as proc]
            [conf :as cnf]
            [utils :as u]))

(defn -main
  [& _args]
  ;; precautions
  (u/exit-unless-tree-sitter-available)
  (u/exit-unless (u/valid-abi?) "invalid abi value in configuration")
  (u/exit-unless-grammar-dir-exists)
  ;; back to our regularly scheduled program
  (println "Generating parser.c")
  (try
    (let [p (proc/shell {:dir cnf/grammar-dir}
                        (str cnf/ts-bin-path
                             " generate --abi " cnf/abi " --no-bindings"))
          exit-code (:exit @p)]
      (u/exit-unless-error-code-is exit-code #{0} "tree-sitter generate"))
    (catch Exception e
      (u/report-exception-and-exit e))))

