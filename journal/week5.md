# Week 5 — DynamoDB and Serverless Caching

# DynamoDB modelling

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
Created module in the util folder that checks if users is authenticated. [checkAuth](https://github.com/Gathu17/aws-bootcamp-cruddur-2023/blob/main/frontend-react-js/src/util/checkAuth.js)

The folder is imported into ```MessageGroupPage.js``` , ```MessageGroupsPage``` and ```HomeFeedPage.js```.

The message_group_uuid was passed to the ```MessageGroupPage.js``` file as params to our backend url..
In the backend a new api was used that selected the message_group using the params set
```
@app.route("/api/messages/<string:message_group_uuid>", methods=['GET'])
def data_messages(message_group_uuid):
  access_token = extract_access_token(request.headers)
  try:
    claims = cognito_jwt_token.verify(access_token)
    # authenicatied request
    app.logger.debug("authenicated")
    app.logger.debug(claims)
    cognito_user_id = claims['sub']
    model = Messages.run(
        cognito_user_id=cognito_user_id,
        message_group_uuid=message_group_uuid
      )
    if model['errors'] is not None:
      return model['errors'], 422
    else:
      return model['data'], 200
  except TokenVerifyError as e:
    # unauthenicatied request
    app.logger.debug(e)
    return {}, 401
```

In frontend-react-js/src/components/MessageGroupItem.js,props.message_group.handle was changed to props.message_group.uuid and params.handle to params.message_group_uuid.

The codes in backend services ```messages.py``` was modified to list conversation that have the message_group_uuid
![Screenshot (2216)](https://user-images.githubusercontent.com/92152669/231453840-5f3ff438-27b1-40a6-bef5-c8a76f075dd7.png)


To create a new message, modify the content for body in frontend-react-js/src/components/MessageForm.js. Update the create_message.py module in backend services and 
add api endpoint in ```app.py```
```
@app.route("/api/messages", methods=['POST','OPTIONS'])
@cross_origin()
def data_create_message():
  message_group_uuid   = request.json.get('message_group_uuid',None)
  user_receiver_handle = request.json.get('handle',None)
  message = request.json['message']
  access_token = extract_access_token(request.headers)

  try:
    claims = cognito_jwt_token.verify(access_token)
    # authenicatied request
    app.logger.debug("authenicated")
    app.logger.debug(claims)
    cognito_user_id = claims['sub']
    if message_group_uuid == None:
      # Create for the first time
      model = CreateMessage.run(
        mode="create",
        message=message,
        cognito_user_id=cognito_user_id,
        user_receiver_handle=user_receiver_handle
      )
    else:
      # Push onto existing Message Group
      model = CreateMessage.run(
        mode="update",
        message=message,
        message_group_uuid=message_group_uuid,
        cognito_user_id=cognito_user_id
      )
    if model['errors'] is not None:
      return model['errors'], 422
    else:
      return model['data'], 200
  except TokenVerifyError as e:
    # unauthenicatied request
    app.logger.debug(e)
    return {}, 401
    
    
```
 
![created message](https://user-images.githubusercontent.com/92152669/231454638-a25727dd-9e6e-49a3-963a-5a6bd80031a1.png)
Next would be to create a new conversation. A new user was added to in our seed.sql file. 


Added [create_message_users.sql](https://github.com/Gathu17/aws-bootcamp-cruddur-2023/blob/main/backend-flask/db/sql/users/create_message_users.sql)
In our frontend add a newe route ```/new/:handle``` for the new conversation.





## Implementating DynamoDB Data Stream to update message groups
 
Before creating the new DynamoDB table, replace the new code for the script ```/bin/ddb/schema-load``` and make sure the AWS_ENDPOINT_URL: "http://dynamodb-local:8000" from the **docker-compose.yml** is commented or removed.

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

Create the table using the script. This will create the dynamodb in aws account. 

```
/bin/ddb/schema-load prod
```




 To create the VPC endpoint  follow the instruction in the [link](https://scribehow.com/shared/Amazon_Workflow__9knsACwST_equLV8dYYa9A).

A new lambda function was also created. For the role, the permissions for ```AWSLambdaInvocation-DynamoDB``` and ```AWSDynamoDBFullAccess must be attached. **NB** Add the trigger to our Amazon DynamoDB database. Also make sure to turn on data streams from the tab **Exports and streams**

Once the lambda function is created the following code was added.
```
import json
import boto3
from boto3.dynamodb.conditions import Key, Attr

dynamodb = boto3.resource(
 'dynamodb',
 region_name='YOUR_REGION',
 endpoint_url="http://dynamodb.YOUR_REGION.amazonaws.com"
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

![Screenshot (2218)](https://user-images.githubusercontent.com/92152669/231460531-41b5dfc2-7038-472c-9064-90129fc0a0b0.png)

