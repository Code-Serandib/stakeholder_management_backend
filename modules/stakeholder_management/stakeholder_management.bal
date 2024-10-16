import ballerina/http;
import ballerina/sql;
import stakeholder_management_backend.sign_in;
public function getTotalStakeholdersCount(sql:Client dbClient) returns int|error {
    sql:ParameterizedQuery query = `
        SELECT COUNT(DISTINCT stakeholder_id) AS total_count
        FROM meeting_stakeholders
    `;

    record {|int total_count;|}|sql:Error result = dbClient->queryRow(query);

    if result is record {|int total_count;|} {
        return result.total_count;
    } else {
        return error("Failed to retrieve total stakeholders count");
    }
}

public function getRegisterStakeholder(http:Caller caller, http:Request req, sql:Client dbClient) returns error? {
        json payload = check req.getJsonPayload();
        Stakeholder stakeholder = check payload.cloneWithType(Stakeholder);

        boolean emailExists = check sign_in:checkIfEmailExists(stakeholder.email_address, dbClient);

        if (emailExists) {
            check caller->respond({
                statusCode: 409,
                message: "Email already exists. Please use a different email address."
            });
            return;

        }

        sql:ExecutionResult _ = check dbClient->execute(stakeholderRegisterParameterizedQuery(stakeholder));
        check caller->respond({message: "Stakeholder registered successfully"});
    }
