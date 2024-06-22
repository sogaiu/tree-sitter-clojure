(ns conf
  (:require [babashka.fs :as fs]))

(def verbose
  (System/getenv "VERBOSE"))

(def proj-root (fs/cwd))

(def tatt-yml-url
  (str "https://raw.githubusercontent.com/clojure/test.regression/"
       ;; XXX: specific commit
       "28873780a73774c008b956871bbf64b7625f2c94"
       "/.github/workflows/test-all-the-things.yml"))

(def tatt-yml-path
  (str proj-root "/data/test-all-the-things.yml"))

(def tr-repos-list-path
  (str proj-root "/data/test-regression-repos-list.tsv"))

(def tr-repos-root
  (str proj-root "/data/test-regression-repos"))

