# Week 3 — Decentralized Authentication
In this week, I covered decentralized authentication usng Amazon Cognito.

Common types of authentication include:
- Username/Password: This is the most common type of authentication, where the user enters a username and password to gain access to the app.
- SAML: (Security Assertion Markup Language) standard protocol for exchanging authentication and authorization data between parties, usually an identity provider (IdP) and a service provider (SP).
-  OpenID Connect: This is a protocol that allows for secure authentication and authorization of users across multiple systems, making it easier to manage user authentication for multiple apps.
- OAuth: This allows users to grant access to their data to third-party apps without giving them their password. Instead, the user logs in to the app with their own credentials and grants the third-party app access to their data through OAuth.

Decentralized authentication is a type of authentication where the process of verifying a user's identity is not managed by a centralized authority or organization. Instead, it is performed by a network of nodes, each of which can validate the user's identity independently.
 
 Amazon Cognito is an aws service that allows users to authenticate. The users are stored n your aws account.
 Types of Amazon Cognito include:
  - Cognito User Pool
  - Cognito Identity Pool

I configured a User pool named Cruddur-User-pool as shown below:
![Screenshot (2147)](https://user-images.githubusercontent.com/92152669/225578283-58ec056e-3019-4a6f-9348-867b6b97a5a6.png)


# Configurng Cognito in frontend

Installing AWS-amplify
``` 
npm i aws-amplyfy --save
```

The following code is added to ```app.js```.
```
import { Amplify } from 'aws-amplify';

Amplify.configure({
  "AWS_PROJECT_REGION": process.env.REACT_APP_AWS_PROJECT_REGION,
  //"aws_cognito_identity_pool_id": process.env.REACT_APP_AWS_COGNITO_IDENTITY_POOL_ID,
  "aws_cognito_region": process.env.REACT_APP_AWS_COGNITO_REGION,
  "aws_user_pools_id": process.env.REACT_APP_AWS_USER_POOLS_ID,
  "aws_user_pools_web_client_id": process.env.REACT_APP_CLIENT_ID,
  "oauth": {},
  Auth: {
    // We are not using an Identity Pool
    // identityPoolId: process.env.REACT_APP_IDENTITY_POOL_ID, // REQUIRED - Amazon Cognito Identity Pool ID
    region: process.env.REACT_APP_AWS_PROJECT_REGION,           // REQUIRED - Amazon Cognito Region
    userPoolId: process.env.REACT_APP_AWS_USER_POOLS_ID,         // OPTIONAL - Amazon Cognito User Pool ID
    userPoolWebClientId: process.env.REACT_APP_AWS_USER_POOLS_WEB_CLIENT_ID,   // OPTIONAL - Amazon Cognito Web Client ID (26-char alphanumeric string)
  }
});
```

from the **docker-compose.yml** under frontedn service add the following code
```
REACT_APP_AWS_PROJECT_REGION: "${AWS_DEFAULT_REGION}"
REACT_APP_AWS_COGNITO_REGION: "${AWS_DEFAULT_REGION}"
REACT_APP_AWS_USER_POOLS_ID: "${AWS_USER_POOLS_ID}"
REACT_APP_CLIENT_ID: "${APP_CLIENT_ID}"
```

# Showing the components based on logged in/logged out

from the **homefeedpage.js** insert the following command
```
import { Auth } from 'aws-amplify';
```
The checkAuth function was replaced with the following
```
// check if we are authenicated
const checkAuth = async () => {
  Auth.currentAuthenticatedUser({
    // Optional, By default is false. 
    // If set to true, this call will send a 
    // request to Cognito to get the latest user data
    bypassCache: false 
  })
  .then((user) => {
    console.log('user',user);
    return Auth.currentAuthenticatedUser()
  }).then((cognito_user) => {
      setUser({
        display_name: cognito_user.attributes.name,
        handle: cognito_user.attributes.preferred_username
      })
  })
  .catch((err) => console.log(err));
};

```


On profileinfo.js, add the following code

```
import { Auth } from 'aws-amplify';
```

```
const signOut = async () => {
    try {
        await Auth.signOut({ global: true });
        window.location.href = "/"
    } catch (error) {
        console.log('error signing out: ', error);
}
```

From the **signinpage.js** remove the following code

```
import { Auth } from 'aws-amplify';
```
```
const onsubmit = async (event) => {
    setErrors('')
    event.preventDefault();
    Auth.signIn(email, password)
    .then(user => {
      console.log('user',user)
      localStorage.setItem("access_token", user.signInUserSession.accessToken.jwtToken)
      window.location.href = "/"
    })
    .catch(error => {
      if (error.code == 'UserNotConfirmedException') {
        window.location.href = "/confirm"
      }
      setErrors(error.message)
      });
    return false
  }
```

From the **signuppage.js** add the following code
```
import { Auth } from 'aws-amplify';
```

```
const onsubmit = async (event) => {
    event.preventDefault();
    setErrors('')
    try {
      const { user } = await Auth.signUp({
        username: email,
        password: password,
        attributes: {
          name: name,
          email: email,
          preferred_username: username,
        },
        autoSignIn: { // optional - enables auto sign in after user is confirmed
          enabled: true,
        }
      }) ;
      console.log(user);
      window.location.href = `/confirm?email=${email}`
    } catch (error) {
        console.log(error);
        setErrors(error.message)
    }
    return false
  }
```
In the confirmationpage.js, add the following code

```
import { Auth } from 'aws-amplify';
```
``` 
const resend_code = async (event) => {
 
    setErrors('')
    try {
      await Auth.resendSignUp(email);
      console.log('code resent successfully');
      setCodeSent(true)
    } catch (err) {
      // does not return a code
      // does cognito always return english
      // for this to be an okay match?
      console.log(err)
      if (err.message == 'Username cannot be empty'){
        setCognitoErrors("You need to provide an email in order to send Resend Activiation Code")   
      } else if (err.message == "Username/client id combination not found."){
        setCognitoErrors("Email is invalid or cannot be found.")   
      }
    }
  }

```

```
const onsubmit = async (event) => {
  event.preventDefault();
  setCognitoErrors('')
  try {
    await Auth.confirmSignUp(email, code);
    window.location.href = "/"
  } catch (error) {
    setCognitoErrors(error.message)
  }
  return false
}
```
In the recoverpage.js, add the following code

 ```
import { Auth } from 'aws-amplify';
```

```
const onsubmit_send_code = async (event) => {
    event.preventDefault();
    setErrors('')
    Auth.forgotPassword(username)
    .then((data) => setFormState('confirm_code') )
    .catch((err) => setErrors(err.message) );
    return false
  }
```
```
const onsubmit_confirm_code = async (event) => {
  event.preventDefault();
  setCognitoErrors('')
  if (password == passwordAgain){
    Auth.forgotPasswordSubmit(username, code, password)
    .then((data) => setFormState('success'))
    .catch((err) => setCognitoErrors(err.message) );
  } else {
    setCognitoErrors('Passwords do not match')
  }
  return false
}


```
