(ns make-repos-list
  (:require [babashka.fs :as fs]
            [babashka.http-client :as hc]
            [clj-yaml.core :as cy]
            [clojure.java.io :as cji]
            [conf :as cnf]))

(defn -main
  [& _args]
  ;; if there's no test-all-the-things.yml file, fetch it
  (when (not (fs/exists? cnf/tatt-yml-path))
    (println "Fetching test-all-the-things.yml from test.regression...")
    (try
      (cji/copy (:body (hc/get cnf/tatt-yml-url {:as :stream}))
                (cji/file cnf/tatt-yml-path))
      (catch Exception e
        (println "fetching test-all-the-things.yml failed:" e)
        (System/exit 1))))
  ;; if there is a test-all-the-things.yml file, process it
  (when (and (fs/exists? cnf/tatt-yml-path)
             (not (fs/exists? cnf/tr-repos-list-path)))
    (println "Writing latest repos list...")
    (try
      (fs/write-lines cnf/tr-repos-list-path
                      (map (fn [item]
                             (def repo (get-in item [:with :subjectRepo]))
                             (def ref (get-in item [:with :subjectRef]))
                             (str "https://github.com/" repo "\t" ref))
                           (-> (cy/parse-string (slurp cnf/tatt-yml-path))
                               (get :jobs)
                               vals)))
      (catch Exception e
        (println "Problem writing repos list:" e)
        (System/exit 1)))))

