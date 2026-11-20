import ballerina/lang.value;
import ballerina/log;
import ballerinax/ibm.ibmmq;

listener ibmmq:Listener ibmmqListener = new ({
    name: mqQueueManager,
    host: mqHost,
    port: mqPort,
    channel: mqChannel,
    userID: mqUser,
    password: mqPassword
});

# Consumes application requests from IBM MQ and runs the same intake logic as the HTTP endpoint.
# This is how a flow moves off ACE one at a time while MQ stays in place.
@ibmmq:ServiceConfig {
    queueName: mqQueueName,
    pollingInterval: mqPollingInterval
}
service on ibmmqListener {

    remote function onMessage(ibmmq:Message message) returns error? {
        string text = check string:fromBytes(message.payload);
        log:printInfo("IBM MQ message received", queue = mqQueueName, body = text);

        ApplicationRequest|error request = value:fromJsonStringWithType(text);
        if request is error {
            log:printError("IBM MQ message is not a valid application request", 'error = request);
            return;
        }

        ApplicationCreated|LookupError|StorageError result = createApplication(request);
        if result is error {
            log:printError("IBM MQ application could not be processed", reason = result.message());
            return;
        }
        log:printInfo("Application created from IBM MQ", applicationId = result.applicationId,
                customerId = result.customerId);
    }
}
