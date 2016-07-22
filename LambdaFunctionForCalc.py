# AWS Lambda provides an easy way to build back ends without managing servers.
# API Gateway and Lambda together can be powerful to create and deploy
# serverless Web applications.

from __future__ import print_function

import boto3 # see https://boto3.readthedocs.io/en/latest/ for boto3
import json

import ast  # Abstract Syntax Tree for parsing and evaluating
import operator as op



def dynamo_get(name):
    global dynamo

    item = dynamo.get_item(Key = {'Id': name})
    if 'Item' in item and 'value' in item['Item']:
        return item['Item']['value']
    else:
        return 0    # if not defined well

def dynamo_scan():
    global dynamo

    items = dynamo.scan()
    ans = ''
    if 'Items' in items:
        for item in items['Items']:
            ans += item['Id'] + ' : ' + \
                str(item['value'] if 'value' in item else 0) + \
                '\n'
    return ans

def dynamo_put(name, value):
    global dynamo
    dynamo.put_item(Item = {'Id': name, 'value': value})



# supported operators
operators = {
    ast.Add: op.add, ast.Sub: op.sub, ast.Mult: op.mul, ast.Div: op.truediv,
    ast.Pow: op.pow, ast.USub: op.neg
}

def eval_(node):
    if isinstance(node, ast.Num):       # <number>
        return node.n

    elif isinstance(node, ast.Name):    # <name>
        return dynamo_get(node.id)

    elif isinstance(node, ast.BinOp):   # <left> <operator> <right>
        return operators[type(node.op)](eval_(node.left), eval_(node.right))

    elif isinstance(node, ast.UnaryOp): # <operator> <operand> e.g., -1
        return operators[type(node.op)](eval_(node.operand))

    else:
        raise TypeError(node)   # incurs an internal error

def eval_expr(expr):
    return eval_(ast.parse(expr, mode='eval').body)



def handler(event, context):
    #print("Received event: " + json.dumps(event, indent=2))

    global dynamo
    dynamo = boto3.resource('dynamodb').Table(
        event['table'] if 'table' in event and event['table'] else 'tableCalc'
    )   # using 'tableCalc' if 'table' is not given as a query string parameter

    var = event['var'] if 'var' in event else ''
    opr = event['op'] if 'op' in event else ''

    if opr:
        # compute the expression
        try:
            ans = eval_expr(opr)
        except: # such as ZeroDivisionError
            return 'Computation Error'

        if var:
            dynamo_put(var, ans)    # save as a number (not a string)
            return var + ' = ' + str(ans)
        else:
            return str(ans)

    else:
        # list variable(s)
        if var:
            return var + ' : ' + str(dynamo_get(var))
        else:
            return dynamo_scan()
