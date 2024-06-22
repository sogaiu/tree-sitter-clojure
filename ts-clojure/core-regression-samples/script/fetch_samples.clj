(ns fetch-samples
  (:require [babashka.fs :as fs]
            [babashka.tasks :as t]
            [conf :as cnf]))

(defn -main
  [& _args]
  (when (not (fs/exists? cnf/cr-repos-root))
    (fs/create-dir cnf/cr-repos-root))
  (with-open [rdr (clojure.java.io/reader cnf/cr-repos-list)]
    (doseq [line (line-seq rdr)]
      (let [[_ url user name ref]
            ;; skip things that don't start with https://
            (re-matches #"^(https://.*/([^/\t]+)/([^/\t]+))\t([^ ]+)$" line)
            user-dir (str cnf/cr-repos-root "/" user)
            dest-dir (str user-dir "/" name)]
        (when url
          (when-not (fs/exists? dest-dir)
            (println "processing url: "url)
            (fs/create-dirs dest-dir)
            (try
              ;; apparently no way to clone + checkout arbitrary ref
              ;; in one invocation
              (t/shell {:extra-env {"GIT_TERMINAL_PROMPT" "0"}}
                       (str "git clone " url " " dest-dir))
              (t/shell {:dir dest-dir}
                       (str "git checkout " ref))
              (catch Exception e
                (println e)))))))))

