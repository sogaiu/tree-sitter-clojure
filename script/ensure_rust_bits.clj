(ns ensure-rust-bits
  (:require [babashka.fs :as fs]))

(defn -main
  [& _args]
  (or (not (fs/which "rustc"))
      (not (fs/which "cargo"))))
