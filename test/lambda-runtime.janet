(import spork/json :as json)
(import /src/lambda-runtime :as sut)

(use judge)

(defn invocation []
  {:ctx {:lambda-runtime-aws-request-id "c82cc661-d06c-4a57-a29c-946fb7f433b3"}
   :event {:request :payload}})

(test (sut/lambda-response json/encode invocation)
  {:body @"{\"ctx\":{\"lambda-runtime-aws-request-id\":\"c82cc661-d06c-4a57-a29c-946fb7f433b3\"},\"event\":{\"request\":\"payload\"}}"
   :method :post
   :url "http://localhost:3246/2018-06-01/runtime/invocation/c82cc661-d06c-4a57-a29c-946fb7f433b3/response"})

(test (sut/lambda-response (fn [_] (error "Uh oh")) invocation)
  {:body @"{\"errorType\":\"HandlerError\",\"errorMessage\":\"Uh oh\"}"
   :headers {"Lambda-Runtime-Function-Error-Type" "Runtime.UnknownReason"}
   :method :post
   :url "http://localhost:3246/2018-06-01/runtime/invocation/c82cc661-d06c-4a57-a29c-946fb7f433b3/error"})

(test (sut/handler-init (fn [] (error "Uh oh")))
  {:headers {"Lambda-Runtime-Function-Error-Type" "Runtime.HandlerInit"}
   :method :post
   :url "http://localhost:3246/2018-06-01/runtime/init/error"})

(test (sut/handler-init (fn [] nil)) nil)

(test (sut/invocation {:headers {:not-interesting-header "value"
                                 :lambda-runtime-aws-request-id "id"}
                       :body (json/encode {:json-encoded :body})})
  {:ctx @{:lambda-runtime-aws-request-id "id"}
   :event @{:json-encoded "body"}})
