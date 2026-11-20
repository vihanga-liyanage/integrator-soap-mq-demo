# HTTP port for the applications API.
configurable int servicePort = 8085;

# SOAP customer service endpoint (mock from mocks/soap_mock.py).
configurable string customerServiceUrl = "http://localhost:8089/customer";

# MySQL connection settings (docker-compose service `mysql`).
configurable string dbHost = "localhost";
configurable int dbPort = 3306;
configurable string dbName = "insurance";
configurable string dbUser = "app";
configurable string dbPassword = ?;

# RabbitMQ broker settings (docker-compose service `rabbitmq`).
configurable string rabbitmqHost = "127.0.0.1";
configurable int rabbitmqPort = 5672;
configurable string rabbitmqUser = "demo";
configurable string rabbitmqPassword = ?;

# Exchange / routing key / queue pre-created by rabbitmq/definitions.json.
configurable string applicationsExchange = "applications.exchange";
configurable string applicationReceivedKey = "application.received";
configurable string applicationReceivedQueue = "application.received";

# Downstream underwriting stub (mocks/underwriting_stub.py).
configurable string underwritingUrl = "http://localhost:8090";

# Delivery attempts before the message is rejected to the dead-letter queue.
configurable int maxAttempts = 3;
configurable decimal retryIntervalSeconds = 2;

# IBM MQ queue manager settings (docker-compose service `ibmmq`).
configurable string mqQueueManager = "QM1";
configurable string mqHost = "127.0.0.1";
configurable int mqPort = 1414;
configurable string mqChannel = "DEV.APP.SVRCONN";
configurable string mqUser = "app";
configurable string mqPassword = ?;
configurable string mqQueueName = "DEV.QUEUE.1";
configurable decimal mqPollingInterval = 2.0;
