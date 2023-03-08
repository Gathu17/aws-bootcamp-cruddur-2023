# Week 2 — Distributed Tracing
In the course of the week I looked into observability, monitoring and distributed tracing. where Distributed tracing works by adding unique identifiers to requests as they enter the system. These identifiers are then propagated through all subsequent requests, allowing them to be linked together in a trace. The trace includes information about the timing and success of each step in the request, as well as any errors or exceptions encountered. I was able to work with various tools as seen below.

### Prerequisites
 - Honeycomb account
 - AWS account for AWS X-RAY.
 - Rollbar account
 - Github Codespaces. I had to switch from Gitpod after running out of credits.

## Observability and monitoring
Software observability is the practice of monitoring, measuring, and understanding the behavior and performance of software systems. Software monitoring is the practice of tracking and measuring the performance and behavior of software systems over time.

###### Pillars of Observability
 - Metrics
 - Traces
 - Logs
 
Why Observability?
 - Decreased alert fatigue for Security Operation teams
 - Visibility of end2end of Logs, metrics and tracing
 - Troubleshoot and resolve things quickly
 - Understand application health
 - Accelerate collaboration between teams.
 - Reduce overall operation cost
##### Central Observability Platform
 - AWS Security hub  with Amazon EventBridge
 - SIEM (Security Incident and Event Management)
 - Open Source Dashboards
 - Event Driven Architecture with AWS services


### Honeycomb
This was used in conjunction with opentelemetry. OpenTelemetry is an open-source project that provides a set of tools, APIs, and SDKs for distributed tracing, metrics collection, and logging in modern applications.

Add dependencies to backend-flask and installing them
```
opentelemetry-api 
opentelemetry-sdk 
opentelemetry-exporter-otlp-proto-http 
opentelemetry-instrumentation-flask 
opentelemetry-instrumentation-requests

```
Add the following to app.py
```
# Honeycomb
from opentelemetry import trace
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

# Honeycomb
# Initialize tracing and an exporter that can send data to Honeycomb
provider = TracerProvider()
processor = BatchSpanProcessor(OTLPSpanExporter())
provider.add_span_processor(processor)
trace.set_tracer_provider(provider)
tracer = trace.get_tracer(__name__)

# Honeycomb
# Initialize automatic instrumentation with Flask
FlaskInstrumentor().instrument_app(app)
RequestsInstrumentor().instrument()

```
Add the env vars to ```docker-compose.yml```
```
OTEL_SERVICE_NAME: 'cruddur'
OTEL_EXPORTER_OTLP_ENDPOINT: "https://api.honeycomb.io"
OTEL_EXPORTER_OTLP_HEADERS: "x-honeycomb-team=${HONEYCOMB_API_KEY}"

```
After running docker-compose the following dataset would be seen in your HoneyComb console
![Screenshot (2129)](https://user-images.githubusercontent.com/92152669/223391995-332a1b4c-044e-4f34-ab14-22799fc723c1.png)

The API key can be found in your environment from your honeycomb account.
To create a span and attribute. The following code will be added to your services module.
```
from opentelemetry import trace
tracer = trace.get_tracer("home-activities")

with tracer.start_as_current_span("home-activities-mock-data"):
    span = trace.get_current_span()
    
span.set_attribute("app.now", now.isoformat())

```
and at the end of the code
```
span.set_attribute("app.result_lenghth", len(return_data))

```
Below are the spans I created
![Screenshot (2130)](https://user-images.githubusercontent.com/92152669/223392650-b23a14c3-fc0b-4757-9b54-8f01ae7cc84c.png)

## X-Ray
#### Installing
Add the ``` aws-xray-sdk``` in requirements.txt file of backend and install.
The image for x-ray daemon was added to the docker-compose.yml file
```
xray-daemon:
    image: "amazon/aws-xray-daemon"
    environment:
      AWS_ACCESS_KEY_ID: "${AWS_ACCESS_KEY_ID}"
      AWS_SECRET_ACCESS_KEY: "${AWS_SECRET_ACCESS_KEY}"
      AWS_REGION: "us-east-1"
    command:
      - "xray -o -b xray-daemon:2000"
    ports:
      - 2000:2000/udp
      
```
and the following env vars were inserted in the backend service
```
AWS_XRAY_URL: "*4567-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}*"
AWS_XRAY_DAEMON_ADDRESS: "xray-daemon:2000"

```

The following code was inserted in ```app.py```
```
# Xray
from aws_xray_sdk.core import xray_recorder
from aws_xray_sdk.ext.flask.middleware import XRayMiddleware

xray_url = os.getenv("AWS_XRAY_URL")
xray_recorder.configure(service='backend-flask', dynamic_naming=xray_url)

```
I started a subsegment in the notifications_activities.py module as shown
```
from aws_xray_sdk.core import xray_recorder

    # Start a subsegment
    subsegment = xray_recorder.begin_segment('notification_activities')
    #x-ray
    dict = {
      "now": now.isoformat(),
      "result_size": len(results)
    }
    subsegment.put_metadata('key', dict, 'namespace')
    
```
It appeared as folows in AWS console
![Screenshot (2136)](https://user-images.githubusercontent.com/92152669/223483259-db44d874-0f55-4df9-9067-15df294ecb8e.png)
![Screenshot (2137)](https://user-images.githubusercontent.com/92152669/223483573-f9b58a36-6267-4a5c-a41b-fd3c4951bc1a.png)

## Cloudwatch
Amazon Cloudwatch allows us to collect and visualize real time data. I configured logger in Python to use Cloudwatch.

#### Installation
Add the following to requirements.txt and install
```
watchtower

```
In ```app.py``` the following code was added
```
import watchtower
import logging
from time import strftime

# Configuring Logger to Use CloudWatch
LOGGER = logging.getLogger(__name__)
LOGGER.setLevel(logging.DEBUG)
console_handler = logging.StreamHandler()
cw_handler = watchtower.CloudWatchLogHandler(log_group='cruddur')
LOGGER.addHandler(console_handler)
LOGGER.addHandler(cw_handler)
LOGGER.info("some message")

@app.after_request
def after_request(response):
    timestamp = strftime('[%Y-%b-%d %H:%M]')
    LOGGER.error('%s %s %s %s %s %s', timestamp, request.remote_addr, request.method, request.scheme, request.full_path, response.status)
    return response
    
```
The following was logged from one of the API endpoints
```
LOGGER.info('Hello Cloudwatch!')

```
Also ensure the AWS env vars have been added to docker-compose. i.e
```
      AWS_DEFAULT_REGION: "${AWS_DEFAULT_REGION}"
      AWS_ACCESS_KEY_ID: "${AWS_ACCESS_KEY_ID}"
      AWS_SECRET_ACCESS_KEY: "${AWS_SECRET_ACCESS_KEY}"
      
```
The logs were observed in the AWS console
![Screenshot (2138)](https://user-images.githubusercontent.com/92152669/223592618-d0159fb7-19c9-4fdd-a84f-4b2ede9549aa.png)

## Rollbar
To install, add the following dependencies to requirements.txt
```
blinker
rollbar

```
I exported the rollbar access token and added to github secrets as I was using Gitthub Codespace
```
export ROLLBAR_ACCESS_TOKEN=""

```
The variable was also added to docker-compose
```
ROLLBAR_ACCESS_TOKEN: "${ROLLBAR_ACCESS_TOKEN}"
```

In ```app.py``` the following was added
```
import rollbar
import rollbar.contrib.flask
from flask import got_request_exception

```
```
rollbar_access_token = os.getenv('ROLLBAR_ACCESS_TOKEN')
@app.before_first_request
def init_rollbar():
    """init rollbar module"""
    rollbar.init(
        # access token
        rollbar_access_token,
        # environment name
        'production',
        # server root directory, makes tracebacks prettier
        root=os.path.dirname(os.path.realpath(__file__)),
        # flask already sets up logging
        allow_logging_basic_config=False)

    # send exceptions from `app` to rollbar, using flask's signal system.
    got_request_exception.connect(rollbar.contrib.flask.report_exception, app)
    
```
```
@app.route('/rollbar/test')
def rollbar_test():
    rollbar.report_message('Hello World!', 'warning')
    return "Hello World!"
    
```
The following was observed in Rollbar
![Screenshot (2139)](https://user-images.githubusercontent.com/92152669/223596301-575f2138-a7cc-45fa-9204-88c769fb0337.png)
![Screenshot (2140)](https://user-images.githubusercontent.com/92152669/223597670-9b7799d4-0b73-4f30-a385-b47027e3802a.png)







