import ballerina/http;
import ballerina/oauth2;
import ballerina/sql;

// OAuth2 client configuration for Google
oauth2:ClientCredentialsGrantConfig oauthConfig = {
    clientId: CLIENT_ID,
    clientSecret: CLIENT_SECRET,
    tokenUrl: TOKEN_URL,
    scopes: [SCOPE]
};

string authorizationUrl = string `${AUTH_URL}?client_id=${CLIENT_ID}&redirect_uri=${REDIRECT_URI}&response_type=code&scope=${SCOPE}&access_type=offline&prompt=consent`;

function signupParameterizedQuery(Users users) returns sql:ParameterizedQuery {
    string organizationName = users.organizationName ?: "";
    string organizationType = users.organizationType ?: "";
    string industry = users.industry ?: "";
    string address = users.address;
    string country = users.country;
    string administratorName = users.administratorName;
    string email = users.email;
    string contactNumber = users.contactNumber ?: "";
    string role = users.role ?: "";
    string username = users.username;
    string password = users.password;

    sql:ParameterizedQuery query = `INSERT INTO users 
        (organizationName, organizationType, industry, address, country, administratorName, email, contactNumber, role, username, password) VALUES 
        (${organizationName}, ${organizationType}, ${industry}, ${address}, ${country}, ${administratorName}, ${email}, ${contactNumber}, ${role}, ${username}, ${password})`;
    return query;
};

// Utility function to get email from Google access token
function getEmailFromAccessToken(string accessToken) returns string|error {
    http:Client googleClient = check new ("https://www.googleapis.com");
    http:Request req = new;
    req.setHeader("Authorization", "Bearer " + accessToken);

    // Set the Authorization header directly in the GET request
    map<string|string[]> headers = {
        "Authorization": "Bearer " + accessToken
    };

    // Send a GET request to the user info endpoint
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
