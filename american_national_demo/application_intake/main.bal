import application_intake.customer;

import ballerina/http;
import ballerina/otel as _;
import ballerina/log;
import ballerina/sql;

service /applications on new http:Listener(servicePort) {

    # Creates a policy application: looks up the customer over SOAP, maps the result
    # and stores it in MySQL.
    resource function post .(ApplicationRequest request)
            returns http:Created|http:BadGateway|http:InternalServerError {

        // 1. Customer lookup over SOAP
        customer:GetCustomerResponse|error customerInfo = getCustomer(request.customerId);
        if customerInfo is error {
            log:printError("Customer lookup failed", 'error = customerInfo, customerId = request.customerId);
            return <http:BadGateway>{body: {message: "Customer lookup failed"}};
        }

        // 2. Transform to a database row
        ApplicationRow row = mapToApplicationRow(customerInfo, request);

        // 3. Store the application
        sql:ExecutionResult|error stored = dbClient->execute(`
            INSERT INTO applications (customer_id, applicant_name, product, risk_score, status)
            VALUES (${row.customerId}, ${row.applicantName}, ${row.product}, ${row.riskScore}, ${row.status})`);
        if stored is error {
            log:printError("Database insert failed", 'error = stored);
            return <http:InternalServerError>{body: {message: "Could not store the application"}};
        }

        string|int? generatedId = stored.lastInsertId;
        int applicationId = generatedId is int ? generatedId : 0;
        log:printInfo("Application stored", applicationId = applicationId, customerId = row.customerId);

        // 4. Publish the event for downstream processing
        ApplicationEvent event = {
            applicationId,
            customerId: row.customerId,
            applicantName: row.applicantName,
            product: row.product,
            riskScore: row.riskScore
        };
        error? published = publishApplicationReceived(event);
        if published is error {
            log:printError("Could not publish application event", 'error = published);
        }

        ApplicationCreated created = {
            applicationId,
            customerId: row.customerId,
            applicantName: row.applicantName,
            product: row.product,
            riskScore: row.riskScore,
            status: row.status
        };
        return <http:Created>{body: created};
    }
}
