# Week 1 — App Containerization
The second week of the bootcamp focused on containerzitaion. The following are the prerequisites of the week.
 - Gitpod account. This is our cloud development environment.
 - Docker. You will need to have docker installed to dockerize the application.
 - AWS CLI. The AWS CLI needs to be installed in the terminal.

### Docker

## Container Security
It is the practice of protecting your applicatrions on compute services such as a container. By using containers it reduces the impact of breach by separating the applications from other related services. Managed container services means that the security responsibility is focused on a few things. Unmanaged containers require more hours and constant monitoring of containers.

### Docker components 
There are two main components of Docker:
 - Docker client. This is where Docker has been installed and ran as a service.
 - Docker server. This is where the containers are docked.
 
### Security Best Practices
 - Host and Docker should be kept updated with the latest security patches.
 - Docker daemon and containers should run in non-root user.
 - Trusting a public and private registry. 
 - No secrets in the Docker file and images
 - Read only file system and volume in Docker.
 - Having separate databases for long term storage
 - 
To containerize our application using Docker we will need to create a Dockerfile for bothe frontend and backend. We will
also need to create a docer compose file that would be able to run both containers with a single command.
The Dockerfile for the frontend is as follows
```
FROM node:16.18

ENV PORT=3000

COPY . /frontend-react-js
WORKDIR /frontend-react-js
RUN npm install
EXPOSE ${PORT}
CMD ["npm", "start"]

```
The file can be seen [here](https://github.com/Gathu17/aws-bootcamp-cruddur-2023/blob/main/frontend-react-js/Dockerfile)

The Dockerfile for the backend is as follows

```
FROM python:3.10-slim-buster

WORKDIR /backend-flask

COPY requirements.txt requirements.txt
RUN pip3 install -r requirements.txt

COPY . .

ENV FLASK_ENV=development

EXPOSE ${PORT}
CMD [ "python3", "-m" , "flask", "run", "--host=0.0.0.0", "--port=4567"]

```
The file can be seen [here](https://github.com/Gathu17/aws-bootcamp-cruddur-2023/blob/main/backend-flask/Dockerfile)

Finally, to containerzie our whole application I created a ```docker-compose.yml``` that builds and runs both containers and also our databases that is Postgresql 
and DynamoDB.

The docker-compose file looks as follows

```
version: "3.8"
services:
  backend-flask:
    environment:
      FRONTEND_URL: "https://3000-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}"
      BACKEND_URL: "https://4567-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}"
    build: ./backend-flask
    ports:
      - "4567:4567"
    volumes:
      - ./backend-flask:/backend-flask
  frontend-react-js:
    environment:
      REACT_APP_BACKEND_URL: "https://4567-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}"
    build: ./frontend-react-js
    ports:
      - "3000:3000"
    volumes:
      - ./frontend-react-js:/frontend-react-js
  dynamodb-local:
    # https://stackoverflow.com/questions/67533058/persist-local-dynamodb-data-in-volumes-lack-permission-unable-to-open-databa
    # We needed to add user:root to get this working.
    user: root
    command: "-jar DynamoDBLocal.jar -sharedDb -dbPath ./data"
    image: "amazon/dynamodb-local:latest"
    container_name: dynamodb-local
    ports:
      - "8000:8000"
    volumes:
      - "./docker/dynamodb:/home/dynamodblocal/data"
    working_dir: /home/dynamodblocal
  db:
    image: postgres:13-alpine
    restart: always
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=password
    ports:
      - '5432:5432'
    volumes: 
      - db:/var/lib/postgresql/data
# the name flag is a hack to change the default prepend folder
# name when outputting the image names
networks: 
  internal-network:
    driver: bridge
    name: cruddur
volumes:
  db:
    driver: local
    
```
