# integrator-soap-mq-demo

WSO2 Integrator demo: a policy application flows from a SOAP service into MySQL and RabbitMQ,
with retry and dead-letter handling and OpenTelemetry tracing. An IBM MQ listener is planned.

## What it shows

1. **Orchestration:** `POST /applications` calls a SOAP service (client generated from a WSDL with `bal wsdl`), maps the response, and inserts a row into MySQL.
2. **Events:** the flow publishes an `application.received` event to RabbitMQ. A second flow consumes it and calls a downstream underwriting stub.
3. **Guaranteed delivery:** if underwriting fails, the consumer retries 3 times, then nacks. The broker dead-letters the message to `application.received.dlq`.
4. **Tracing:** traces go out over OTLP/HTTP. Tested against a Dynatrace trial tenant.
5. **IBM MQ:** not built yet.

## Layout

| Path | What |
|---|---|
| `american_national_demo/application_intake/` | The WSO2 Integrator (Ballerina) package |
| `mocks/` | SOAP mock service (`soap_mock.py`, `customer.wsdl`) and underwriting stub |
| `rabbitmq/` | Broker definitions: exchange, queues, dead-letter policy |
| `mysql-init/` | Schema for the `insurance` database |
| `docker-compose.yml` | RabbitMQ, MySQL, Jaeger (optional), IBM MQ |
| `dynatrace-snippet.toml` | Tracing settings with placeholders |

## Run it

Prerequisites: Docker, Python 3, Ballerina 2201.14.x (WSO2 Integrator 5.1).

```
docker compose up -d
python3 mocks/soap_mock.py              # SOAP service on :8089
python3 mocks/underwriting_stub.py      # underwriting stub on :8090
```

Create `american_national_demo/application_intake/Config.toml` (it is gitignored):

```
dbPassword = "apppass"
dbHost = "127.0.0.1"
dbPort = 3307
rabbitmqPassword = "demo"
```

Then, from `american_national_demo/application_intake`:

```
bal run
curl -i -X POST localhost:8085/applications -H 'Content-Type: application/json' \
  -d '{"customerId":"C1001","product":"TERM_LIFE"}'
```

Known customer IDs: `C1001`, `C1002`, `C1003`. Other IDs return a generated customer.

### Break and recover underwriting

```
curl -X POST localhost:8090/admin/fail     # consumer retries, then dead-letters
curl -X POST localhost:8090/admin/ok
```

Inspect `application.received.dlq` in the RabbitMQ UI.

## Demo credentials

These protect local containers only. They are not real secrets.

| Service | Where | Login |
|---|---|---|
| RabbitMQ | localhost:5672, UI :15672 | demo / demo |
| MySQL | localhost:3307, db `insurance` | app / apppass |
| IBM MQ | localhost:1414 (QMGR `QM1`), console :9443 | app / passw0rd, admin / passw0rd |

IBM MQ runs under amd64 emulation on Apple Silicon.

## Tracing

Add this to `Config.toml` (see `dynatrace-snippet.toml`). Never commit a real token.

```
[ballerina.observe]
tracingEnabled = true
tracingProvider = "otel"

[ballerina.otel]
tracesEndpoint = "https://<environment-id>.live.dynatrace.com/api/v2/otlp/v1/traces"
tracesProtocol = "http/protobuf"
tracesExporterHeaders = "Authorization=Bearer <platform-token>"

[ballerina.otel.tracesResourceAttributes]
"service.name" = "application-intake"
```

Notes from testing:

- Use a plain space after `Bearer`. A percent-encoded `%20` is not decoded and Dynatrace answers 401, even though the exporter still logs success.
- The environment ID must not include `.apps`.
- The RabbitMQ publish and consume appear as two separate traces. Trace context is not propagated through the broker.

## Not done yet

- IBM MQ listener flow
- Kafka listener (planned as a configuration-only walkthrough)
