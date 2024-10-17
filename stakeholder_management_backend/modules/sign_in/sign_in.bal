import ballerina/http;
import ballerina/sql;
import ballerina/io;
public function getSignIn(http:Caller caller, SignInInput signInInput, sql:Client dbClient) returns error? {
    boolean isAuthenticated = check authenticateUser(signInInput.email, signInInput.password, dbClient);
    if isAuthenticated {
        string jwtToken = check generateJwtToken(signInInput.email);
        json responseBody = {"message": "Successfully authenticated!", "token": jwtToken};
        check caller->respond(responseBody);
    } else {
        check caller->respond("Invalid email or password!");
    }
}

public function getUserDetails(string? email, sql:Client dbClient) returns Users|error {
        if email is string {
            io:println("Received email: " + email.toBalString());
            stream<record {}, sql:Error?> resultStream = dbClient->query(getUserData(email));
            io:println("Received dsta: " + resultStream.toBalString());

            check from record {} users in resultStream
                do {
                    io:println("Student name: ", users);
                    Users user = {
                        organizationName: users["organizationName"].toString(),
                        organizationType: users["organizationType"].toString(),
                        industry: users["industry"].toString(),
                        address: users["address"].toString(),
                        country: users["country"].toString(),
                        administratorName: users["administratorName"].toString(),
                        email: users["email"].toString(),
                        contactNumber: users["contactNumber"].toString(),
                        role: users["role"].toString(),
                        username: users["username"].toString(),
                        password: users["password"].toString()
                    };
                    return user;
                };
        }
        return error("User does not exist with this email.");
    }

