(ns gen-clru-list
  (:require [babashka.deps :as bd]
            [babashka.fs :as fs]
            [babashka.process :as proc]
            [clojure.edn :as ce]
            [clojure.string :as cs]
            [conf :as cnf]))

;; XXX: info about sort order?
;;
;;      https://github.com/clojars/clojars-web/issues/563

;; XXX: stop using this and go simpler
(bd/add-deps
 '{:deps {version-clj/version-clj
          {:mvn/version "0.1.2"}}})

(require
 '[version-clj.core :as vc])

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(comment

  (vc/version->seq "1.0.0")
  ;; => [(1 0 0)]

  (vc/version->seq "1.0.0-SNAPSHOT")
  ;; => [(1 0 0) ["snapshot"]]

  (vc/version->seq "0.4.0-beta1")
  ;; => [(0 4 0) ("beta" 1)]

  (vc/version->seq "0.2.0b3")
  ;; => [(0 2 0) ("b" 3)]

  (vc/version-compare "1.0.0-SNAPSHOT" "1.0.0")
  ;; => -1

  )

(def clojars-repo-root
  "https://repo.clojars.org")

;; https://github.com/clojars/clojars-web/wiki/Data#useful-extracts-from-the-poms
(def feed-url
  "http://clojars.org/repo/feed.clj.gz")

;; XXX: factor out logging?
(defn fetch-to-file
  [url out-fpath]
  ;; XXX: what to use for fetching web stuff seems to be in flux so
  ;;      until that settles down...
  (let [p (proc/process "curl" url "-L" "-o" out-fpath)
        exit-code (:exit @p)]
    ;; XXX: clean up if no errors?
    '(spit "log.txt"
          (str exit-code ":" url "\n")
          :append true)
    exit-code))

(comment

  (fetch-to-file feed-url "feed.clj.gz")

  )

(defn release-version?
  [ver-str]
  (= (count (vc/version->seq ver-str))
     1))

(comment

  (release-version? "0.1.0")
  ;; => true

  (release-version? "0.1.0-SNAPSHOT")
  ;; => false

  )

(defn latest-release-version
  [versions]
  (->> (filter release-version? versions)
    (sort vc/version-compare)
    last))

(comment

  (def versions
    ["1.7.0"])

  (latest-release-version versions)
  ;; => "1.7.0"

  (def versions
    ["1.7.0"
     "1.8.0"])

  (latest-release-version versions)
  ;; => "1.8.0"

  (def versions
    ["0.4.0"
     "0.4.0-beta1"
     "0.3.2"
     "0.3.1"
     "0.3.0"
     "0.3.0-SNAPSHOT"
     "0.2.2"
     "0.2.1"
     "0.2.0b3"
     "0.2.0b2"
     "0.2.0b1"])

  (latest-release-version versions)
  ;; => "0.4.0"

  (def versions
    ["0.2.0-SNAPSHOT"
     "0.2.0-alpha7"
     "0.2.0-alpha3-SNAPSHOT"
     "0.2.0-alpha1"
     "0.1.19-SNAPSHOT"
     "0.1.18.2"
     "0.1.18.1"
     "0.1.18"
     "0.1.15"
     "0.1.0-SNAPSHOT"
     "0.1.0-alpha13"
     "0.1.0-alpha1"])

  (latest-release-version versions)
  ;; => "0.1.18.2"

  ;; no latest-release-version
  (def versions
    ["0.1.9-SNAPSHOT"
     "0.1.9-beta3"
     "0.1.9-beta2"
     "0.1.9-beta1"])

  (latest-release-version versions)
  ;; => nil

  )

;; XXX: platform-dependent?
(defn feed-map->ext-line
  [{:keys [:artifact-id :group-id :versions]} ext]
  (when-let [ver (latest-release-version versions)]
    (let [group-path (cs/replace group-id "." "/")]
      (str "./"
        group-path "/"
        artifact-id "/"
        ver "/"
        artifact-id "-" ver "." ext))))

(comment

  (def feed-map
    {:group-id "viz-cljc",
     :artifact-id "viz-cljc",
     :description "Clojure and Clojurescript support for Viz.js",
     :scm {:tag "73b1e3ffcbad54088ac24681484ee0f97b382f1b", :url ""},
     :homepage "http://example.com/FIXME",
     :url "http://example.com/FIXME",
     :versions ["0.1.3" "0.1.2" "0.1.0"]})

  (feed-map->ext-line feed-map "pom")
  ;; => "./viz-cljc/viz-cljc/0.1.3/viz-cljc-0.1.3.pom"

  )

(defn feed-map->pom-line
  [m]
  (feed-map->ext-line m "pom"))

(comment

  (def feed-map
    {:group-id "viz-cljc",
     :artifact-id "viz-cljc",
     :description "Clojure and Clojurescript support for Viz.js",
     :scm {:tag "73b1e3ffcbad54088ac24681484ee0f97b382f1b", :url ""},
     :homepage "http://example.com/FIXME",
     :url "http://example.com/FIXME",
     :versions ["0.1.3" "0.1.2" "0.1.0"]})

  (feed-map->pom-line feed-map)
  ;; => "./viz-cljc/viz-cljc/0.1.3/viz-cljc-0.1.3.pom"

  )

(defn feed-map->jar-line
  [m]
  (feed-map->ext-line m "jar"))

(comment

  (def feed-map
    {:group-id "viz-cljc",
     :artifact-id "viz-cljc",
     :description "Clojure and Clojurescript support for Viz.js",
     :scm {:tag "73b1e3ffcbad54088ac24681484ee0f97b382f1b", :url ""},
     :homepage "http://example.com/FIXME",
     :url "http://example.com/FIXME",
     :versions ["0.1.3" "0.1.2" "0.1.0"]})

  (feed-map->jar-line feed-map)
  ;; => "./viz-cljc/viz-cljc/0.1.3/viz-cljc-0.1.3.jar"

  )

(defn feed-map->jar-url
  [m]
  (when-let [jar-line (feed-map->jar-line m)]
    (let [[_ dot-less-line] (re-find #"^\.(.*)" jar-line)]
      (str clojars-repo-root dot-less-line))))

(comment

  (def feed-map
    {:group-id "viz-cljc",
     :artifact-id "viz-cljc",
     :description "Clojure and Clojurescript support for Viz.js",
     :scm {:tag "73b1e3ffcbad54088ac24681484ee0f97b382f1b", :url ""},
     :homepage "http://example.com/FIXME",
     :url "http://example.com/FIXME",
     :versions ["0.1.3" "0.1.2" "0.1.0"]})

  (feed-map->jar-url feed-map)
  ;; => "https://repo.clojars.org/viz-cljc/viz-cljc/0.1.3/viz-cljc-0.1.3.jar"

  )

;; main

(defn -main
  [& _args]
  ;; if there's no feed.clj, fetch feed.clj.gz
  (when (not (fs/exists? cnf/feed-clj-path))
    (println "Fetching feed.clj.gz from clojars...")
    (let [exit-code (fetch-to-file feed-url cnf/feed-clj-gz-path)]
      (when-not (zero? exit-code)
        (println "Problem fetching feed.clj.gz, exit code:" exit-code)
        (System/exit 1))))
  ;; if there is a feed.clj.gz, uncompress it
  (when (fs/exists? cnf/feed-clj-gz-path)
    (try
      (println "Uncompressing feed.clj.gz...")
      ;; XXX: not cross-platform?
      ;; using gzip instead of gunzip works better in more environments
      (let [p (proc/process {:dir "data"}
                            "gzip" "--decompress" cnf/feed-clj-gz-path)
            exit-code (:exit @p)]
        (when-not (zero? exit-code)
          (println "gzip exited non-zero:" exit-code)
          (System/exit 1)))
      (catch Exception e
        (println "Problem uncompressing:" (.getMessage e))
        (System/exit 1))))
  ;; if there is a feed.clj, process it
  (when (and (fs/exists? cnf/feed-clj-path)
             (not (fs/exists? cnf/clru-list-path)))
    (println "Writing latest release jars url list...")
    (let [out-file-path (fs/create-temp-file)]
      (fs/delete-on-exit out-file-path)
      (fs/write-lines out-file-path
                      (keep feed-map->jar-url
                            (ce/read-string
                             (str "[" (slurp (fs/file cnf/feed-clj-path)) "]"))))
      ;; XXX: not cross-platform...
      (proc/process "sort" "--output" cnf/clru-list-path out-file-path))))
