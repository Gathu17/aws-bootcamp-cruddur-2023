# Prelude
This was the first week of the AWS Cloud bootcamp created by Andrew Brown. In this week we focused on billing and creating architectural diagrams for the Cruddur app.The Cruddur app is a micro-blogging app built using React and Django framework. The following ar some of the prerequisites needed for the week's challenges:
 - Github account. You will require a github account where you will fork the aws-bootcamp-cruddur-2023 repo and commit changes.
 - Gitpod account. We will use this as our cloud development environment.
 - Lucidchart. This is a diagramming application that we will use to create conceptual and logical architectural diagrams.
 - AWS account. This is the most essential to have and will be our cloud platform.
 -
# Week 0 — Billing and Architecture
The following are the week's objectives that were accomplished:
 - Creating budgets and billing alerts.
 - Creating IAM user and user groups in our AWS account.
 - Creating a a napkin design and logical architectural diagram for our Cruddur app.

 ## Cloud Security
 This is cybersecurity that protects our data, applications and services that are associated with our cloud environment from both internal and external security threats. Focusing on cloud security reduces the risk of data leaks through human error and also reduces the impact of a security breach.
 
 ## Enabling MFA 
 Multi-factor authentication serves as an extra layer of protection for our AWS accounts thus mitigating the risk of a hacker gaining access to our root account. I enabled MFA for both the root account and IAM user.
 
 ### Creating IAM user and user group 
 An IAM user is a resource in IAM(Identity Access and Management) that has associated credentials and permissions. An IAM user ccan represent a person or application that uses its credentials to make AWS requests. It is advisable to use the IAM user rather that the root user since if the IAM user is compromised one can easily delete the user or limit the policy attached to the user. Policies are assigned to either an IAM user or IAM role or IAM group and consist of what the entity can/can not do.
 I created an IAM user as shown below.
 ![Screenshot 2023-02-19 184616](https://user-images.githubusercontent.com/92152669/221417170-4c789be0-b341-4400-8a92-499d2647c59c.png)
 
 ### AWS Organisation 
 When one has multiple AWS accounts it starts to become tedious to manage and keep track of all these accounts. That is where AWS Organisation comes in. It helps one to   manage policies and billings plus other services in one central management account. Your root user account will be your management account.
 The following is the organisation I created
 ![Screenshot 2023-02-19 184813](https://user-images.githubusercontent.com/92152669/221417204-965c9406-75a0-4b0b-b3d4-8592e32694a1.png)

 ## Billings, Budgets and Alarms
 There sre two ways to create a budget in AWS:
  - AWS CLI
  - AWS console

To use the AWS CLI one would have to install and verify AWS in the terminal. To install the AWS CLI you can copy
the commands from [here](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).

#### Creating a budget
The following commands creates a budget 
```
aws budgets create-budget \
--account-id=$(aws sts get-caller-identity --query Account --output text) \
--budget file://aws/json/budget.json \
--notifications-with-subscribers file://aws/json/budget-notifications-with-subscribers.json

```
The budget will appear as follows in our console
![Screenshot 2023-02-19 204205](https://user-images.githubusercontent.com/92152669/221418033-0af06aed-578f-4a08-8200-82e6b9950f5a.png)


#### Creating a subscription

The following commands will create a subscription and topic.
```
aws sns subscribe \
    --topic-arn=$(aws sns create-topic --name billing-alarm --output text) \
    --protocol email \
    --notification-endpoint=myemail@email.com
   
```
The subscription will appear as follows
![Screenshot 2023-02-19 205452](https://user-images.githubusercontent.com/92152669/221418063-258570e1-b37a-4df0-9e08-ef576a6c84e0.png)



