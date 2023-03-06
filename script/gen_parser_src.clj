(ns gen-parser-src
  (:require [babashka.fs :as fs]
            [babashka.process :as proc]
            [conf :as cnf]))

(defn -main
  [& _args]
  (if-not (fs/exists? cnf/grammar-js)
    (println "grammar.js not found")
    (let [exit-code
          (-> (proc/shell {:continue true} cnf/ts-generate-cmd)
              :exit)]
      (when (not= exit-code 0)
        (println "Problem generating parser source:" exit-code)))))

