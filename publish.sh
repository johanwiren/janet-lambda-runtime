#!/bin/sh

set -euo pipefail

docker build -t janet-example --build-arg WITH_SOURCE=${WITH_SOURCE:-} .
docker run --rm janet-example tar -cf - lambda | tar xf -
aws lambda update-function-code --function-name test-janet --zip-file fileb://lambda/lambda.zip
