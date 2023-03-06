(ns conf
  (:require [babashka.fs :as fs]))

(def verbose
  (System/getenv "VERBOSE"))

(def proj-root (fs/cwd))

;; tree-sitter

(def ts-sha
  "c51896d32dcc11a38e41f36e3deb1a6a9c4f4b14")

(def abi 13)

(def ts-bin-path
  (str proj-root "/bin/tree-sitter"))

(def grammar-js
  (str proj-root "/grammar.js"))

(def ts-generate-cmd
  (str ts-bin-path " generate --abi " abi " --no-bindings"))

;; relative to proj-root
(def ts-cli-real-path
  "tree-sitter/target/release/tree-sitter")

;; relative to proj-root
(def ts-cli-link-path
  "bin/tree-sitter")

;; clojars

(def feed-clj-path
  (str proj-root "/data/feed.clj"))

(def feed-clj-gz-path
  (str proj-root "/data/feed.clj.gz"))

(def clru-list-path
  (str proj-root "/data/latest-release-jar-urls.txt"))

(def clojars-repos-root
  (str proj-root "/clojars-repos"))

(def clojars-file-paths
  (str proj-root "/data/clojars-files.txt"))

(def clojars-skip-urls
  (str proj-root "/data/clojars-skip-urls.txt"))

(def clojars-error-file-paths
  (str proj-root "/data/clojars-error-files.txt"))

(def clojars-extensions
  #{"clj" "cljc" "cljd" "cljr" "cljs" "cljx" "edn" "bb" "nbb"})

;; clojuredart

(def cljd-repos-root
  (str proj-root "/clojuredart-repos"))

(def cljd-repos-list
  (str proj-root "/data/clojuredart-repos-list.txt"))

;; failures

(def fails-root
  (str proj-root "/test/expected-failures"))
