(declare-project
 :name "janet-lambda-runtime"
 :dependencies
 ["spork"
  {:repo "https://github.com/cosmictoast/jurl.git" :tag "v1.4.2"}
  "judge"])

(declare-source
 :source ["src/lambda-runtime.janet"])

(task "test" []
      (-> (array "jpm_tree/bin/judge" ;(drop 2 (dyn :args)))
          (string/join " ")
          (shell)))
