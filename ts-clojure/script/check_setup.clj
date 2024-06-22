(ns check-setup
  (:require [babashka.fs :as fs]
            [babashka.process :as proc]
            [clojure.string :as cs]
            [conf :as cnf]
            [utils :as u]))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defn check-prereq-paths
  [state]
  (merge state {:tree-sitter (u/tree-sitter-available?)
                :git (u/git-available?)
                :cc (u/cc-available?)
                :node (u/node-available?)}))

(defn check-grammar-dir
  [state]
  (-> state
      (merge {:grammar-dir-exists (u/grammar-dir-exists?)})
      (merge {:tree-sitter-sees-parser (u/tree-sitter-sees-parser?)})))

(defn check-abi
  [state]
  (merge state {:abi-is-number (u/valid-abi?)}))

(defn check-repos
  [state]
  (merge state {:repos-root-exists (u/repos-root-exists?)}))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defn print-separator
  []
  (println "------------------------------------------------------------------"))

(defn report-prereq-paths
  [state]
  (println "prerequisities")
  (let [ts (get state :tree-sitter)
        git (get state :git)
        cc (get state :cc)
        node (get state :node)]
    (u/exit-unless ts "tree-sitter not found")
    (println "  tree-sitter:" ts)
    (u/exit-unless git "git not found")
    (println "          git:" git)
    (u/exit-unless cc "cc not found")
    (println "           cc:" cc)
    (u/exit-unless node "node not found")
    (println "         node:" node)
    ;;
    (print-separator)
    ;;
    state))

(defn report-grammar-dir
  [state]
  (println "grammar-dir")
  (println "        directory set to:" cnf/grammar-dir)
  (let [exists (get state :grammar-dir-exists)]
    (u/exit-unless exists
                   (format "grammar-dir (%s) does not exist"
                           cnf/grammar-dir))
    (println "        directory exists: Yes"))
  (let [parser-visible (get state :tree-sitter-sees-parser)]
    (u/exit-unless parser-visible
                   (format "tree-sitter did not find grammar-dir (%s)"
                           cnf/grammar-dir))
    (println "  visible to tree-sitter: Yes"))
  ;;
  (print-separator)
  ;;
  state)

(defn report-abi
  [state]
  (println "abi number")
  (let [abi-is-number (get state :abi-is-number)]
    (u/exit-unless abi-is-number
                   (format "abi was not a number: %s %s"
                           cnf/abi (type cnf/abi)))
    (println "  abi:" cnf/abi))
  ;;
  (print-separator)
  ;;
  state)

(defn report-repos
  [state]
  (println "samples")
  (println "     samples repos:" (cnf/repos :name))
  (println "  directory set to:" (cnf/repos :root))
  (let [exists (get state :repos-root-exists)]
    (u/exit-unless exists
                   (format "repos (%s) does not exist"
                           (cnf/repos :root)))
    (println "  directory exists: Yes")
    (when (and exists
               (get state :count-samples))
      (println "[Counting samples too...this might take a while.]")
      (println "[Hint: Invoke with -1 as argument to skip sample counting.]")
      (println "       # of samples:" (count (u/collect-samples)))))
  ;;
  (print-separator)
  ;;
  state)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; outline:
;;
;; * report paths of tree-sitter, git, c compiler, and node
;; * report path of tree-sitter-clojure found by tree-sitter
;; * report path of grammar-dir from conf (should match above)
;; * report abi number from conf
;; * report current repos setting
;; * report paths of samples for current grammar
(defn check-and-report-findings
  [state]
  (println "ts-clojure: checking setup...")
  (print-separator)
  ;;
  (let [new-state
        (-> state
            ;;
            check-prereq-paths
            report-prereq-paths
            ;;
            check-grammar-dir
            report-grammar-dir
            ;;
            check-abi
            report-abi
            ;;
            check-repos
            report-repos)]
    ;;
    (println "Setup looks ok.")
    ;;
    new-state))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defn -main
  [& _args]
  ;;
  (try
    (let [state (if (= "-1" (first *command-line-args*))
                  {}
                  {:count-samples true})]
      (check-and-report-findings state))
    (catch Exception e
      (u/report-exception-and-exit e))))

