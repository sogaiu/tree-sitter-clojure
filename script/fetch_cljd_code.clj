(ns fetch-cljd-code
  (:require [babashka.fs :as fs]
            [babashka.tasks :as t]
            [conf :as cnf]))

(defn -main
  [& _args]
  (when (not (fs/exists? cnf/cljd-repos-root))
    (fs/create-dir cnf/cljd-repos-root))
  (with-open [rdr (clojure.java.io/reader cnf/cljd-repos-list)]
    (doseq [url (line-seq rdr)]
      (when (uri? (java.net.URI. url))
        (when-let [[_ user name] 
                   (re-matches #".*/([^/]+)/([^/]+)$" url)]
          (let [dest-dir (str cnf/cljd-repos-root "/" name "." user)]
            (when-not (fs/exists? dest-dir)
              (t/shell (str "git clone " url " " dest-dir)))))))))
