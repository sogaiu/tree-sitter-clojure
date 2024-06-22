(ns show-expected-errors
  (:require [babashka.fs :as fs]
            [clojure.java.io :as cji]
            [clojure.string :as cs]
            [conf :as cnf]))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defn count-error-freq
  []
  (let [errors (atom {})]
    (with-open [rdr (cji/reader (cnf/repos :error-tsv-path))]
      ;; should skip first row because represents field names
      (.readLine rdr)
      (doseq [row (line-seq rdr)]
        (when-let [fields (cs/split row #"\t")]
          (let [descr (second fields)]
            (swap! errors
                   update descr
                   #(if (nil? %) 1 (inc %)))))))
    @errors))

;; $ tail -n +2 classify-parse-errors.tsv | cut -d$'\t' -f 2 | uniq -c | sort
(defn -main
  [& _args]
  (when (and (cnf/repos :error-tsv-path)
             (fs/exists? (cnf/repos :error-tsv-path)))
    (println "Showing expected errors")
    (let [errors (count-error-freq)
          total (atom 0)]
      ;; XXX: could write with reduce but that would be more cryptic
      (doseq [descr (sort (keys errors))]
        (let [cnt (get errors descr)]
          (swap! total + cnt)
          (print cnt "\t" descr "\n")))
      (println "---------------------------------------")
      (print @total "\t" "Total" "\n"))))

