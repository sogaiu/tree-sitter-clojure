(ns ensure-tree-sitter
  (:require [babashka.fs :as fs]
            [babashka.process :as proc]
            [babashka.tasks :as t]))

(def proj-root (fs/cwd))

(def ts-cli-real-path
  "tree-sitter/target/release/tree-sitter")

(def ts-cli-link-path
  "bin/tree-sitter")

(def ts-sha
  "c51896d32dcc11a38e41f36e3deb1a6a9c4f4b14")

(defn -main
  [& _args]
  (when-not (fs/exists? ts-cli-real-path)
    ;; clone tree-sitter repository if necessary
    (when-not (fs/exists? "tree-sitter")
      (try
        (t/shell "git clone https://github.com/tree-sitter/tree-sitter")
        (catch Exception e
          (println "Problem cloning tree-sitter:" (.getMessage e))
          (System/exit 1))))
    ;; check out commit ts-sha
    (try
      (println "Checking out commit:" ts-sha)
      (let [p (proc/process {:dir "tree-sitter"} "git" "checkout" ts-sha)
            exit-code (:exit @p)]
        (when-not (zero? exit-code)
          (println "git checkout exited non-zero:" exit-code)
          (System/exit 1)))
      (catch Exception e
        (println "Problem checking out commit:" (.getMessage e))
        (System/exit 1)))
    ;; build tree-sitter cli
    (try
      (println "Building tree-sitter cli...")
      (let [p (proc/process {:dir "tree-sitter"} "cargo" "build" "--release")
            exit-code (:exit @p)]
        (when-not (zero? exit-code)
          (println "cargo build exited non-zero:" exit-code)
          (System/exit 1)))
      (catch Exception e
        (println "Problem building tree-sitter cli:" (.getMessage e))
        (System/exit 1)))
    ;; create symlink to tree-sitter cli
    (try
      (println "Making symlink to tree-sitter cli under bin")
      (fs/create-dir "bin")
      (fs/create-sym-link ts-cli-link-path
                          (str "../" ts-cli-real-path))
      (catch Exception e
        (println "Problem creating tree-sitter cli symlink:" (.getMessage e))
        (System/exit 1))))
  ;; try running the tree-sitter cli
  (try
    (t/shell (str ts-cli-real-path " --version"))
    (catch Exception e
      (println "Problem executing tree-sitter cli:" (.getMessage e))
      (System/exit 1))))

