import application_intake.customer;

# Looks up a customer through the SOAP service.
#
# + customerId - The customer identifier
# + return - The customer details, or an error if the call fails or the response is empty
function getCustomer(string customerId) returns customer:GetCustomerResponse|error {
    customer:GetCustomerSoapRequest request = {
        Body: {
            GetCustomer: {
                sequenceGroup: {customerId}
            }
        }
    };
    customer:GetCustomerSoapResponse response = check customerClient->getCustomer(request);
    customer:GetCustomerResponse? result = response.Body.GetCustomerResponse;
    if result is () {
        return error("SOAP response did not contain a GetCustomerResponse");
    }
    return result;
}
