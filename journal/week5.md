# Week 5 — DynamoDB and Serverless Caching


# Restructure Script Folders

As we are going to create more scripts, we implement the following folders structure following:

For each postgres script, the folder will be the following:
```
backend-flask/bin/db-connect → backend-flask/bin/db/connect
backend-flask/bin/db-create → backend-flask/bin/db/create
backend-flask/bin/db-drop → backend-flask/bin/db/drop
backend-flask/bin/db-schema-load → backend-flask/bin/db/schema-load
backend-flask/bin/db-seed → backend-flask/bin/db/seed
backend-flask/bin/db-sessions → backend-flask/bin/db/sessions
backend-flask/bin/db-setup → backend-flask/bin/db/setup

```

Note: Inside the file **backend-flask/bin/db/setup** we added the following code 

```
python "$bin_path/db/update_cognito_user_ids"
```
The file ([**update_cognito_user_ids**](https://github.com/dontworryjohn/aws-bootcamp-cruddur-2023/blob/main/backend-flask/bin/db/update_cognito_user_ids)) must be created. The script adds the cognito user id.

Make sure to add **boto3** into **backend-flask/requirements.txt**, which is the AWS SDK for Python to create, configure, and manage AWS services such as DynamoDB.

Add in .gitpod.yml the following ([code](https://github.com/dontworryjohn/aws-bootcamp-cruddur-2023/commit/549f34baa8e09bbe51d65a5f87e49c1462afe2a0)). This allows to install python libraries automatically whenever a new workspace is launched.

Update **backend-flask/db/seed.sql** with the following [**code**](https://github.com/dontworryjohn/aws-bootcamp-cruddur-2023/blob/main/backend-flask/db/seed.sql)). The new query contains information that are inside the cognito user pool. Therefore update with your information.

Create [backend-flask/bin/cognito/list-users](https://github.com/dontworryjohn/aws-bootcamp-cruddur-2023/blob/main/backend-flask/bin/cognito/list-users)). to list users data saved in AWS Cognito

On **docker-compose.yml** insert if not exist the following **CONNECTION_URL: "postgresql://postgres:password@db:5432/cruddur"** and comment #CONNECTION_URL: "${PROD_CONNECTION_URL}". This week we wont use RDS.

# Implementations

## DynamoDB Scripts
In this section, it is listed the main scripts used during the development (local and production)

- **./bin/ddb/drop** ([code](https://github.com/dontworryjohn/aws-bootcamp-cruddur-2023/blob/main/backend-flask/bin/ddb/drop)): This script allows to drop dynamo db table

- **./bin/ddb/list-tables** ([code](https://github.com/dontworryjohn/aws-bootcamp-cruddur-2023/blob/main/backend-flask/bin/ddb/drop)): This script allows the list of the table that has been created.

- **./bin/ddb/scan**  ([code](https://github.com/dontworryjohn/aws-bootcamp-cruddur-2023/blob/main/backend-flask/bin/ddb/scan)): This script shows all the items inside of the table.

- **./bin/ddb/schema-load** ([code](https://github.com/dontworryjohn/aws-bootcamp-cruddur-2023/blob/main/backend-flask/bin/ddb/schema-load)): This script allows the creation of the dynamodb **cruddur-messages** either locally or in production

- **./bin/ddb/seed** ([code](https://github.com/dontworryjohn/aws-bootcamp-cruddur-2023/blob/main/backend-flask/bin/ddb/schema-load)): This script loads some mock data inside the table with hardcoded **message_group_uuid**
(Note: The **my_handle** and **other_handle** were replaced with 2 users that are avaialble on cognito user pool. the **created_at** was modified as it could cause error if you create a new message.)

NB: Make sure to do the 
**Chmod u+x** for the new scripts

## Implementation of Messages with the local DynamoDB

Create the following file [**backend-flask/lib/ddb.py](https://github.com/dontworryjohn/aws-bootcamp-cruddur-2023/blob/main/backend-flask/lib/ddb.py). 
Make sure to create **AWS_ENDPOINT_URL: "http://dynamodb-local:8000"** inside the **docker-compose.yml**.

For additional changes from the backend see the [repo](https://github.com/dontworryjohn/aws-bootcamp-cruddur-2023/commits/main/backend-flask)  and frontent [repo](https://github.com/dontworryjohn/aws-bootcamp-cruddur-2023/commits/main/frontend-react-js)

To retrieve messages and message groups from Dynamodb instead of using hard-coded data, modify the backend routes and functions. Rather than passing in a handle, use message_group_uuid. The Ddb class's list_message_groups and list_messages are mainly used for these implementations.

Make the following changes in backend-flask/app.py: replace "/api/messages/@string:handle" with "/api/messages/string:message_group_uuid".

Also, make modifications in the backend-flask/services/message_groups.py and backend-flask/services/messages.py files.

In the frontend-react-js/src/pages/MessageGroupPage.js, update the backend_url to use ${params.message_group_uuid} instead of ${handle}, and in frontend-react-js/src/App.js, change the path from "/messages/@:handle" to "/messages/:message_group_uuid".

In frontend-react-js/src/components/MessageGroupItem.js, change props.message_group.handle to props.message_group.uuid and params.handle to params.message_group_uuid.

For authentication, create a reusable script in frontend-react-js/src/lib/CheckAuth.js, which can be used in frontend-react-js/src/pages/HomeFeedPage.js, frontend-react-js/src/pages/MessageGroupPage.js, frontend-react-js/src/pages/MessageGroupsPage.js, and frontend-react-js/src/components/MessageForm.js.

To create a new message, modify the content for body in frontend-react-js/src/components/MessageForm.js. Update the data_create_message function in backend-flask/app.py and backend-flask/services/create_message.py, which has two modes - "update" to a new message group or "create" a new message with a new message group.

Create backend-flask/db/sql/users/create_message_users.sql.

For additional pages, use create_message_group of the Ddb class. In frontend-react-js/src/App.js, import MessageGroupNewPage and add the corresponding router.

Create frontend-react-js/src/pages/MessageGroupNewPage.js and frontend-react-js/src/components/MessageGroupNewItem.js.

Add the endpoint and function for user short in backend-flask/app.py, create backend-flask/services/users_short.py and backend-flask/db/sql/users/short.sql.

Finally, update frontend-react-js/src/components/MessageGroupFeed.js and frontend-react-js/src/components/MessageForm.js.




## Implementation DynamoDB Data Stream to update message groups
 
Before creating the new DynamoDB table, replace the new code for the script **/bin/ddb/schema-load** and make sure the **AWS_ENDPOINT_URL: "http://dynamodb-local:8000"** from the **docker-compose.yml** is commented.

```
#!/usr/bin/env python3

import boto3
import sys

attrs = {
    'endpoint_url':'http://localhost:8000'
}

if len(sys.argv) == 2:
    if "prod" in sys.argv[1]:
        attrs={}

ddb = boto3.client('dynamodb',**attrs)

table_name = 'cruddur-messages'

response = ddb.create_table(
    TableName=table_name,
    AttributeDefinitions=[
        {
            'AttributeName': 'message_group_uuid',
            'AttributeType': 'S'
        },
        {
            'AttributeName': 'pk',
            'AttributeType': 'S'
        },
        {
            'AttributeName': 'sk',
            'AttributeType': 'S'
        },
    ],
    KeySchema=[
        {
            'AttributeName': 'pk',
            'KeyType': 'HASH'
        },
          {
            'AttributeName': 'sk',
            'KeyType': 'RANGE'
        },
    ],
    GlobalSecondaryIndexes=[{
    'IndexName':'message-group-sk-index',
    'KeySchema':[{
      'AttributeName': 'message_group_uuid',
      'KeyType': 'HASH'
    },{
      'AttributeName': 'sk',
      'KeyType': 'RANGE'
    }],
    'Projection': {
      'ProjectionType': 'ALL'
    },
    'ProvisionedThroughput': {
      'ReadCapacityUnits': 5,
      'WriteCapacityUnits': 5
    },
    }],
    BillingMode='PROVISIONED',
    ProvisionedThroughput={
        'ReadCapacityUnits': 5,
        'WriteCapacityUnits': 5
    },
    Tags=[
        {
            'Key': 'PROJECT',
            'Value': 'CRUDDER'
        },
    ],
)
print(response)
```

Create the table using the script. This will create the dynamodb in your aws account. 

```
/bin/ddb/schema-load prod
```
Note: If you returns the error **table already exists: cruddur-messages**, that means the table is already created in your account. if you dont see the table, make sure you are in the right region.
Once created the table, active the **DynamoDB Stream**.
From the table, go to the tab **Exports and streams**>Section **DynamoDB stream details** click active>Select **New image**
**


The next steps is to create the endpoint.
To do please follow the instruction in the [link](https://scribehow.com/shared/Amazon_Workflow__9knsACwST_equLV8dYYa9A).

Once you create the endpoint, next to do is to create the lambda fuction.

Use the following code for the lambda function:
```
import json
import boto3
from boto3.dynamodb.conditions import Key, Attr

dynamodb = boto3.resource(
 'dynamodb',
 region_name='YOURREGION',
 endpoint_url="http://dynamodb.YOURREGION.amazonaws.com"
)

def lambda_handler(event, context):
  print('event-data',event)
  eventName = event['Records'][0]['eventName']
  if (eventName == 'REMOVE'):
    print("skip REMOVE event")
    return
  pk = event['Records'][0]['dynamodb']['Keys']['pk']['S']
  sk = event['Records'][0]['dynamodb']['Keys']['sk']['S']
  if pk.startswith('MSG#'):
    group_uuid = pk.replace("MSG#","")
    message = event['Records'][0]['dynamodb']['NewImage']['message']['S']
    print("GRUP ===>",group_uuid,message)
    
    table_name = 'cruddur-messages'
    index_name = 'message-group-sk-index'
    table = dynamodb.Table(table_name)
    data = table.query(
      IndexName=index_name,
      KeyConditionExpression=Key('message_group_uuid').eq(group_uuid)
    )
    print("RESP ===>",data['Items'])
    
    # recreate the message group rows with new SK value
    for i in data['Items']:
      delete_item = table.delete_item(Key={'pk': i['pk'], 'sk': i['sk']})
      print("DELETE ===>",delete_item)
      
      response = table.put_item(
        Item={
          'pk': i['pk'],
          'sk': sk,
          'message_group_uuid':i['message_group_uuid'],
          'message':message,
          'user_display_name': i['user_display_name'],
          'user_handle': i['user_handle'],
          'user_uuid': i['user_uuid']
        }
      )
      print("CREATE ===>",response)
```
Note: from the following  region_name='YOURREGION',
 endpoint_url="http://dynamodb.YOURREGION.amazonaws.com" insert the region where you have deployed your resources.

Follow the instruction to create the [lambda, role and trigger](https://scribehow.com/shared/How_to_create_a_Lambda_function_with_VPC_and_DynamoDB_triggers__EPcZPPH8T7SW8Yn5zsdAqw).



Reference
- Contino.Io
- AWS Documentation
- [Ashish Video Cloud Security Podcast](https://www.youtube.com/watch?v=gFPljPNnK2Q&list=PLBfufR7vyJJ7k25byhRXJldB5AiwgNnWv&index=51)
