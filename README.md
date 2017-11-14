# Calculator over Web
A web application for calculating arithmetic expressions using AWS

The hyperlinks below can be clicked on directly from this document, or the text behind the hyperlink can be copied and pasted into any web browsers. Space characters are allowed inside mathematical expressions, but in the URL, most web browsers will require them to be converted to '`%20`'.

### Usage examples:

1. compute `(3 - 1) * 2`  
[https://h7f1a8znc2.execute-api.us-east-1.amazonaws.com/calc?op=(3-1)*2](https://h7f1a8znc2.execute-api.us-east-1.amazonaws.com/calc?op=(3%20-%201)%20*%202)  
--> will say `"4"`

2. compute `6**100` (6 to the power of 100)  
[https://h7f1a8znc2.execute-api.us-east-1.amazonaws.com/calc?op=6\*\*100](https://h7f1a8znc2.execute-api.us-east-1.amazonaws.com/calc?op=6**100)  
--> will say `"653318623500070906096690267158057820537143710472954871543071966369497141477376"`

3. compute `(3 - 1) * 2` and store it into the variable A  
[https://h7f1a8znc2.execute-api.us-east-1.amazonaws.com/calc?var=A&op=(3-1)*2](https://h7f1a8znc2.execute-api.us-east-1.amazonaws.com/calc?var=A&op=(3%20-%201)%20*%202)  
--> will say `"A = 4"`

4. compute `A / 2` and store it into the variable B  
[https://h7f1a8znc2.execute-api.us-east-1.amazonaws.com/calc?var=B&op=A/2](https://h7f1a8znc2.execute-api.us-east-1.amazonaws.com/calc?var=B&op=A%20/%202)  
--> will say `"B = 2"`

5. compute `A * B`  
[https://h7f1a8znc2.execute-api.us-east-1.amazonaws.com/calc?op=A*B](https://h7f1a8znc2.execute-api.us-east-1.amazonaws.com/calc?op=A%20*%20B)  
--> will say `"8"`

6. look up variable `A`  
[https://h7f1a8znc2.execute-api.us-east-1.amazonaws.com/calc?var=A](https://h7f1a8znc2.execute-api.us-east-1.amazonaws.com/calc?var=A)  
--> will say `"A : 4"`

7. look up all the variables  
[https://h7f1a8znc2.execute-api.us-east-1.amazonaws.com/calc](https://h7f1a8znc2.execute-api.us-east-1.amazonaws.com/calc)  
--> will say `"A : 4\nB : 2\n"`

8. compute `1 + 2` (note '+' was decoded as '`%2b`' to conform to the URL encoding rule)  
[https://h7f1a8znc2.execute-api.us-east-1.amazonaws.com/calc?op=1%2b2](https://h7f1a8znc2.execute-api.us-east-1.amazonaws.com/calc?op=1%20%2b%202)  
--> will say `"3"`

### Details of the query string parameters:
- `op` : (optional) the arithmetic expression to compute
- `var` : (optional) name of the variable that will store the computed result (with 'op' parameter) or will show its content (without 'op' parameter)
- `table` : (optional) name of the table (`tableCalc` by default) in AWS DynamoDB that contains all the variables mentioned in the expressions

Calculations are performed in the Python number system, so integers with any number of digits and floating-point numbers with any precision can be used. The following operators can be used in the expressions for this simple calculator (although support of built-in functions such as trigonometric ones could be done by extending the parser in `LambdaFunctionForCalc` in :
  `+`(addition), `-`(subtraction or unary minus), `*`(multiplication), `/`(division), `**`(power).

### About the internals of the application.
This application consists of the following three AWS services.
- AWS gateway API:
  - accepts the arithmetic expressions in the form of query string parameters through RESTful API,
  - converts the query string parameters into a json data, and
  - invokes the AWS lambda function with the json data to compute expressions.
- AWS lambda:
  - runs the Python function `LambdaFunctionForCalc` that actually computes the expressions and
  - makes use of the AWS DynamoDB service using the AWS SDK for Python, Boto3.
- AWS DynamoDB:
  - the NoSQL database that holds the variables and that is searched for the variables.

### How to install the application into AWS
1. (optional) Install AWS CLI
2. Create the execution role 'lambda-gateway-execution-role' with the inline policy:

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
3. Run `./dynamo.sh` to create the table 'tableCalc' in dynamoDB
4. Run `./lambda.sh` from the same directory of `LambdaFunctionForCalc.py` to create the Lambda function 'LambdaFunctionForCalc'
5. Run `./restapi.sh` from the same directory of `LambdaFunctionForCalc.py` to create the RESTful API
  - or create a REST API in AWS console referencing the following structure and use this as a custom template for the content-type of `application/json` in the Integration Request for the GET method:

    ```
    {
      "op": "$input.params('op')",
      "var": "$input.params('var')",
      "table": "$input.params('table')"
    }
    ```

### Structure of the REST API
![alt tag](https://raw.githubusercontent.com/dzchoi/Calculator-over-Web/master/REST-API.png)
