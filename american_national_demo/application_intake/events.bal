import ballerina/log;

# Publishes an "application received" event to RabbitMQ.
#
# + event - The event to publish
# + return - An error if the broker rejects or cannot be reached
function publishApplicationReceived(ApplicationEvent event) returns error? {
    check rabbitmqClient->publishMessage({
        content: event,
        exchange: applicationsExchange,
        routingKey: applicationReceivedKey
    });
    log:printInfo("Published application.received", applicationId = event.applicationId);
}
