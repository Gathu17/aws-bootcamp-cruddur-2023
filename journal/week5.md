# Week 5 — DynamoDB and Serverless Caching

# BynamoDB modelling

The following chart describes the model for our cruddur app
![Screenshot (2201)](https://user-images.githubusercontent.com/92152669/231102379-9e4a01dd-56a4-45c9-ac89-a14db0718e87.png)

The message group contains  conversation between different users. 
We have our message_group_uuid as the partition key and created_at as the sort key.
In Amazon DynamoDB, a partition key and sort key together form a composite primary key for a table. When users creates new item , DynamoDB uses partition key to identify which partition to put the item. The sort key is used to sort items within the partition.


# Reorganized Bash scripts

Created different folders for postgreSQL scripts and DynamoDB scripts.

Added boto3 library(the AWS SDK for Python to create, configure, and manage AWS services such as DynamoDB) to requirements.txt file.
In the postCreateCommand of DevConatiner the command to add the boto3 library was inserted.

The utility scripts were created that would:
 - load schema for our tables in dynamoDB ![Screenshot (2204)](https://user-images.githubusercontent.com/92152669/231132629-f7d22578-bd8a-4bde-9296-39cd3377c9cc.png)

 - dropping cruddur messages table ![Screenshot (2203)](https://user-images.githubusercontent.com/92152669/231132374-53cb1ff0-bc3a-4f87-9eec-0bf400fefe97.png)

 - scanning the table
 - seeding data to our table ![Screenshot (2202)](https://user-images.githubusercontent.com/92152669/231132056-077e4031-69cc-4bfe-ae46-bcc7ad25a3c1.png)

 - list tables in DynamoDB ![Screenshot (2205)](https://user-images.githubusercontent.com/92152669/231132822-64823734-a14f-4381-9aff-3dd916986170.png)

 - patterns to get and list conversations ![Screenshot (2206)](https://user-images.githubusercontent.com/92152669/231133147-6fd5f643-5c00-456b-8ec4-b3a6c786ddeb.png)


The scripts can be found [here](https://github.com/Gathu17/aws-bootcamp-cruddur-2023/tree/main/backend-flask/bin/ddb)

To populate the cognito_user_uuid that is present in our seed database as mock as seen [here](https://github.com/Gathu17/aws-bootcamp-cruddur-2023/blob/main/backend-flask/db/seed.sql), a script to list cognito users was added.[script](https://github.com/Gathu17/aws-bootcamp-cruddur-2023/blob/main/backend-flask/bin/cognito/list-users)

The script that populated cognito_user_id column in the table is seen [here](https://github.com/Gathu17/aws-bootcamp-cruddur-2023/blob/main/backend-flask/bin/db/update_cognito_user_ids) was ran. 
![Screenshot (2207)](https://user-images.githubusercontent.com/92152669/231137274-377d76ce-636c-4ea4-b7b8-e81c8ed50362.png)

**NB** The CONNECTION_URL in docker-compose should point to postgres database being used.



## Creating messages and message groups in DynamoDB

The following file was added [backend-flask/lib/ddb.py](https://github.com/Gathu17/aws-bootcamp-cruddur-2023/blob/main/backend-flask/lib/ddb.py). 
Make sure to add **AWS_ENDPOINT_URL: "http://dynamodb-local:8000"** inside the **docker-compose.yml**.
The ``` Ddb.py ``` contains class Ddb with methods to 
 - list message grups
 - list messages
 - create message
 - create message group
 
The slass is used in our backend service for message groups [here](https://github.com/Gathu17/aws-bootcamp-cruddur-2023/blob/main/backend-flask/services/message_groups.py)
Here my_user_uuid is used to fetch the message group linked to that users uuid. The SQL script to fetch users.uuid using the cognito_user_id was added as shown
[here](https://github.com/Gathu17/aws-bootcamp-cruddur-2023/blob/main/backend-flask/db/sql/users/uuid_from_cognito_user_id.sql)

Make sure to also add the message groups api in ```app.py```.
```
@app.route("/api/message_groups", methods=['GET'])
def data_message_groups():
  access_token = extract_access_token(request.headers)
  try:
    claims = cognito_jwt_token.verify(access_token)
    # authenicatied request
    app.logger.debug("authenicated")
    app.logger.debug(claims)
    cognito_user_id = claims['sub']
    model = MessageGroups.run(cognito_user_id=cognito_user_id)
    if model['errors'] is not None:
      return model['errors'], 422
    else:
      return model['data'], 200
  except TokenVerifyError as e:
    # unauthenicatied request
    app.logger.debug(e)
    return {}, 401
   
```
#### Frontend implementation
Created module in the util folder that checks if users is authenticated. 



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
