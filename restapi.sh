#!/bin/sh -ex

# Script to create a RESTful API for an AWS Lambda function from *.py in current directory
# The API accepts a GET method for the '/' resource with the following three query string
# parameters: 'op', 'var', and 'table'.

# adjust these for your configuration of AWS CLI
profile=your_profile_name
region=your_region_name

# references:
# - Using AWS Lambda with Amazon API Gateway (On-Demand Over HTTPS)
#  http://docs.aws.amazon.com/lambda/latest/dg/with-on-demand-https-example.html
# - Using Amazon API Gateway as a AWS service proxy for DynamoDB:
#  https://aws.amazon.com/blogs/compute/using-amazon-api-gateway-as-a-proxy-for-dynamodb/



# get the lambda function name from current directory
set - $(ls *.py)
function=${1%.*}
if [ ! $function ]; then echo No code; exit; fi

#:<<'###'
# create the API
aws apigateway create-rest-api --profile $profile \
--name $function | tee /dev/tty |
grep -Po '(?<="id": ").*(?=")' >./rest-api-id

# get the ID of the API root resource
aws apigateway get-resources --profile $profile \
--rest-api-id $(cat ./rest-api-id) | tee /dev/tty |
grep -Po '(?<="id": ").*(?=")' >./resource-id

# create method (GET) on the resource
aws apigateway put-method --profile $profile \
--rest-api-id $(cat ./rest-api-id) \
--resource-id $(cat ./resource-id) \
--http-method GET \
--authorization-type NONE \
--request-parameters '{"method.request.querystring.op": false, "method.request.querystring.var": false, "method.request.querystring.table": false}'

# set the Lambda Function as the destination for the GET method
aws apigateway put-integration --profile $profile \
--rest-api-id $(cat ./rest-api-id) \
--resource-id $(cat ./resource-id) \
--http-method GET \
--type AWS \
--integration-http-method POST \
--uri "arn:aws:apigateway:$region:lambda:path/2015-03-31/functions/arn:aws:lambda:$region:$(cat ~/.aws/aws-acct-id.txt):function:$function/invocations" \
--request-templates '{"application/json": "{\"op\": \"$input.params('"'op'"')\", \"var\": \"$input.params('"'var'"')\", \"table\": \"$input.params('"'table'"')\"}"}' \
--passthrough-behavior WHEN_NO_TEMPLATES

# set the GET method response to JSON
aws apigateway put-method-response --profile $profile \
--rest-api-id $(cat ./rest-api-id) \
--resource-id $(cat ./resource-id) \
--http-method GET \
--status-code 200 \
--response-models '{"application/json": "Empty"}' \
--response-parameters '{"method.response.header.Content-Type": false}'

# set the GET method integration response to JSON
aws apigateway put-integration-response --profile $profile \
--rest-api-id $(cat ./rest-api-id) \
--resource-id $(cat ./resource-id) \
--http-method GET \
--status-code 200 \
--response-parameters "{\"method.response.header.Content-Type\": \"'text/plain'\"}"

# deploy the API
aws apigateway create-deployment --profile $profile \
--rest-api-id $(cat ./rest-api-id) \
--stage-name calc

# grant the API permission to invoke the Lambda function; the permissions associated with
# the Lambda function can be checked with: aws lambda get-policy --function-name ...
aws lambda add-permission --profile $profile \
--function-name $function \
--statement-id $function \
--action lambda:InvokeFunction \
--principal apigateway.amazonaws.com \
--source-arn "arn:aws:execute-api:$region:$(cat ~/.aws/aws-acct-id.txt):$(cat ./rest-api-id)/calc/GET/"
###
