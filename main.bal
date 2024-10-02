import ballerina/http;
import stakeholder_management_backend.risk_modeling;
import ballerina/data.jsondata;
import stakeholder_management_backend.engagement_metrics;
import ballerina/sql;
import ballerinax/java.jdbc;
import ballerinax/mysql.driver as _;
import ballerina/io;
import ballerina/log;
import ballerina/jwt;

@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:3000"],
        allowMethods: ["GET", "POST", "OPTIONS"],
        allowHeaders: ["Authorization", "Content-Type"],
        allowCredentials: true
    }
}
service /api on new http:Listener(9091) {

    final http:Client metricsAPIClient;
    final sql:Client dbClient;

    function init() returns error? {
        self.metricsAPIClient = check new("http://localhost:9090/stakeholder-analytics");
        self.dbClient = check new jdbc:Client(jdbcUrl);
        check initDatabase(self.dbClient);
    }

    //risk score
    resource function post risk_score(http:Caller caller, risk_modeling:RiskInput riskInput) returns error? {

        json|error? riskScore = risk_modeling:calculateRiskScore(self.metricsAPIClient, riskInput);

        if riskScore is json{

            json response = { "riskScore": riskScore };
            check caller->respond(response);
 
        } else {

            json response = { "error": riskScore.message()};
            check caller->respond(response);

        }
    }

    //calculate_project_risk
    resource function post project_risk(http:Caller caller, http:Request req) returns error? {
        json payload = check req.getJsonPayload();

        risk_modeling:RiskInput[] riskInputs = check jsondata:parseAsType(check payload.riskInputs);
        float[] influences = check jsondata:parseAsType(check payload.influences);

        json|error? projectRisk = risk_modeling:calculateProjectRisk(self.metricsAPIClient, riskInputs, influences);

        if projectRisk is json{

            json response = { "projectRisk": projectRisk };
            check caller->respond(response);
 
        } else {

            json response = { "error": projectRisk.message()};
            check caller->respond(response);

        }
    }

    //calculate_project_risk
    resource function post engagement_drop_alert(http:Caller caller, http:Request req) returns error? {
        json payload = check req.getJsonPayload();

        risk_modeling:RiskInput[] riskInputs = check jsondata:parseAsType(check payload.riskInputs);
        float engamenetTreshold = check payload.Te;

        json|error? engagementDropAlerts = risk_modeling:engagementDropAlert(self.metricsAPIClient, riskInputs, engamenetTreshold);

        if engagementDropAlerts is json{

            json response = { "engagementDropAlerts": engagementDropAlerts };
            check caller->respond(response);
 
        } else {

            json response = { "error": engagementDropAlerts.message()};
            check caller->respond(response);

        }
    }

    //calculate priority score
    resource function post priority_score(http:Caller caller, engagement_metrics:EPSInput epsInput) returns error? {

        json|error? Eps = engagement_metrics:calculateEps(self.metricsAPIClient, epsInput);

        if Eps is json{

            json response = { "EpsResult": Eps };
            check caller->respond(response);
 
        } else {

            json response = { "error": Eps.message()};
            check caller->respond(response);

        }
    }

    //calculate balanced score metrics
    resource function post balanced_score(http:Caller caller, engagement_metrics:BSCInput bscInput) returns error? {

        json|error? Bsc = engagement_metrics:calculateBsc(self.metricsAPIClient, bscInput);

        if Bsc is json{

            json response = { "BscResult": Bsc };
            check caller->respond(response);
 
        } else {

            json response = { "error": Bsc.message()};
            check caller->respond(response);

        }
    }

    //calculate total engament score
    resource function post engagement_score(http:Caller caller, engagement_metrics:TESInput tesInput) returns error? {

        json|error? Tsc = engagement_metrics:calculateTes(self.metricsAPIClient, tesInput);

        if Tsc is json{

            json response = { "TscResult": Tsc };
            check caller->respond(response);
 
        } else {

            json response = { "error": Tsc.message()};
            check caller->respond(response);

        }
    }

    resource function get googleLogin(http:Caller caller, http:Request req) returns error? {
        http:Response redirectResponse = new;
        redirectResponse.setHeader("Location", authorizationUrl);
        redirectResponse.statusCode = http:REDIRECT_FOUND_302;
        check caller->respond(redirectResponse);
    }

    // Callback route to handle Google OAuth2 response
    resource function get callback(http:Caller caller, http:Request req) returns error? {
        string? authCode = req.getQueryParamValue("code");
        if authCode is string {
            log:printInfo("Received authorization code: " + authCode);

            http:Request tokenRequest = new;
            tokenRequest.setHeader("Content-Type", "application/x-www-form-urlencoded");

            map<string> body = {
                "code": authCode,
                "client_id": CLIENT_ID,
                "client_secret": CLIENT_SECRET,
                "redirect_uri": REDIRECT_URI,
                "grant_type": "authorization_code"
            };

            tokenRequest.setPayload(body);

            http:Client tokenClient = check new (TOKEN_URL);
            http:Response|error tokenResponse = tokenClient->post("", tokenRequest);

            if tokenResponse is http:Response {
                json|error jsonResponse = tokenResponse.getJsonPayload();
                if jsonResponse is json {
                    string accessToken = (check jsonResponse.access_token).toString();
                    log:printInfo("Access Token: " + accessToken);

                    string email = check getEmailFromAccessToken(accessToken);
                    log:printInfo("User email: " + email);

                    if email != "" && self.checkUserExists(email) {
                        check caller->respond("User successfully authenticated!");
                    } else {
                        check caller->respond("User does not exist. Please sign up.");
                    }
                }
            }
        } else {
            check caller->respond("Authorization failed!");
        }
    }

    resource function post signup(http:Caller caller, Users users) returns error? {
        sql:ExecutionResult _ = check self.dbClient->execute(signupParameterizedQuery(users));
        check caller->respond("Sign up successful");
    }

    resource function post signIn(http:Caller caller, SignInInput signInInput) returns error? {
        boolean isAuthenticated = check self.authenticateUser(signInInput.email, signInInput.password);
        if isAuthenticated {
            string jwtToken = check self.generateJwtToken(signInInput.email);
            json responseBody = {"message": "Successfully authenticated!", "token": jwtToken};
            check caller->respond(responseBody);
        } else {
            check caller->respond("Invalid email or password!");
        }

    }

    @http:ResourceConfig {
        auth: [
            {
                jwtValidatorConfig: {
                    issuer: "codeserandib",
                    audience: "users",
                    signatureConfig: {
                        certFile: "resources/codeserandib.crt"
                    }
                }
            }
        ]
    }
    resource function get validateToken(http:Caller caller, http:Request req) returns error? {
        var token = req.getHeader("Authorization");
        if token is string {
            io:println("Received token: " + token);
        } else {
            io:println("Token is missing in the request header.");
            check caller->respond("Missing Authorization header");
        }
        check caller->respond("valid token");
    }

    function checkUserExists(string email) returns boolean {
        stream<record {}, sql:Error?> resultStream = self.dbClient->query(`SELECT username FROM users WHERE email = ${email}`);
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

    function authenticateUser(string email, string password) returns boolean|sql:Error {
        stream<record {}, sql:Error?> resultStream = self.dbClient->query(`SELECT username FROM users WHERE email = ${email} AND password = ${password}`);

        record {}? result = check resultStream.next();
        io:println("record:" + result.toString());
        if result is record {} {
            io:println("Count value: ");
            return true;
        }
        return false;
    }

    // Generate a JWT token with user claims
    isolated function generateJwtToken(string email) returns string|error {
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
}
