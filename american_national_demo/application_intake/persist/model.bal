import ballerina/persist as _;
import ballerina/time;
import ballerinax/persist.sql;

@sql:Name {value: "applications"}
public type Application record {|
    @sql:Generated
    readonly int id;
    @sql:Name {value: "customer_id"}
    @sql:Varchar {length: 32}
    string customerId;
    @sql:Name {value: "applicant_name"}
    @sql:Varchar {length: 128}
    string applicantName;
    @sql:Varchar {length: 64}
    string product;
    @sql:Name {value: "risk_score"}
    int riskScore;
    @sql:Varchar {length: 32}
    string status;
    @sql:Name {value: "created_at"}
    time:Utc createdAt;
|};

