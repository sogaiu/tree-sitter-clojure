(ns parse-samples
  (:import [java.io FileInputStream]
           [java.security MessageDigest])
  (:require [babashka.fs :as fs]
            [babashka.process :as proc]
            [clojure.java.io :as cji]
            [clojure.string :as cs]
            [conf :as cnf]
            [utils :as u]))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defn md5
  [file]
  (with-open [f (FileInputStream. file)]
    (let [input (byte-array 4096)
          mdi (MessageDigest/getInstance "MD5")]
      (loop [len (.read f input)]
        (if (pos? len)
          (do
            (.update mdi input 0 len)
            (recur (.read f input)))
          ;; XXX: using just bigint seems to lead to undesirable
          ;;      results involving negative numbers
          (BigInteger. 1 (.digest mdi)))))))

(def file-checksum md5)

(defn init-error-checksums
  []
  (let [checksums (atom #{})]
    (with-open [rdr (cji/reader (cnf/repos :error-tsv-path))]
      ;; should skip first row because represents field names
      (.readLine rdr)
      (doseq [row (line-seq rdr)]
        (let [fields (cs/split row #"\t")]
          (when fields
            (let [checksum (first fields)]
              (swap! checksums conj checksum)))))
      @checksums)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defn save-sample-paths
  [samples]
  (let [to-be-parsed (fs/create-temp-file)]
    (fs/delete-on-exit to-be-parsed)
    (fs/write-lines to-be-parsed (map str samples))
    to-be-parsed))

(defn parse-samples
  [to-be-parsed]
  (let [start-time (System/currentTimeMillis)
        out-file-path (fs/create-temp-file)
        _ (fs/delete-on-exit out-file-path)
        p (proc/process {:dir cnf/grammar-dir
                         :out :write
                         :out-file (fs/file out-file-path)}
                        (str cnf/ts-bin-path
                             " parse --quiet --paths "
                             to-be-parsed))
        exit-code (:exit @p)
        duration (- (System/currentTimeMillis) start-time)]
    [duration exit-code out-file-path]))

(defn save-error-paths
  [out-file-path]
  (let [errors (atom [])]
    (fs/write-lines (cnf/repos :error-file-paths)
                    (keep (fn [line]
                            (if-let [[path-ish time message]
                                     (cs/split line #"\t")]
                              (let [path (cs/trim path-ish)]
                                (when cnf/verbose (println message path))
                                (swap! errors conj path)
                                path)
                              (println "Did not parse:" line)))
                          (fs/read-all-lines (fs/file out-file-path))))
    @errors))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defn report-looking
  []
  (println "Looking in samples collection:" (cnf/repos :name))
  (print "Focusing on" (sort (cnf/repos :extensions))
         "files ... ")
  (flush))

(defn report-found
  [samples start-time]
  (println "found"
           (count samples) "files"
           "in" (- (System/currentTimeMillis) start-time) "ms"))

(defn report-parsing
  []
  (print "Invoking tree-sitter to parse files ... ")
  (flush))

(defn report-errors
  [errors]
  (let [n-errors (count errors)]
    (if (zero? n-errors)
      (println "No parse errors.")
      (do
        (println "Number of errors encountered:" n-errors)
        (when (and (cnf/repos :error-tsv-path)
                   (fs/exists? (cnf/repos :error-tsv-path)))
          ;; compare checksums against expected error checksums
          (let [checksums (init-error-checksums)
                hits (atom [])]
            (doseq [path errors]
              (let [checksum (format "%032x" (file-checksum (fs/file path)))]
                (if (get checksums checksum)
                  (swap! hits conj checksum)
                  (println "Unexpected error for path:" path))))
            (println "Number of expected errors encountered:" (count @hits))
            (println "Percent of expected errors met:"
                     (str (* 100
                             (/ (count @hits) n-errors))
                          "%"))))
        (println "See" (cnf/repos :error-file-paths)
                 "for details or rerun verbosely.")))))

(defn report-duration
  [duration]
  (println "Took" duration "ms"))

(defn report-exit-code-and-exit
  [exit-code]
  (if-not (#{0 1} exit-code)
    (do
      (println "tree-sitter parse exited with unexpected exit-code:"
               exit-code)
      (System/exit 1))
    (System/exit 0)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; outline:
;;
;; 1. collect files to parse
;; 2. save file paths to file (to hand to tree-sitter)
;; 3. parse files using tree-sitter
;; 4. examine output to determine file paths with errors and save to file
(defn -main
  [& args]
  (u/exit-unless-grammar-dir-exists)
  ;;
  (println "Parsing samples")
  (let [repos (first args)]
    ;; convenience for setting samples set to test against
    (when repos
      ;; XXX: may be there's a better way to do this?
      (if-let [repos-var (find-var (symbol (str "conf/" repos)))]
        (do
          (u/exit-unless-valid-repos @repos-var)
          ;; https://stackoverflow.com/a/10987054
          (alter-var-root #'cnf/repos (constantly repos-var)))
        (do
          (println "Did not find samples repos with name:" repos)
          (System/exit 1))))
    ;;
    (u/exit-unless-repos-root-exists)
    ;;
    (try
      (let [start-time (System/currentTimeMillis)
            _ (report-looking)
            ;; 1. find all relevant clojure-related files
            samples (u/collect-samples)
            _ (report-found samples start-time)
            ;; 2. save file paths to be parsed to a file
            to-be-parsed (save-sample-paths samples)
            _ (report-parsing)
            ;; 3. parse with tree-sitter via the paths file
            [duration exit-code out-file-path] (parse-samples to-be-parsed)
            _ (when (= 1 exit-code) (println))
            ;; 4. save and print error file info
            errors (save-error-paths out-file-path)]
        (report-errors errors)
        (report-duration duration)
        (u/exit-unless-error-code-is exit-code #{0 1} "tree-sitter-parse"))
      (catch Exception e
        (u/report-exception-and-exit e)))))

