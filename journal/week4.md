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

I created bash scripts for creating and dropping databases, connecting to databases and creating users and activities as can be evidenced [here](https://github.com/Gathu17/aws-bootcamp-cruddur-2023/tree/main/backend-flask/bin)

Note: Be sure to add permissions using the following command
```
chmod +x ./bin/<script>
```
I also created the bash script to modify the RDS security group with the following aws command
```
aws ec2 modify-security-group-rules \
    --group-id $DB_SG_ID \
    --security-group-rules "SecurityGroupRuleId=$DB_SG_RULE,SecurityGroupRule={Description=GITPOD,IpProtocol=tcp,FromPort=5432,ToPort=5432,CidrIpv4=$(curl ifconfig.me)/32}"
```
![Screenshot (2179)](https://user-images.githubusercontent.com/92152669/228193072-c91a6fb5-b609-41f8-9768-6dd1ae5853a6.png)

Remember to set the DB_SG_RULE and DB_SG_ID vars in the codespace.
The command to run the script was added to the devcontainer.json that is initiated when starting the codespace.

# Create Lambda function
In the AWS Lambda, a function was created with the code present [here](https://github.com/Gathu17/aws-bootcamp-cruddur-2023/blob/main/aws/lambdas/cruddur-post-confirmation.py)
When creating lambda function . I ran into an issue on permissions to create function. This can be solved by going to policies and adding a policy for **AWSLambdaBasicExecution**. This policy was used in a created rle for the lambda function. You will also need to add policy for **AWSLambdaVPCExecution**


the env var for the lambda will be **CONNECTION_URL** which has the variable of the **PROD_CONNECTION_URL** set in our codespace earlier.

You will also need to create a layer for psycopg2 used in our lambda function. The zip file created can be found [here](https://github.com/Gathu17/aws-bootcamp-cruddur-2023/tree/main/aws/aws-psycopg2)
The VPC was also added for our security group.

Once the Lambda function was setup correctly, cloudwatch logs should display the following when user signs up. PS: Confirm from the cognito user pool that the user isn't already added 
![Screenshot (2180)](https://user-images.githubusercontent.com/92152669/228197927-9edf8e05-cada-4ca2-88bf-a7877155d977.png)

To confirm the user has been added, you will connect to the database using ```./bin/connect prod ``` that connects to our production database. By running  ```SELECT * FROM users```, the user should be seen in the user table as shown.
![Screenshot (2181)](https://user-images.githubusercontent.com/92152669/228200485-2a92e90c-bec0-484d-97c1-c4e4bfe2020f.png)

### Create activity.
The next step was to add activities to our ```public.activities``` table.
In the create_activity.py file, the functions to create activity and query object was modifed. The db.py was also refractored as shown [here](https://github.com/Gathu17/aws-bootcamp-cruddur-2023/blob/main/backend-flask/lib/db.py)

Once an activity is created in our cruddur app, it should display in our database as shown below
![Screenshot (2182)](https://user-images.githubusercontent.com/92152669/228203887-7a11ab05-321d-481e-8f7d-203397e4ac2c.png)





