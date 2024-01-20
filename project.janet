(declare-project
 :name "janet-lambda-runtime"
 :dependencies
 ["spork" {:repo "https://github.com/cosmictoast/jurl.git" :tag "v1.4.2"}])

(declare-source
 :source ["src/lambda-runtime.janet"])

(declare-executable
 :name "runtime"
 :entry "src/example.janet"
 :install false)
