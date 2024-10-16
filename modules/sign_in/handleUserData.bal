import ballerina/log;
import ballerina/sql;
import ballerina/jwt;

public function checkIfEmailExists(string email_address, sql:Client dbClient) returns boolean|error {
    stream<record {}, sql:Error?> resultStream = dbClient->query(`SELECT 1 FROM stakeholders WHERE email_address = ${email_address}`);
    var result = check resultStream.next();

    if result is record {} {
        return true;
    }

    return false;
}

public function checkUserExists(string email, sql:Client dbClient) returns boolean {
    stream<record {}, sql:Error?> resultStream = dbClient->query(`SELECT username FROM users WHERE email = ${email}`);
    do {
        record {}? result = check resultStream.next();

        if result is record {} {
            return true;
        }
    } on fail var e {
        log:printInfo("Invalid result stream: " + e.toString());
        return false;
    }
    return false;
}

public function authenticateUser(string email, string password, sql:Client dbClient) returns boolean|sql:Error {
    stream<record {}, sql:Error?> resultStream = dbClient->query(`SELECT username FROM users WHERE email = ${email} AND password = ${password}`);

    record {}? result = check resultStream.next();
    if result is record {} {
        return true;
    }
    return false;
}

// Generate a JWT token with user claims
public isolated function generateJwtToken(string email) returns string|error {
    jwt:IssuerConfig issuerConfig = {
        username: "codeserandib",
        issuer: "codeserandib",
        audience: "users",
        expTime: 3600,
        signatureConfig: {
            config: {
                keyFile: "resources/codeserandib.key",
                keyPassword: ""
            }
        }
    };

    string jwtToken = check jwt:issue(issuerConfig);
    return jwtToken;
}
