# Week 2 — Distributed Tracing
In the course of the week I looked into observability, monitoring and distributed tracing. where Distributed tracing works by adding unique identifiers to requests as they enter the system. These identifiers are then propagated through all subsequent requests, allowing them to be linked together in a trace. The trace includes information about the timing and success of each step in the request, as well as any errors or exceptions encountered. I was able to work with various tools as seen below.

### Prerequisites
 - Honeycomb account
 - AWS account for AWS X-RAY.
 - Rollbar account
 - Github Codespaces. I had to switch from Gitpod after running out of credits.

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
