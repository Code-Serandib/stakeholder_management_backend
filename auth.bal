import ballerina/http;
import ballerina/oauth2;

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
    // http:Request req = new;
    // req.setHeader("Authorization", "Bearer " + accessToken);

    // Define headers to include the Authorization token
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
        // Parse the response payload
        json|error userInfo = response.getJsonPayload();
        if userInfo is json {
            if userInfo.email is string {
                return (check userInfo.email).toString();
            }
        }
    }
    return error("Failed to get email from access token");
}
