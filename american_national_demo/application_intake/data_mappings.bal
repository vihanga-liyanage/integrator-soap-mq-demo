import application_intake.customer;

# Maps the SOAP customer response plus the incoming request to a database row.
function mapToApplicationRow(customer:GetCustomerResponse customerInfo, ApplicationRequest request) returns ApplicationRow => {
    customerId: customerInfo.sequenceGroup1.customerId,
    applicantName: customerInfo.sequenceGroup1.fullName,
    product: request.product,
    riskScore: customerInfo.sequenceGroup1.riskScore,
    status: "RECEIVED"
};
