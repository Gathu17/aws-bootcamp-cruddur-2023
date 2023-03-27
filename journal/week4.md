# Week 4 — Postgres and RDS

This week we covered AWS RDS and postgreSQL in our app.



## Security practice in AWS and application
 - Use VPC: Amazon RDS should always be deployed within an Amazon Virtual Private Cloud (VPC) to restrict access to authorized users and secure the network traffic.
 - Use secure connections: Use SSL/TLS to encrypt all connections between the client and the RDS database instance. This ensures that data is transmitted securely and cannot be intercepted or tampered with.
 - Use strong passwords: Always use strong passwords for database users and avoid using default passwords.
 - Restrict access to RDS instances: Limit access to RDS instances to only authorized IP addresses or subnets. Use security groups to restrict access.
 - Enable Multi-Factor Authentication (MFA): MFA adds an extra layer of security to RDS instances by requiring users to provide a second form of authentication, such as a security token, in addition to their password.
 - Regularly patch and update: Apply security patches and updates regularly to ensure that RDS instances are protected against known vulnerabilities.
 - Monitor logs: Monitor RDS instance logs regularly to detect and respond to any suspicious activity.
 - Use IAM Roles: Use IAM roles to manage permissions for AWS resources instead of using AWS access keys.

# Create RDS

To create an RDS instance for postgreSQL, the following is pasted into the terminal
```
aws rds create-db-instance \
  --db-instance-identifier cruddur-db-instance \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --engine-version  14.6 \
  --master-username root \
  --master-user-password huEE33z2Qvl383 \
  --allocated-storage 20 \
  --availability-zone eu-west-1a \
  --backup-retention-period 0 \
  --port 5432 \
  --no-multi-az \
  --db-name cruddur \
  --storage-type gp3 \
  --publicly-accessible \
  --storage-encrypted \
  --enable-performance-insights \
  --performance-insights-retention-period 7 \
  --no-deletion-protection
```
The following json was logged in the console 
![Screenshot (2178)](https://user-images.githubusercontent.com/92152669/227918477-d423a3e1-92af-4838-bdc9-a7ee4cbcd705.png)


**Common Psql commands**
```
\x on -- expanded display when looking at data
\q -- Quit PSQL
\l -- List all databases
\c database_name -- Connect to a specific database
\dt -- List all tables in the current database
\d table_name -- Describe a specific table
\du -- List all users and their roles
\dn -- List all schemas in the current database
CREATE DATABASE database_name; -- Create a new database
DROP DATABASE database_name; -- Delete a database
CREATE TABLE table_name (column1 datatype1, column2 datatype2, ...); -- Create a new table
DROP TABLE table_name; -- Delete a table
SELECT column1, column2, ... FROM table_name WHERE condition; -- Select data from a table
INSERT INTO table_name (column1, column2, ...) VALUES (value1, value2, ...); -- Insert data into a table
UPDATE table_name SET column1 = value1, column2 = value2, ... WHERE condition; -- Update data in a table
DELETE FROM table_name WHERE condition; -- Delete data from a table
```

### Creating Database and tables
Once the connection url to the postgreSQL was setup. The following line was used to create Database for Cruddur in psql.

```
CREATE database cruddur;
```

CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-seed-load"
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"

seed_path="$(realpath .)/db/seed.sql"

echo $seed_path

if [ "$1" = "prod" ]; then
  echo "Running in production mode"
  URL=$PROD_CONNECTION_URL
else
  URL=$CONNECTION_URL
fi

psql $URL cruddur < $seed_path
 ```


and on the seed.sql insert this code
```
-- this file was manually created
INSERT INTO public.users (display_name, handle, cognito_user_id)
VALUES
  ('Andrew Brown', 'andrewbrown' ,'MOCK'),
  ('Andrew Bayko', 'bayko' ,'MOCK');

INSERT INTO public.activities (user_uuid, message, expires_at)
VALUES
  (
    (SELECT uuid from public.users WHERE users.handle = 'andrewbrown' LIMIT 1),
    'This was imported as seed data!',
    current_timestamp + interval '10 day'
  )
```

# Creation connection with RDS

If you have stopped and rerun you gitpod/codespace enviroment, make sure to rerun the **db-create**, **db-schema-load** and **db-seed** in the order mention before running the db-connect. Make sure the containers are up and running first before making the connection!
There will be an instruction later how to implement the automazation once you launch the CDE enviroment without launching.

**How to see the connection**

create a file called **db-sessions** under backend-flask/bin 
```
NO_DB_CONNECTION_URL=$(sed 's/\/cruddur//g' <<<"$CONNECTION_URL")
psql $NO_DB_CONNECTION_URL -c "select pid as process_id, \
       usename as user,  \
       datname as db, \
       client_addr, \
       application_name as app,\
       state \
from pg_stat_activity;"
```

changed the permission of the file:
```
 chmod u+x ./db-sessions
```


create a file called **db-setup** under backend-flask/bin 

```
#! /usr/bin/bash

-e # stop if it fails at any point
CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-setup"
printf "${CYAN}==== ${LABEL}${NO_COLOR}\n"

bin_path="$(realpath .)/bin"

source "$bin_path/db-drop"
source "$bin_path/db-create"
source "$bin_path/db-schema-load"
source "$bin_path/db-seed"

```

changed the permission of the file:
```
 chmod u+x ./db-setup
```

## Install driver for psql

Add the following libraries into the requirements.txt of the backend flask
```
psycopg[binary]
psycopg[pool]
```

and run the for this time the following command:
```
pip install -r requirements.txt
```

create a file under lib called **db.py**. this will be the connection for your backend
```
from psycopg_pool import ConnectionPool
import os

def query_wrap_object(template):
  sql = f"""
  (SELECT COALESCE(row_to_json(object_row),'{{}}'::json) FROM (
  {template}
  ) object_row);
  """
  return sql

def query_wrap_array(template):
  sql = f"""
  (SELECT COALESCE(array_to_json(array_agg(row_to_json(array_row))),'[]'::json) FROM (
  {template}
  ) array_row);
  """
  return sql

connection_url = os.getenv("CONNECTION_URL")
pool = ConnectionPool(connection_url)
```

and insert the library on **home_activities**
```
from lib.db import pool,query_wrap_array
```

and add the following code
```
sql = """
      SELECT
        activities.uuid,
        users.display_name,
        users.handle,
        activities.message,
        activities.replies_count,
        activities.reposts_count,
        activities.likes_count,
        activities.reply_to_activity_uuid,
        activities.expires_at,
        activities.created_at
      FROM public.activities
      LEFT JOIN public.users ON users.uuid = activities.user_uuid
      ORDER BY activities.created_at DESC
      """
      print(sql)
      span.set_attribute("app.result_length", len(results))
      with pool.connection() as conn:
        with conn.cursor() as cur:
          cur.execute(sql)
          # this will return a tuple
          # the first field being the data
          json = cur.fetchall()
      return json[0]
```

from the file docker-compose change the **CONNECTIONS_URL** with the following
```
      CONNECTION_URL: "postgresql://postgres:password@db:5432/cruddur"
```

From the console active the RDS if it is in pause mode

create the PROD_CONNECTION_URL that will point to the RDS
```
postgresql://userofthedb:masterpassword@endpointofthedb:5432/cruddur
```
create the local env and on gitpod/codespace
```
export PROD_CONNECTION_URL="postgresql://userofthedb:masterpassword@endpointofthedb:5432/cruddur"
gp env PROD_CONNECTION_URL="postgresql://userofthedb:masterpassword@endpointofthedb:5432/cruddur"
```
**Note**: the password should not ending with ! as the url will be !@ and it could cause some error during the launching the command. if you experience an error "bash bla bla cruddur" you need to change the password for the DB of rds 

In order to connect to the RDS instance we need to provide our Gitpod IP and whitelist for inbound traffic on port 5432.
```
export GITPOD_IP=$(curl ifconfig.me)
```

create the env var for the security group and the security group rule
```
export DB_SG_ID="sg-sdfsdf"
gp env DB_SG_ID="sg-sdfsdf"
export DB_SG_RULE_ID="sgr-sdfsdfsdf"
gp env DB_SG_RULE_ID="sgr-sdfsdfsdf"
```

Since the ip address changes everytime, you need to change the ip on the security group of the rds instance
here is the script to add to the file **rds-update-sg-rule** under bin
```
aws ec2 modify-security-group-rules \
    --group-id $DB_SG_ID \
    --security-group-rules "SecurityGroupRuleId=$DB_SG_RULE_ID,SecurityGroupRule={Description=GITPOD,IpProtocol=tcp,FromPort=5432,ToPort=5432,CidrIpv4=$GITPOD_IP/32}"
```

on the file *gitpod.yml** add this line so it will get the ip of the instance
```
    before: |
      export GITPOD_IP=$(curl ifconfig.me)
      source  "$THEIA_WORKSPACE_ROOT/backend-flask/bin/rds-update-sg-rule"
```

# Create Lambda
Create a lambda in the region where are your services and create the same file under aws/lambdas calling the file cruddur-post-confirmation.py

```
import json
import psycopg2

def lambda_handler(event, context):
    user = event['request']['userAttributes']
    print('userAttributes')
    print(user)
    user_display_name = user['name']
    user_email        = user['email']
    user_handle       = user['preferred_username']
    user_cognito_id   = user['sub']
    try:
        conn = psycopg2.connect(os.getenv('CONNECTION_URL'))
        cur = conn.cursor()
        sql = f"""
            "INSERT INTO users (
                display_name,
                email,
                handle,
                cognito_user_id
            ) 
            VALUES(
                {user_display_name},
                {user_email},
                {user_handle},
                {user_cognito_id}
            )"
        """            
        cur.execute(sql)
        conn.commit() 

    except (Exception, psycopg2.DatabaseError) as error:
        print(error)
    finally:
        if conn is not None:
            cur.close()
            conn.close()
            print('Database connection closed.')

    return event
```

the env var for the lambda will be **CONNECTION_URL** which has the variable of the **PROD_CONNECTION_URL** set on gitpod/codespace (example: PROD_CONNECTION_URL="postgresql://userofthedb:masterpassword@endpointofthedb:5432/cruddur)

Once you create the env var, create also the layer>add layers> select specify arn
```
arn:aws:lambda:your region:898466741470:layer:psycopg2-py38:1
```

now it is time to create the trigger for cognito.
from cognito,  select the user pool and go to the user pool properties to find the lambda triggers. follow the configuration according to the image below:

![lambda triggers](https://github.com/dontworryjohn/aws-bootcamp-cruddur-2023/blob/main/images/lambda%20triggers.png)

Make sure to attach the following policy **AWSLambdaVPCAccessExecutionRole** to the lambda role by going to configuration>permission> link under the Role name.

Once attached the policy, go to VPC and select the VPC where resides the RDS,
the subnet mask (i suggest selecting just 1 as you could have timeout error during the execution of the lambda) and select the same security group of the rds. In my case i took the default vpc for my region as i deployed there, the subnetmask in my case eu-west-2a (make sure to verify where reside your rds by going to EC2>Network Interface under network & security)
and security group please make sure to insert the new inbound rule

![Security Group](https://github.com/dontworryjohn/aws-bootcamp-cruddur-2023/blob/main/images/newSG.png)

#Troubleshooting

This command see if the connection is estabilished
```
echo $CONNECTION_URL
```
