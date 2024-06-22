(ns fetch-jars
  (:require [babashka.fs :as fs]
            [babashka.http-client :as hc]
            [clojure.java.io :as cji]
            [conf :as cnf]))

(def default-n 10)

(def skip-urls
  (do
    (when (not (fs/exists? cnf/clojars-skip-urls))
      (spit cnf/clojars-skip-urls ""))
    (set (fs/read-all-lines (fs/file cnf/clojars-skip-urls)))))

(defn skip-url?
  [url]
  (or (skip-urls url)
      (re-matches #"^.*lein-template.*" url)))

(defn parse-url
  [url]
  (when-let [[_ container-path jar-name]
             (re-matches #"^https://repo.clojars.org/(.*)/([^/]+\.jar)" url)]
    [container-path jar-name]))

(defn collect-urls
  [rdr n]
  (let [counter (atom n)
        urls (atom [])]
    ;; try to collect enough urls
    (doseq [url (line-seq rdr)
            :while (or (neg? n)
                       (pos? @counter))]
      (when (and (uri? (java.net.URI. url))
                 (not (skip-url? url)))
        (when-let [[container-path jar-name] (parse-url url)]
          (let [jar-path
                (str cnf/clojars-jars-root "/" container-path "/" jar-name)]
            ;; XXX: could fetching have failed without cleaning up the jar?
            (when-not (fs/exists? jar-path)
              (swap! urls conj url)
              (swap! counter dec))))))
    (when cnf/verbose (println "Collected" (count @urls) "urls"))
    urls))

(defn fetch-urls
  [rdr n]
  (let [urls (collect-urls rdr n)
        fetched (atom 0)
        probs (atom [])]
    (if (empty? @urls)
      nil
      (let [start-time (System/currentTimeMillis)]
        (doseq [url @urls]
          (when-let [[container-path jar-name] (parse-url url)]
            (let [jar-dir (str cnf/clojars-jars-root "/" container-path)
                  jar-path (str jar-dir "/" jar-name)]
              (when-not (fs/exists? jar-path)
                (fs/create-dirs jar-dir))
              (try
                (cji/copy (:body (hc/get url {:as :stream}))
                          (cji/file jar-path))
                (swap! fetched inc)
                (catch Exception e
                  (println url)
                  (println e)
                  (println)
                  (swap! probs conj url))))))
        [(- (System/currentTimeMillis) start-time)
         @fetched
         @probs]))))

(defn num-to-fetch
  []
  (if (empty? *command-line-args*)
    default-n
    (try
      (Integer/parseInt (first *command-line-args*))
      (catch Exception e
        (println "Failed to parse as integer:"
                 (first *command-line-args*))
        nil))))

(defn -main
  [& _args]
  (when (not (fs/exists? cnf/clojars-jars-root))
    (fs/create-dir cnf/clojars-jars-root))
  ;; n <= -1 means to fetch all remaining
  (let [n (num-to-fetch)]
    (cond
      (nil? n)
      (do
        (println "Please specify a whole number of jars to fetch")
        (System/exit 1))
      ;;
      (zero? n)
      (do
        (println "Ok, if you say so.")
        (System/exit 0)))
    (with-open [rdr (cji/reader cnf/clojars-jar-list-path)]
      (if-let [[duration fetched probs] (fetch-urls rdr n)]
        (do
          (when (not (empty? probs))
            (println "Encountered some problems")
            (println probs))
          (println "Took:" duration "ms"
                   "fetching" fetched "jars"))
        (println "Did not find any urls to fetch.")))))

