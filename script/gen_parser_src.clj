(ns gen-parser-src
  (:require [babashka.fs :as fs]
            [babashka.process :as proc]))

(def proj-root (fs/cwd))

(def grammar-js 
  (str proj-root "/grammar.js"))

(def ts-bin-path
  (str proj-root "/bin/tree-sitter"))

(def abi 13)

(def ts-generate-cmd
  (str ts-bin-path " generate --abi " abi " --no-bindings"))

(defn -main
  [& _args]
  (if-not (fs/exists? grammar-js)
    (println "grammar.js not found")
    (let [exit-code
          (-> (proc/shell {:continue true} ts-generate-cmd)
              :exit)]
      (when (not= exit-code 0)
        (println "Problem generating parser source:" exit-code)))))

