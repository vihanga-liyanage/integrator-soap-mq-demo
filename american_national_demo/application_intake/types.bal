import ballerinax/rabbitmq;

# Incoming request to create a policy application.
public type ApplicationRequest record {|
    string customerId;
    string product;
|};

# Row to be written to the `applications` table.
public type ApplicationRow record {|
    string customerId;
    string applicantName;
    string product;
    int riskScore;
    string status;
|};

# Response returned to the caller after the application is stored.
public type ApplicationCreated record {|
    int applicationId;
    string customerId;
    string applicantName;
    string product;
    int riskScore;
    string status;
|};

# Error body returned when a backend call fails.
public type ErrorBody record {|
    string message;
|};

# Event published when an application has been stored.
public type ApplicationEvent record {|
    int applicationId;
    string customerId;
    string applicantName;
    string product;
    int riskScore;
|};

# RabbitMQ message carrying an ApplicationEvent.
public type ApplicationMessage record {|
    *rabbitmq:AnydataMessage;
    ApplicationEvent content;
|};
