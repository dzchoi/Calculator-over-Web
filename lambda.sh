#!/bin/bash -e
# process substitution <() requires bash (instead of dash)

# Script to create/update an AWS Lambda function from *.py in current directory

# The AWS Service role of the type AWS Lambda 'lambda-gateway-execution-role' should be
# prepared by following http://docs.aws.amazon.com/lambda/latest/dg/with-on-demand-https-example-create-iam-role.html.
# This role grants the AWS Lambda service permissions to assume the role.

# reference:
# - http://docs.aws.amazon.com/lambda/latest/dg/with-on-demand-https-example-upload-deployment-pkg.html

# adjust these for your configuration of AWS CLI
profile=your_profile_name
region=your_region_name
account_id=your_amazon_account_id

# get the lambda function name from current directory
set - $(ls *.py)
function=${1%.*}
if [ ! $function ]; then echo No code; exit; fi

if aws lambda list-functions | grep -q '"FunctionName": "'$function'"'; then
# update the code for the Lambda function if it exists
aws lambda update-function-code \
    --profile $profile \
    --region $region \
    --function-name $function \
    --function-name $function \
    --zip-file fileb://<(zip - $function.py)
else
# create a new Lambda function
aws lambda create-function \
    --profile $profile \
    --region $region \
    --role arn:aws:iam::$account_id:role/lambda-gateway-execution-role \
    --function-name $function \
    --zip-file fileb://<(zip - $function.py) \
    --handler $function.handler \
    --runtime python2.7

#or to load from a S3 bucket
#aws lambda create-function \
    #--profile $profile \
    #--region $region \
    #--role arn:aws:iam::$account_id:role/lambda-gateway-execution-role \
    #--function-name LambdaFunctionForCalc \
    #--code S3Bucket=<bucket-name>,S3Key=<zip-file-object-key> \
    #--handler LambdaFunctionForCalc.handler \
    #--runtime python2.7
fi
