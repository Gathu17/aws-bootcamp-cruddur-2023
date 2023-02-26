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
