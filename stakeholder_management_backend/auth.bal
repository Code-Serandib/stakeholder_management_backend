import ballerina/http;
import ballerina/oauth2;
import ballerina/log;
import ballerina/sql;
import ballerina/uuid;
import stakeholder_management_backend.sign_in;

// OAuth2 Configuration
configurable string CLIENT_ID = ?;
configurable string CLIENT_SECRET = ?;
configurable string REDIRECT_URI = "http://localhost:3000/sign-in";
configurable string TOKEN_URL = "https://oauth2.googleapis.com/token";
configurable string AUTH_URL = "https://accounts.google.com/o/oauth2/auth";
configurable string SCOPE = "https://www.googleapis.com/auth/userinfo.profile https://www.googleapis.com/auth/userinfo.email";

configurable string DB_URL = ?;
configurable string DB_USERNAME = ?;
configurable string DB_PASSWORD = ?;

configurable string SMTP_EMAIL = ?;
configurable string SMTP_USERNAME = ?;
configurable string SMTP_PASSWORD = ?;

// OAuth2 client configuration for Google
oauth2:ClientCredentialsGrantConfig oauthConfig = {
    clientId: CLIENT_ID,
    clientSecret: CLIENT_SECRET,
    tokenUrl: TOKEN_URL,
    scopes: [SCOPE]
};

string authorizationUrl = string `${AUTH_URL}?client_id=${CLIENT_ID}&redirect_uri=${REDIRECT_URI}&response_type=code&scope=${SCOPE}&access_type=offline&prompt=consent`;

// Function to get user info from Google using access token
function getUserInfo(string accessToken) returns json|error {
    http:Client googleClient = check new ("https://www.googleapis.com");

    map<string> headers = {"Authorization": "Bearer " + accessToken};

    http:Response|error response = googleClient->get("/oauth2/v2/userinfo", headers);
    
    if response is http:Response {
        json|error userInfo = response.getJsonPayload();
        if userInfo is json {
            return userInfo;
        }
    }
    return error("Failed to get user information");
}

// Utility function to get email from Google access token
function getEmailFromAccessToken(string accessToken) returns string|error {
    http:Client googleClient = check new ("https://www.googleapis.com");
    http:Request req = new;
    req.setHeader("Authorization", "Bearer " + accessToken);

    map<string|string[]> headers = {
        "Authorization": "Bearer " + accessToken
    };

    http:Response|error response = googleClient->get("/oauth2/v2/userinfo", headers);
    if response is http:Response {
        json|error userInfo = response.getJsonPayload();
        if userInfo is json {
            if userInfo.email is string {
                return (check userInfo.email).toString();
            }
        }
    }
    return error("Failed to get email from access token");
}

public function getGoogleAuthValidation(
    string? authCode,
    http:Caller caller,
    // function (string) returns boolean checkUserExists,
    sql:Client dbClient
) returns error? {
    if authCode is string {
        log:printInfo("Received authorization code: " + authCode);

        string requestBody = "code=" + authCode + "&client_id=" + CLIENT_ID +
                        "&client_secret=" + CLIENT_SECRET + "&redirect_uri=" + REDIRECT_URI +
                        "&grant_type=authorization_code";

        http:Request tokenRequest = new;
        tokenRequest.setHeader("Content-Type", "application/x-www-form-urlencoded");
        tokenRequest.setPayload(requestBody);

        http:Client tokenClient = check new (TOKEN_URL);
        http:Response|error tokenResponse = tokenClient->post("", tokenRequest);

        if tokenResponse is http:Response {
            json|error jsonResponse = tokenResponse.getJsonPayload();
            if jsonResponse is json {

                if jsonResponse.access_token is string && jsonResponse.refresh_token is string {
                    string accessToken = (check jsonResponse.access_token).toString();
                    string refreshToken = (check jsonResponse.refresh_token).toString();

                    json userInfo = check getUserInfo(accessToken);

                    string email = (check userInfo.email).toString();
                    log:printInfo("User email: " + email);
                    log:printInfo("userInfo: " + userInfo.toBalString());

                    // Use the passed checkUserExists function to verify if the user exists
                    if email != "" && !sign_in:checkUserExists(email, dbClient) {
                        string userName = (check userInfo.name).toString();
                        string password = uuid:createType1AsString();

                        sql:ParameterizedQuery query = `INSERT INTO users 
                        (administratorName, email, username, password) VALUES 
                        (${userName}, ${email}, ${userName}, ${password})`;

                        sql:ExecutionResult _ = check dbClient->execute(query);
                        log:printInfo("New user registered: " + email);

                        json response = {
                            status: "User successfully registered!",
                            user_email: email,
                            access_token: accessToken,
                            refresh_token: refreshToken
                        };
                        check caller->respond(response);
                    } else {
                        json response = {
                            status: "User already exists!",
                            user_email: email,
                            access_token: accessToken,
                            refresh_token: refreshToken
                        };
                        check caller->respond(response);
                    }
                } else {
                    check caller->respond("Failed to retrieve access token from Google.");
                }

            }
        }
    } else {
        check caller->respond("Authorization failed!");
    }
}

public function getRefreshToken(http:Caller caller, http:Request req) returns error? {
        json|error reqPayload = req.getJsonPayload();
        if reqPayload is json {
            string? refreshToken = (check reqPayload.refresh_token).toString();
            if refreshToken is string {
                log:printInfo("Received refresh token: " + refreshToken);

                string requestBody = "client_id=" + CLIENT_ID +
                            "&client_secret=" + CLIENT_SECRET +
                            "&refresh_token=" + refreshToken +
                            "&grant_type=refresh_token";

                http:Request tokenRequest = new;
                tokenRequest.setHeader("Content-Type", "application/x-www-form-urlencoded");
                tokenRequest.setPayload(requestBody);

                http:Client tokenClient = check new (TOKEN_URL);
                http:Response|error tokenResponse = tokenClient->post("", tokenRequest);

                if tokenResponse is http:Response {
                    json|error jsonResponse = tokenResponse.getJsonPayload();
                    if jsonResponse is json {
                        if jsonResponse.access_token is string {
                            string newAccessToken = (check jsonResponse.access_token).toString();
                            log:printInfo("New access token received: " + newAccessToken);

                            json response = {
                                status: "Token refreshed successfully",
                                access_token: newAccessToken
                            };
                            check caller->respond(response);
                        } else {
                            check caller->respond("Failed to retrieve new access token.");
                        }
                    } else {
                        check caller->respond("Failed to parse response from token server.");
                    }
                } else {
                    check caller->respond("Failed to request new access token from server.");
                }
            } else {
                check caller->respond("Refresh token is missing.");
            }
        } else {
            check caller->respond("Invalid request payload.");
        }
    }

    public function getUserDataFromAccessToken(http:Caller caller, http:Request req, sql:Client dbClient) returns error? {
        json|error reqPayload = req.getJsonPayload();
        if reqPayload is json {
            string? accessToken = (check reqPayload.accessToken).toString();
            if accessToken is string {
                json userInfo = check getUserInfo(accessToken);

                string email = (check userInfo.email).toString();
                string profilePicture = (check userInfo.picture).toString();

                stream<record {}, sql:Error?> resultStream = dbClient->query(sign_in:getUserData(email));

                check from record {} users in resultStream
                    do {
                        sign_in:Users user = {
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
                        json response = {
                            user: user,
                            user_email: email,
                            profilePicture: profilePicture
                        };
                        check caller->respond(response);
                    };
            }
        }
    }

    public function getValidateToken(http:Caller caller, http:Request req) returns error? {
        var token = req.getHeader("Authorization");
        if token !is string {
            check caller->respond("Missing Authorization header");
        }
        check caller->respond("valid token");
    }

