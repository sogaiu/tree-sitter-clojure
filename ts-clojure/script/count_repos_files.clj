(ns count-repos-files
  (:require [babashka.fs :as fs]
            [conf :as cnf]
            [utils :as u]))

(defn -main
  [& args]
  (let [repos (first args)]
    ;; convenience for setting samples set to operate on
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
    ;; precautions
    (u/exit-unless-repos-root-exists)
    ;; back to our regularly scheduled programming
    (let [start-time (System/currentTimeMillis)
          exts (atom {})
          n-files (atom 0)]
      (print "Scanning" (cnf/repos :name) "content ... ")
      (flush)
      (fs/walk-file-tree
       (cnf/repos :root)
       {:visit-file
        (fn [path _]
          (swap! n-files inc)
          (swap! exts
                 (fn [old ext-arg]
                   (assoc old
                          ext-arg (inc (get old ext-arg 0))))
                 (fs/extension path))
          :continue)
        :follow-links true})
      (println "done")
      ;;
      (println "Found" @n-files "files")
      (println "Found" (count @exts) "file extensions")
      ;;
      (println "Clojure-related file extensions")
      (doseq [ext (sort (cnf/repos :extensions))]
        (println ext ":" (get @exts ext 0)))
      (let [n-cljish-files
            (reduce (fn [acc ext]
                      (if-let [cnt (@exts ext)]
                        (+ acc cnt)
                        acc))
                    0
                    (cnf/repos :extensions))]
        (println "Found" n-cljish-files "Clojure-related files"))
      ;;(spit (cnf/repos :file-exts-path) @exts)
      ;;(println "See" (cnf/repos :file-exts-path) "for all extension info.")
      ;;
      (println "Took" (- (System/currentTimeMillis) start-time) "ms"))))

