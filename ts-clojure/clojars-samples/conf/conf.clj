(ns conf
  (:require [babashka.fs :as fs]
            [clojure.string :as cs]))

(def verbose
  (System/getenv "VERBOSE"))

(def proj-root (fs/cwd))

(def feed-clj-path
  (str proj-root "/data/feed.clj"))

(def feed-clj-gz-path
  (str proj-root "/data/feed.clj.gz"))

(def clojars-jar-list-path
  (str proj-root "/data/clojars-jar-list.txt"))

(def clojars-jars-root
  (str proj-root "/data/clojars-jars"))

(def clojars-repos-root
  (str proj-root "/data/clojars-repos"))

;;(def clojars-file-exts-path
;;  (str proj-root "/data/clojars-file-exts.txt"))

(def clojars-skip-urls
  (str proj-root "/data/clojars-skip-urls.txt"))

