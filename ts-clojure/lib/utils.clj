(ns utils
  (:require [babashka.fs :as fs]
            [babashka.process :as proc]
            [clojure.string :as cs]
            [conf :as cnf]))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defn collect-samples
  []
  (let [samples (atom [])]
    (fs/walk-file-tree
     (cnf/repos :root)
     {:visit-file
      (fn [path _]
        (when ((cnf/repos :extensions) (fs/extension path))
          (swap! samples conj path))
        :continue)
      :follow-links true})
    @samples))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defn exit-unless-error-code-is
  [exit-code code-set cmd-str]
  (when-not (code-set exit-code)
    (println cmd-str "exited with unexpected exit-code:"
             exit-code)
    (System/exit 1)))

(defn exit-unless
  [condition message]
  (when-not condition
    (println message)
    (System/exit 1)))

(defn report-exception-and-exit
  [e]
  (println "Exception:" e)
  (System/exit 1))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defn which
  [name]
  ;; XXX: probably a better way...
  (when-let [path (fs/which name)]
    (format "%s" (fs/which name))))

(defn tree-sitter-available?
  []
  (which cnf/ts-bin-path))

(defn git-available?
  []
  (which "git"))

(defn cc-available?
  []
  (which "cc"))

(defn node-available?
  []
  (which "node"))

(defn grammar-dir-exists?
  []
  (fs/exists? cnf/grammar-dir))

;; sample output from tree-sitter dump-languages
;;
;;   scope: source.janet
;;   parser: "./tree-sitter-janet-simple/"
;;   highlights: None
;;   file_types: ["cgen", "janet", "jdn"]
;;   content_regex: None
;;   injection_regex: None
;;
;;   scope: source.clojure
;;   parser: "./tree-sitter-clojure/"
;;   highlights: None
;;   file_types: ["bb", "clj", "cljc", "cljs"]
;;   content_regex: None
;;   injection_regex: None
;;
(defn parsers-from-dump-languages
  []
  (let [out-file-path (fs/create-temp-file)
        _ (fs/delete-on-exit out-file-path)
        p (proc/process {:out :write
                         :out-file (fs/file out-file-path)}
                        (str cnf/ts-bin-path " dump-languages"))
        exit-code (:exit @p)]
    (exit-unless
     (zero? exit-code)
     (format "tree-sitter dump-languages exited non-zero: %d"
             exit-code))
    (keep (fn [line]
            (when (pos? (count line))
              (let [[name value] (cs/split line #": ")]
                (when (= name "parser")
                  (let [no-quotes (subs value 1 (dec (count value)))]
                    no-quotes)))))
          (fs/read-all-lines (fs/file out-file-path)))))

(defn tree-sitter-sees-parser?
  []
  (when (grammar-dir-exists?)
    (loop [parsers (parsers-from-dump-languages)]
      (cond
        (empty? parsers)
        false
        ;;
        (fs/same-file? (first parsers) cnf/grammar-dir)
        true
        ;;
        :default
        (recur (rest parsers))))))

(defn valid-abi?
  []
  (number? cnf/abi))

(defn repos-root-exists?
  []
  (fs/exists? (cnf/repos :root)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; XXX: check other conf.clj values?

(defn valid-repos?
  [repos]
  (and (map? repos)
       (contains? repos :name)
       (contains? repos :root)
       (contains? repos :extensions)
       (contains? repos :error-file-paths)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defn exit-unless-tree-sitter-available
  []
  (exit-unless (tree-sitter-available?)
               "tree-sitter not found"))

(defn exit-unless-repos-root-exists
  []
  (exit-unless (repos-root-exists?)
               (str "Directory for " (cnf/repos :root) " not found")))

(defn exit-unless-grammar-dir-exists
  []
  (exit-unless (grammar-dir-exists?)
               (str "Directory for " cnf/grammar-dir " not found")))

(defn exit-unless-valid-repos
  [repos]
  (exit-unless (valid-repos? repos)
               (str "Not a valid repos: for" repos)))

