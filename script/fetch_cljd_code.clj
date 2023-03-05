(ns fetch-cljd-code
  (:require [babashka.fs :as fs]
            [babashka.tasks :as t]))

(def proj-root (fs/cwd))

(def repos-root 
  (str proj-root "/clojuredart-repos"))

(def repos-list
  (str proj-root "/data/clojuredart-repos-list.txt"))

(defn -main
  [& _args]
  (when (not (fs/exists? repos-root))
    (fs/create-dir repos-root))
  (with-open [rdr (clojure.java.io/reader repos-list)]
    (doseq [url (line-seq rdr)]
      (when (uri? (java.net.URI. url))
        (when-let [[_ user name] 
                   (re-matches #".*/([^/]+)/([^/]+)$" url)]
          (let [dest-dir (str repos-root "/" name "." user)]
            (when-not (fs/exists? dest-dir)
              (t/shell (str "git clone " url " " dest-dir)))))))))
