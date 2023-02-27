(ns expect-failures
  (:require [babashka.fs :as fs]
            [babashka.process :as proc]
            [clojure.string :as cs]))

(def proj-root (fs/cwd))

(def fails-root
  (str proj-root "/test/expected-failures"))

(defn -main
  [& _args]
  (when (fs/exists? fails-root)
    (fs/walk-file-tree fails-root
                       {:visit-file
                        (fn [path _]
                          (println "Expecting ERROR for:" (fs/file-name path))
                          ;; https://github.com/babashka/process#shell
                          (let [exit-code
                                (-> (proc/shell {:continue true}
                                                "tree-sitter parse --quiet"
                                                (str path))
                                    :exit)]
                            (if (= exit-code 1)
                              (println "Exit-code was 1 as expected")
                              (println "Unexpected exit-code:" exit-code)))
                          (println)
                          :continue)})))
