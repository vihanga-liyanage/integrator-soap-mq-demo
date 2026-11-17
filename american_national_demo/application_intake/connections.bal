import ballerina/http;
import application_intake.customer;

import ballerinax/mysql;
import ballerinax/mysql.driver as _;
import ballerinax/rabbitmq;

# SOAP client generated from customer.wsdl (SOAP 1.2 port).
final customer:Client customerClient = check new (customerServiceUrl);

# MySQL client for the `insurance` database.
final mysql:Client dbClient = check new (dbHost, dbUser, dbPassword, dbName, dbPort);

# RabbitMQ publisher.
final rabbitmq:Client rabbitmqClient = check new (rabbitmqHost, rabbitmqPort,
    auth = {username: rabbitmqUser, password: rabbitmqPassword});

# Downstream underwriting service.
final http:Client underwritingClient = check new (underwritingUrl);
