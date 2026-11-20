import ballerina/http;
import ballerina/lang.runtime;
import ballerina/log;
import ballerina/observe;
import ballerinax/rabbitmq;

listener rabbitmq:Listener rabbitmqListener = new (rabbitmqHost, rabbitmqPort,
    auth = {username: rabbitmqUser, password: rabbitmqPassword});

# Consumes application events and sends them to underwriting.
# Retries a few times, then rejects the message (requeue=false) so the broker moves it to the
# dead-letter queue (policy `application-received-dlx`).
@rabbitmq:ServiceConfig {
    queueName: applicationReceivedQueue,
    autoAck: false
}
service rabbitmq:Service on rabbitmqListener {

    remote function onMessage(ApplicationMessage message, rabbitmq:Caller caller) returns error? {
        ApplicationEvent event = message.content;
        error? lastError = ();

        foreach int attempt in 1 ... maxAttempts {
            error? result = sendToUnderwriting(event);
            if result is () {
                check caller->basicAck();
                log:printInfo("Underwriting accepted", applicationId = event.applicationId, attempt = attempt);
                return;
            }
            lastError = result;
            log:printWarn("Underwriting call failed", applicationId = event.applicationId,
                    attempt = attempt, maxAttempts = maxAttempts, reason = result.message());
            if attempt < maxAttempts {
                runtime:sleep(retryIntervalSeconds);
            }
        }

        log:printError("Giving up, sending to dead-letter queue", applicationId = event.applicationId,
                reason = lastError is error ? lastError.message() : "unknown");
        // Experiment: tag the active span as failed so tracing backends can flag the request.
        error? tagged = observe:addTagToSpan("error", "true");
        if tagged is error {
            log:printWarn("Could not tag span as error", reason = tagged.message());
        }
        check caller->basicNack(requeue = false);
    }
}

function sendToUnderwriting(ApplicationEvent event) returns error? {
    http:Response response = check underwritingClient->post("/underwriting", event);
    if response.statusCode != http:STATUS_OK {
        return error(string `underwriting returned ${response.statusCode}`);
    }
}
