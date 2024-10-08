import stakeholder_management_backend.engagement_metrics;
import stakeholder_management_backend.risk_modeling;
import ballerina/data.jsondata;
import stakeholder_management_backend.theoretical_depth;
import ballerina/http;
import ballerina/io;
import ballerina/jwt;
import ballerina/log;
import ballerina/sql;
import ballerinax/java.jdbc;
import ballerinax/mysql.driver as _;

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
        self.metricsAPIClient = check new ("http://localhost:9090/stakeholder-analytics");
        self.dbClient = check new jdbc:Client(jdbcUrl);
        check initDatabase(self.dbClient);
    }

    //risk score
    resource function post risk_score(http:Caller caller, risk_modeling:RiskInput riskInput) returns error? {

        json|error? riskScore = risk_modeling:calculateRiskScore(self.metricsAPIClient, riskInput);

        if riskScore is json {

            json response = {"riskScore": riskScore};
            check caller->respond(response);

        } else {

            json response = {"error": riskScore.message()};
            check caller->respond(response);

        }
    }

    //calculate_project_risk
    resource function post project_risk(http:Caller caller, http:Request req) returns error? {
        json payload = check req.getJsonPayload();

        risk_modeling:RiskInput[] riskInputs = check jsondata:parseAsType(check payload.riskInputs);
        float[] influences = check jsondata:parseAsType(check payload.influences);

        json|error? projectRisk = risk_modeling:calculateProjectRisk(self.metricsAPIClient, riskInputs, influences);

        if projectRisk is json {

            json response = {"projectRisk": projectRisk};
            check caller->respond(response);

        } else {

            json response = {"error": projectRisk.message()};
            check caller->respond(response);

        }
    }

    //calculate_project_risk
    resource function post engagement_drop_alert(http:Caller caller, http:Request req) returns error? {
        json payload = check req.getJsonPayload();

        risk_modeling:RiskInput[] riskInputs = check jsondata:parseAsType(check payload.riskInputs);
        float engamenetTreshold = check payload.Te;

        json|error? engagementDropAlerts = risk_modeling:engagementDropAlert(self.metricsAPIClient, riskInputs, engamenetTreshold);

        if engagementDropAlerts is json {

            json response = {"engagementDropAlerts": engagementDropAlerts};
            check caller->respond(response);

        } else {

            json response = {"error": engagementDropAlerts.message()};
            check caller->respond(response);

        }
    }

    //calculate priority score
    resource function post priority_score(http:Caller caller, engagement_metrics:EPSInput epsInput) returns error? {

        json|error? Eps = engagement_metrics:calculateEps(self.metricsAPIClient, epsInput);

        if Eps is json {

            json response = {"EpsResult": Eps};
            check caller->respond(response);

        } else {

            json response = {"error": Eps.message()};
            check caller->respond(response);

        }
    }

    //calculate balanced score metrics
    resource function post balanced_score(http:Caller caller, engagement_metrics:BSCInput bscInput) returns error? {

        json|error? Bsc = engagement_metrics:calculateBsc(self.metricsAPIClient, bscInput);

        if Bsc is json {

            json response = {"BscResult": Bsc};
            check caller->respond(response);

        } else {

            json response = {"error": Bsc.message()};
            check caller->respond(response);

        }
    }

    //calculate total engament score
    resource function post engagement_score(http:Caller caller, engagement_metrics:TESInput tesInput) returns error? {

        json|error? Tsc = engagement_metrics:calculateTes(self.metricsAPIClient, tesInput);

        if Tsc is json {

            json response = {"TscResult": Tsc};
            check caller->respond(response);

        } else {

            json response = {"error": Tsc.message()};
            check caller->respond(response);

        }
    }

    //influence_index
    resource function post influence_index_cal(http:Caller caller, theoretical_depth:SEmetrics se_metrics) returns error? {

        json|error? influenceIndex = theoretical_depth:calculateInfluenceIndex(self.metricsAPIClient, se_metrics);

        if influenceIndex is json{

            json response = { "influenceIndex": influenceIndex };
            check caller->respond(response);
 
        } else {

            json response = { "error": influenceIndex.message()};
            check caller->respond(response);

        }
    }

    //nashEquilibrium
    resource function post nash_equilibrium_cal(http:Caller caller, theoretical_depth:CustomTable customTable) returns error? {

        json|error? nashEquilibrium = theoretical_depth:calculateNashEquilibrium(self.metricsAPIClient, customTable);

        if nashEquilibrium is json{

            json response = { "nashEquilibrium": nashEquilibrium };
            check caller->respond(response);
 
        } else {

            json response = { "error": nashEquilibrium.message()};
            check caller->respond(response);

        }
    }

    //socialExchange
    resource function post social_exchange_cal(http:Caller caller, theoretical_depth:StakeholderRelation stakeholderRelation) returns error? {

        json|error? socialExchange = theoretical_depth:calculateSocialExchange(self.metricsAPIClient, stakeholderRelation);

        if socialExchange is json{

            json response = { "socialExchange": socialExchange };
            check caller->respond(response);
 
        } else {

            json response = { "error": socialExchange.message()};
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
                        // check caller->respond("User successfully authenticated!");
                        string userEmail = email;
                        json response = {user_email: userEmail};
                        check caller->respond(response);
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

    // Calculate SIM
resource function post calculate_sim(http:Caller caller, http:Request req) returns error? {
    json payload = check req.getJsonPayload();

    stakeholder_equilibrium:Stakeholder[] stakeholders = check jsondata:parseAsType(check payload.stakeholders);

    // Call the calculateSIM function and handle the response or error
    json|error? simResponse = stakeholder_equilibrium:calculateSIM(self.metricsAPIClient, stakeholders);

    if simResponse is json {
        // If the result is successful, send the response
        json response = { "Stakeholder Influence Matrix (SIM)": simResponse };
        check caller->respond(response);
    } else {
        // If there's an error, return the error message
        json response = { "error": simResponse.message() };
        check caller->respond(response);
    }
}
// Calculate DSI
resource function post calculate_dsi(http:Caller caller, http:Request req) returns error? {
    json payload = check req.getJsonPayload();

    stakeholder_equilibrium:Stakeholder[] stakeholders = check jsondata:parseAsType(check payload.stakeholders);
    float[] deltaBehavior = check jsondata:parseAsType(check payload.deltaBehavior);

    json|error? dsiResult = stakeholder_equilibrium:calculateDynamicStakeholderImpact(self.metricsAPIClient, stakeholders, deltaBehavior);

    if dsiResult is json {
        json response = { "Dynamic Stakeholder Impact (DSI)": dsiResult };
        check caller->respond(response);
    } else {
        json response = { "error": dsiResult.message() };
        check caller->respond(response);
    }
}

// Calculate SNS 

resource function post calculate_sns(http:Caller caller, http:Request req) returns error? {
    json payload = check req.getJsonPayload();

    stakeholder_equilibrium:Stakeholder[] stakeholders = check jsondata:parseAsType(check payload.stakeholders);
    float[] deltaBehavior = check jsondata:parseAsType(check payload.deltaBehavior);

    json|error? snsResult = stakeholder_equilibrium:calculateStakeholderNetworkStability(self.metricsAPIClient, stakeholders, deltaBehavior);

    if snsResult is json {
        json response = { "Stakeholder Network Stability (SNS)": snsResult };
        check caller->respond(response);
    } else {
        json response = { "error": snsResult.message() };
        check caller->respond(response);
    }
}


// Calculate SIS 
resource function post calculate_sis(http:Caller caller, http:Request req) returns error? {
    json payload = check req.getJsonPayload();

    stakeholder_equilibrium:Stakeholder[] stakeholders = check jsondata:parseAsType(check payload.stakeholders);

    json|error? sisResult = stakeholder_equilibrium:calculateSystemicInfluenceScore(self.metricsAPIClient, stakeholders);

    if sisResult is json {
        json response = { "Systemic Influence Score (SIS)": sisResult };
        check caller->respond(response);
    } else {
        json response = { "error": sisResult.message() };
        check caller->respond(response);
    }
}

    // resource function post registerStakeholder(http:Caller caller, Stakeholder stakeholder) returns error? {
    //     sql:ExecutionResult _ = check self.dbClient->execute(stakeholderRegisterParameterizedQuery(stakeholder));
    //     check caller->respond("Successfully Added");
    // }

    resource function post registerStakeholder(http:Caller caller, http:Request req) returns error? {
        json payload = check req.getJsonPayload();
        Stakeholder stakeholder = check payload.cloneWithType(Stakeholder);

        // Check if the email already exists
        boolean emailExists = check self.checkIfEmailExists(stakeholder.email_address);

        if (emailExists) {
        // Respond with a conflict message
        check caller->respond({ statusCode: 409, 
        message: "Email already exists. Please use a different email address." });
        return;
        
    }

        sql:ExecutionResult _ = check self.dbClient->execute(stakeholderRegisterParameterizedQuery(stakeholder));
        // check caller->respond("Successfully Added");
        check caller->respond({ message: "Stakeholder registered successfully" });
    }

    // Fetch all stakeholders for a given user_email
    resource function get getAllStakeholder(string user_email) returns Stakeholder[]|error? {
        return self.getAllStakeholders(user_email);
    }

    resource function get sort(string stakeholder_type, string user_email) returns Stakeholder[]|error {
        return self.sortStakeholdersByType(stakeholder_type, user_email);
    }

    resource function get search(string email_address, string user_email) returns Stakeholder[]|error? {
        return self.searchStakeholderByEmail(email_address, user_email);
    }

    resource function get types() returns StakeholderType[]|error {
        return self.getAllStakeholderTypes();
    }

    // Function to get all stakeholders
    function getAllStakeholders(string user_email) returns Stakeholder[]|error {
        Stakeholder[] stakeholders = [];
        // sql:ParameterizedQuery query = `SELECT * FROM stakeholders WHERE user_email = ${user_email}`;
        stream<Stakeholder, sql:Error?> resultStream = self.dbClient->query(getAllStakeholderParameterizedQuery(user_email));

        check from Stakeholder stakeholder in resultStream
            do {
                stakeholders.push(stakeholder);
            };

        check resultStream.close();
        return stakeholders;
    }

    function sortStakeholdersByType(string type_id, string user_email) returns Stakeholder[]|error {
        Stakeholder[] stakeholders = [];
        stream<Stakeholder, sql:Error?> resultStream = self.dbClient->query(sortStakeholdersByTypeParameterizedQuery(type_id,user_email));
        check from Stakeholder stakeholder in resultStream
            do {
                stakeholders.push(stakeholder);
            };
        check resultStream.close();
        return stakeholders;
    }

    function searchStakeholderByEmail(string email_address, string user_email) returns Stakeholder[]|error? {
        Stakeholder[] stakeholders = [];
        stream<Stakeholder, sql:Error?> resultStream = self.dbClient->query(searchStakeholderByEmailParameterizedQuery(email_address,user_email));
        check from Stakeholder stakeholder in resultStream
            do {
                stakeholders.push(stakeholder);
            };
        check resultStream.close();
        return stakeholders;
    }

    isolated function getAllStakeholderTypes() returns StakeholderType[]|error {
        StakeholderType[] types = [];
        stream<StakeholderType, sql:Error?> resultStream = self.dbClient->query(`SELECT * FROM stakeholder_types`);
        check from StakeholderType typ in resultStream
            do {
                types.push(typ);
            };
        check resultStream.close();
        return types;
    }


    function checkIfEmailExists(string email_address) returns boolean|error {
    stream<record {}, sql:Error?> resultStream = self.dbClient->query(`SELECT 1 FROM stakeholders WHERE email_address = ${email_address}`);
    var result = check resultStream.next();

    if result is record {} {
        // Email exists
        return true;
    }

    return false; // Email doesn't exist
}

}
