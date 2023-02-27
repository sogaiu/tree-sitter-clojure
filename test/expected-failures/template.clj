;; https://raw.githubusercontent.com/qbits/lein-template/d607011d040647415cd9baae19438de8a22ebae1/src/leiningen/new/component/project.clj
(defproject cc.qbits.component/{{name}} "0.1.0-SNAPSHOT"
  :license {:name "Eclipse Public License"
            :url "http://www.eclipse.org/legal/epl-v10.html"}
  :dependencies [[com.stuartsierra/component "0.3.1"]
                 [prismatic/schema "1.0.4"]]
  :source-paths ["src/clj"]
  :global-vars {*warn-on-reflection* true})
