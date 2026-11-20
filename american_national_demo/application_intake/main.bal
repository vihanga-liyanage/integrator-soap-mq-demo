import ballerina/http;
import ballerina/otel as _;

service /applications on new http:Listener(servicePort) {

    # Creates a policy application: looks up the customer over SOAP, maps the result,
    # stores it in MySQL and publishes an event to RabbitMQ.
    resource function post .(ApplicationRequest request)
            returns http:Created|http:BadGateway|http:InternalServerError {

        ApplicationCreated|LookupError|StorageError result = createApplication(request);
        if result is LookupError {
            return <http:BadGateway>{body: {message: "Customer lookup failed"}};
        }
        if result is StorageError {
            return <http:InternalServerError>{body: {message: "Could not store the application"}};
        }
        return <http:Created>{body: result};
    }
}
