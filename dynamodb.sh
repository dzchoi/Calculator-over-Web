#!/bin/sh -e

# Script for create a new table in AWS DynamoDB, which has a single key 'Id' of string

# adjust this for your configuration of AWS CLI
profile=your_profile_name

# table name to be created; 'tableCalc' by default
table=${1:-tableCalc}	# table name can be given as a command-line parameter

if ! aws dynamodb describe-table --table-name $table 2>/dev/null; then
aws dynamodb create-table --profile $profile \
--table-name $table \
--attribute-definitions AttributeName=Id,AttributeType=S \
--key-schema AttributeName=Id,KeyType=HASH \
--provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
fi
