(ns fetch-samples
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
          (let [user-dir (str cnf/cljd-repos-root "/" user)
                dest-dir (str user-dir "/" name)]
            (when-not (fs/exists? dest-dir)
              (fs/create-dirs user-dir)
              (t/shell (str "git clone --depth 1 " url " " dest-dir)))))))))
