import application_intake.customer;

import ballerina/log;
import ballerina/sql;

# The SOAP customer lookup failed.
public type LookupError distinct error;

# The application could not be stored in the database.
public type StorageError distinct error;

# Shared intake logic used by the HTTP endpoint and the IBM MQ listener:
# SOAP lookup, transform, insert into MySQL, publish the event to RabbitMQ.
#
# + request - The incoming application request
# + return - The stored application, or an error describing which step failed
function createApplication(ApplicationRequest request) returns ApplicationCreated|LookupError|StorageError {

    // 1. Customer lookup over SOAP
    customer:GetCustomerResponse|error customerInfo = getCustomer(request.customerId);
    if customerInfo is error {
        log:printError("Customer lookup failed", 'error = customerInfo, customerId = request.customerId);
        return error LookupError("Customer lookup failed", customerInfo);
    }

    // 2. Transform to a database row
    ApplicationRow row = mapToApplicationRow(customerInfo, request);

    // 3. Store the application
    sql:ExecutionResult|error stored = dbClient->execute(`
        INSERT INTO applications (customer_id, applicant_name, product, risk_score, status)
        VALUES (${row.customerId}, ${row.applicantName}, ${row.product}, ${row.riskScore}, ${row.status})`);
    if stored is error {
        log:printError("Database insert failed", 'error = stored);
        return error StorageError("Could not store the application", stored);
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

    return {
        applicationId,
        customerId: row.customerId,
        applicantName: row.applicantName,
        product: row.product,
        riskScore: row.riskScore,
        status: row.status
    };
}
