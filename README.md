# Calculator over Web
A web application for calculating arithmetic expressions using AWS

The hyperlinks below can be clicked on directly from this email or the text on the hyperlink can be just copied (including space characters) and pasted into any web browsers.

##Usage examples:

1. compute `(3 - 1) * 2`  
[https://h7f1a8znc2.execute-api.us-east-1.amazonaws.com/calc?op=(3 - 1) * 2](https://h7f1a8znc2.execute-api.us-east-1.amazonaws.com/calc?op=(3 - 1) * 2)  
--> will say `"4"`

2. compute `6**100` (6 to the power of 100)  
[https://h7f1a8znc2.execute-api.us-east-1.amazonaws.com/calc?op=6**100](https://h7f1a8znc2.execute-api.us-east-1.amazonaws.com/calc?op=6**100)  
--> will say `"653318623500070906096690267158057820537143710472954871543071966369497141477376"`

3. compute `(3 - 1) * 2` and store it into the variable A  
[https://h7f1a8znc2.execute-api.us-east-1.amazonaws.com/calc?var=A&op=(3 - 1) * 2](https://h7f1a8znc2.execute-api.us-east-1.amazonaws.com/calc?var=A&op=(3 - 1) * 2)  
--> will say `"A = 4"`

4. compute `A / 2` and store it into the variable B  
[https://h7f1a8znc2.execute-api.us-east-1.amazonaws.com/calc?var=B&op=A / 2](https://h7f1a8znc2.execute-api.us-east-1.amazonaws.com/calc?var=B&op=A / 2)  
--> will say `"B = 2"`

5. compute `A * B`  
[https://h7f1a8znc2.execute-api.us-east-1.amazonaws.com/calc?op=A * B](https://h7f1a8znc2.execute-api.us-east-1.amazonaws.com/calc?op=A * B)  
--> will say `"8"`

6. look up variable `A`  
[https://h7f1a8znc2.execute-api.us-east-1.amazonaws.com/calc?var=A](https://h7f1a8znc2.execute-api.us-east-1.amazonaws.com/calc?var=A)  
--> will say `"A : 4"`

7. look up all the variables  
[https://h7f1a8znc2.execute-api.us-east-1.amazonaws.com/calc](https://h7f1a8znc2.execute-api.us-east-1.amazonaws.com/calc)  
--> will say `"A : 4\nB : 2\n"`

8. compute `1 + 2` (note '+' was decoded as '%2b' to conform to the URL encoding rule)  
[https://h7f1a8znc2.execute-api.us-east-1.amazonaws.com/calc?op=1 %2b 2](https://h7f1a8znc2.execute-api.us-east-1.amazonaws.com/calc?op=1 %2b 2)  
--> will say `"3"`

##Details of the query string parameters:
- `op` : (optional) the arithmetic expression to compute
- `var` : (optional) name of the variable that will store the computed result (with 'op' parameter) or will show its content (without 'op' parameter)
- `table` : (optional) name of the table (`tableCalc` by default) in AWS DynamoDB that contains all the variables mentioned in the expressions

Calculations are performed in the number system of Python and the following operators can be used now in the expressions:
  `+`(addition), `-`(subtraction or unary minus), `*`(multiplication), `/`(division), `**`(power).

##About the internals of the application.
This application consists of the following three AWS services.
- AWS gateway API:
  - accepts the arithmetic expressions in the form of query string parameters through RESTful API,
  - converts the query string parameters into a json data, and
  - invokes the AWS lambda function with the json data to compute expressions.
- AWS lambda:
  - runs the Python function 'LambdaFunctionForCalc' that actually computes the expressions and
  - makes use of the AWS DynamoDB service using the AWS SDK for Python, Boto3.
- AWS DynamoDB:
  - the NoSQL database that holds the variables and that is searched for the variables.

##How to install the application into AWS
1. (optional) install AWS CLI
2. create the execution role 'lambda-gateway-execution-role' with the inline policy:

    ```
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "Stmt1428341300017",
          "Action": [
            "dynamodb:DescribeTable",
            "dynamodb:DeleteItem",
            "dynamodb:GetItem",
            "dynamodb:PutItem",
            "dynamodb:Query",
            "dynamodb:Scan",
            "dynamodb:UpdateItem"
          ],
          "Effect": "Allow",
          "Resource": "*"
        },
        {
          "Sid": "",
          "Resource": "*",
          "Action": [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          "Effect": "Allow"
        }
      ]
    }
    ```
3. run `./dynamo.sh` to create the table 'tableCalc' in dynamoDB
4. run `./lambda.sh` from the same directory of `LambdaFunctionForCalc.py` to create the Lambda function 'LambdaFunctionForCalc'
5. run `./restapi.sh` from the same directory of `LambdaFunctionForCalc.py` to create the RESTful API
