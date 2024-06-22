(ns conf
  (:require [babashka.fs :as fs]))

(def verbose
  (System/getenv "VERBOSE"))

(def proj-root (fs/cwd))

(def cr-repos-list
  (str proj-root "/data/core-regression-repos-list.tsv"))

(def cr-repos-root
  (str proj-root "/data/core-regression-repos"))

