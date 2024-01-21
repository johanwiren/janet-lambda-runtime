(import jurl)
(import spork/json :as json)
(import spork/generators :as g)

(var AWS_LAMBDA_RUNTIME_API "localhost:3246")
(var handler-from-source? false)

(defn- runtime-url [path]
  (string/format "http://%s/2018-06-01/runtime%s" AWS_LAMBDA_RUNTIME_API path))

(defn- invoke-api [request]
  (let [res (jurl/request request)]
    (if (<= 500 (get res :status))
      (error "InternalServerErrorFromRuntimeAPI")
      res)))

(defn handler-init [f]
  (var res nil)
  (try
    (do (f) nil)
    ([err]
     (set res
          {:url (runtime-url "/init/error")
           :method :post
           :headers {"Lambda-Runtime-Function-Error-Type" "Runtime.HandlerInit"}})
           :body (json/encode {:errorMessage err
                               :errorType "HandlerInitError"})))
  res)

(defn- init! [f]
  (set AWS_LAMBDA_RUNTIME_API (os/getenv "AWS_LAMBDA_RUNTIME_API" "localhost:3246"))
  (-?> (handler-init f)
       (invoke-api))
  (gccollect))

(defn invocation [{:headers headers :body body}]
  (def ctx @{})
  (loop [[k v] :pairs headers :when (string/has-prefix? "lambda-" k)]
    (put ctx k v))
  {:ctx ctx
   :event (json/decode body true)})

(defn- get-invocation []
  (let [res (invoke-api {:url (runtime-url "/invocation/next")
                         :method :get})]
    (invocation res)))

(defn lambda-response [handler get-invocation]
  (def invocation (get-invocation))
  (def {:ctx ctx} invocation)
  (def {:lambda-runtime-aws-request-id request-id} ctx)
  (var response nil)
  (var error nil)
  (try
    (set response (handler (get-invocation)))
    ([err] (set error err)))
  (def url (runtime-url (string/format "/invocation/%s/%s"
                                       request-id
                                       (if error "error" "response"))))
  {:url url
   :method :post
   :headers (when error {"Lambda-Runtime-Function-Error-Type" "Runtime.UnknownReason"})
   :body (if error
           (json/encode {:errorMessage error
                         :errorType "HandlerError"})
           response)})

(defn- run-from-source [handler]
  (print "Running from source")
  (setdyn :syspath (os/getenv "JANET_PATH"))
  (import (string "./" handler) :as h)
  (set handler-from-source? true)
  ((compile '(h/main nil))))

(defn serve [init handler]
  (let [handler (os/getenv "_HANDLER")]
    (if (and (not handler-from-source?)
             (os/stat (string handler ".janet")))
      (run-from-source handler)
      (do
        (init! init)
        (forever
         (let [res (lambda-response handler get-invocation)]
           (invoke-api res)
           (gccollect)))))))

