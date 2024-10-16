import stakeholder_management_backend.engagement_metrics;
import stakeholder_management_backend.meetings;
import stakeholder_management_backend.risk_modeling;
import stakeholder_management_backend.stakeholder_equilibrium;
import stakeholder_management_backend.theoretical_depth;

import ballerina/data.jsondata;
import ballerina/http;
import ballerina/io;
import ballerina/jwt;
import ballerina/log;
import ballerina/sql;
import ballerina/uuid;
import ballerinax/java.jdbc;
import ballerinax/mysql.driver as _;

type rowType record {

};

@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:3000"],
        allowMethods: ["GET", "PUT", "POST", "DELETE", "OPTIONS"],
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
    resource function get data(http:RequestContext ctx) returns error? {
        [jwt:Header, jwt:Payload] jwtInfo = check ctx.getWithType(http:JWT_INFORMATION);
        io:println(jwtInfo);
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

        if influenceIndex is json {

            json response = {"influenceIndex": influenceIndex};
            check caller->respond(response);

        } else {

            json response = {"error": influenceIndex.message()};
            check caller->respond(response);

        }
    }

    //nashEquilibrium
    resource function post nash_equilibrium_cal(http:Caller caller, theoretical_depth:CustomTable customTable) returns error? {

        json|error? nashEquilibrium = theoretical_depth:calculateNashEquilibrium(self.metricsAPIClient, customTable);

        if nashEquilibrium is json {

            json response = {"nashEquilibrium": nashEquilibrium};
            check caller->respond(response);

        } else {

            json response = {"error": nashEquilibrium.message()};
            check caller->respond(response);

        }
    }

    //socialExchange
    resource function post social_exchange_cal(http:Caller caller, theoretical_depth:StakeholderRelation stakeholderRelation) returns error? {

        json|error? socialExchange = theoretical_depth:calculateSocialExchange(self.metricsAPIClient, stakeholderRelation);

        if socialExchange is json {

            json response = {"socialExchange": socialExchange};
            check caller->respond(response);

        } else {

            json response = {"error": socialExchange.message()};
            check caller->respond(response);

        }
    }

    //meetings
    resource function post schedule_meeting(meetings:NewMeeting newMeeting) returns meetings:MeetingCreated|error? {
        transaction {
            sql:ExecutionResult result = check self.dbClient->execute(`
            INSERT INTO meetings (title, description, meeting_date, meeting_time, location)
            VALUES (${newMeeting.title}, ${newMeeting.description}, ${newMeeting.meeting_date}, ${newMeeting.meeting_time}, ${newMeeting.location})
        `);

            int|string? lastInsertId = result.lastInsertId;

            if lastInsertId is int {
                int meetingId = lastInsertId;

                foreach int stakeholderId in newMeeting.stakeholders {
                    _ = check self.dbClient->execute(`
                    INSERT INTO meeting_stakeholders (meeting_id, stakeholder_id)
                    VALUES (${meetingId}, ${stakeholderId})
                `);
                }

                check commit;

                return <meetings:MeetingCreated>{
                    body: {
                        id: meetingId,
                        ...newMeeting
                    }
                };
            } else {
                rollback;
                return error("Error occurred while retrieving the last insert ID");
            }
        }
    }

    // Get all upcoming meetings
    resource function get upcoming_meetings() returns meetings:MeetingRecord[]|error {
        sql:ParameterizedQuery query = `SELECT M.id, M.title, M.description, M.meeting_date, 
    M.meeting_time, M.location, 
    GROUP_CONCAT(S.stakeholder_name) AS stakeholders 
    FROM meetings M 
    LEFT JOIN meeting_stakeholders MS ON M.id = MS.meeting_id 
    LEFT JOIN stakeholders S ON MS.stakeholder_id = S.id 
    WHERE M.meeting_date >= CURRENT_DATE 
    GROUP BY M.id, M.title, M.description, M.meeting_date, M.meeting_time, M.location 
    ORDER BY M.meeting_date ASC;`;

        stream<meetings:MeetingRecord, sql:Error?> meetingStream = self.dbClient->query(query);
        return from meetings:MeetingRecord meeting in meetingStream
            select meeting;
    }

    // Get all meetings
    resource function get all_meetings() returns meetings:MeetingRecord[]|error {
        sql:ParameterizedQuery query = `SELECT M.id, M.title, M.description, M.meeting_date, 
       M.meeting_time, M.location, 
       GROUP_CONCAT(S.id, ':', S.stakeholder_name) AS stakeholders 
        FROM meetings M 
    LEFT JOIN meeting_stakeholders MS ON M.id = MS.meeting_id 
    LEFT JOIN stakeholders S ON MS.stakeholder_id = S.id
    GROUP BY M.id
    ORDER BY M.meeting_date ASC`;
        stream<meetings:MeetingRecord, sql:Error?> meetingStream = self.dbClient->query(query);
        return from meetings:MeetingRecord meeting in meetingStream
            select meeting;
    }

    // Get a single meeting by ID
    resource function get meetings/[int id]() returns meetings:MeetingRecord|http:NotFound {
        sql:ParameterizedQuery query = `SELECT M.id, M.title, M.description, M.meeting_date, 
    M.meeting_time, M.location, 
    GROUP_CONCAT(S.id, ':', S.stakeholder_name) AS stakeholders 
    FROM meetings M 
    LEFT JOIN meeting_stakeholders MS ON M.id = MS.meeting_id 
    LEFT JOIN stakeholders S ON MS.stakeholder_id = S.id 
    WHERE M.id = ${id} 
    GROUP BY M.id, M.title, M.description, M.meeting_date, M.meeting_time, M.location;`;

        meetings:MeetingRecord|error meeting = self.dbClient->queryRow(query);
        return meeting is meetings:MeetingRecord ? meeting : http:NOT_FOUND;
    }

    //mark attendance
    resource function post mark_attendance(meetings:AttendaceRecord attendanceRecord) returns error? {
        sql:ParameterizedQuery query = `UPDATE meeting_stakeholders 
                                     SET attended = ${attendanceRecord.attended} 
                                     WHERE meeting_id = ${attendanceRecord.meetingId} AND stakeholder_id = ${attendanceRecord.stakeholderId}`;
        _ = check self.dbClient->execute(query);
    }

    // get All attendance
    resource function get attendance/[int meetingId]() returns meetings:Attendace[]|error {
        sql:ParameterizedQuery query = `SELECT stakeholder_id,attended FROM meeting_stakeholders
                                     WHERE meeting_id = ${meetingId}`;
        stream<meetings:Attendace, sql:Error?> attendanceStream = self.dbClient->query(query);
        return from meetings:Attendace atendance in attendanceStream
            select atendance;
    }

    resource function get meetingCountByMonth() returns meetings:MeetingCount[]|error {
        sql:ParameterizedQuery query = `
        SELECT 
            MONTHNAME(MIN(M.meeting_date)) AS month,
            YEAR(MIN(M.meeting_date)) AS year,
            COUNT(M.id) AS count,
            MIN(M.meeting_date) AS order_date
        FROM meetings M
        WHERE M.meeting_date <= CURRENT_DATE
        AND YEAR(M.meeting_date) = YEAR(CURRENT_DATE)
        GROUP BY YEAR(M.meeting_date), MONTH(M.meeting_date)
        ORDER BY order_date
    `;

        stream<meetings:MeetingCount, sql:Error?> meetingStream = self.dbClient->query(query);
        return from meetings:MeetingCount meeting in meetingStream
            select meeting;
    }

    // Get total meetings count
    resource function get totalMeetingsCount() returns int|error {
        sql:ParameterizedQuery query = `
        SELECT COUNT(*) AS total_count
        FROM meetings
    `;

        record {|int total_count;|}|sql:Error result = self.dbClient->queryRow(query);

        if result is record {|int total_count;|} {
            return result.total_count;
        } else {
            return error("Failed to retrieve total meetings count");
        }
    }

    // Get total stakeholders count
    resource function get totalStakeholdersCount() returns int|error {
        sql:ParameterizedQuery query = `
        SELECT COUNT(DISTINCT stakeholder_id) AS total_count
        FROM meeting_stakeholders
    `;

        record {|int total_count;|}|sql:Error result = self.dbClient->queryRow(query);

        if result is record {|int total_count;|} {
            return result.total_count;
        } else {
            return error("Failed to retrieve total stakeholders count");
        }
    }

    //meetings

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

                        if email != "" && !self.checkUserExists(email) {
                            string userName = (check userInfo.name).toString();
                            string password = uuid:createType1AsString();

                            sql:ParameterizedQuery query = `INSERT INTO users 
                            (administratorName, email, username, password) VALUES 
                            (${userName}, ${email}, ${userName}, ${password})`;

                            sql:ExecutionResult _ = check self.dbClient->execute(query);
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

    resource function post getUserDataFromAccessToken(http:Caller caller, http:Request req) returns error? {
        // var accessToken = req.getHeader("accessToken");
        // if accessToken is string {
        json|error reqPayload = req.getJsonPayload();
        if reqPayload is json {
            string? accessToken = (check reqPayload.accessToken).toString();
            if accessToken is string {
                json userInfo = check getUserInfo(accessToken);

                string email = (check userInfo.email).toString();
                string profilePicture = (check userInfo.picture).toString();

                stream<record {}, sql:Error?> resultStream = self.dbClient->query(getUserData(email));

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
                        json response = {
                            user: user,
                            user_email: email,
                            profilePicture: profilePicture
                        };
                        check caller->respond(response);
                        // return user;
                    };

                json response = {
                    profilePicture: profilePicture,
                    user_email: email
                };
                // json response = {
                //     message: "test message"
                // };
                check caller->respond(response);
            }
        }
    }

    // Function to handle refreshing the access token using the refresh token
    resource function post refreshToken(http:Caller caller, http:Request req) returns error? {
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

    resource function post signup(http:Caller caller, Users users) returns error? {
        sql:ExecutionResult _ = check self.dbClient->execute(signupParameterizedQuery(users));
        check caller->respond("Sign up successful");
    }

    resource function post userProfileUpdate(http:Caller caller, Users users) returns error? {
        sql:ExecutionResult _ = check self.dbClient->execute(updateUserParameterizedQuery(users));
        check caller->respond("Update successful");
    }

    resource function get getUserDetails(string? email) returns Users|error {
        if email is string {
            io:println("Received email: " + email.toBalString());
            stream<record {}, sql:Error?> resultStream = self.dbClient->query(getUserData(email));
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
            json response = {"Stakeholder Influence Matrix (SIM)": simResponse};
            check caller->respond(response);
        } else {
            // If there's an error, return the error message
            json response = {"error": simResponse.message()};
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
            json response = {"Dynamic Stakeholder Impact (DSI)": dsiResult};
            check caller->respond(response);
        } else {
            json response = {"error": dsiResult.message()};
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
            json response = {"Stakeholder Network Stability (SNS)": snsResult};
            check caller->respond(response);
        } else {
            json response = {"error": snsResult.message()};
            check caller->respond(response);
        }
    }

    // Calculate SIS 
    resource function post calculate_sis(http:Caller caller, http:Request req) returns error? {
        json payload = check req.getJsonPayload();

        stakeholder_equilibrium:Stakeholder[] stakeholders = check jsondata:parseAsType(check payload.stakeholders);

        json|error? sisResult = stakeholder_equilibrium:calculateSystemicInfluenceScore(self.metricsAPIClient, stakeholders);

        if sisResult is json {
            json response = {"Systemic Influence Score (SIS)": sisResult};
            check caller->respond(response);
        } else {
            json response = {"error": sisResult.message()};
            check caller->respond(response);
        }
    }

    resource function post registerStakeholder(http:Caller caller, http:Request req) returns error? {
        json payload = check req.getJsonPayload();
        Stakeholder stakeholder = check payload.cloneWithType(Stakeholder);

        // Check if the email already exists
        boolean emailExists = check self.checkIfEmailExists(stakeholder.email_address);

        if (emailExists) {
            // Respond with a conflict message
            check caller->respond({
                statusCode: 409,
                message: "Email already exists. Please use a different email address."
            });
            return;

        }

        sql:ExecutionResult _ = check self.dbClient->execute(stakeholderRegisterParameterizedQuery(stakeholder));
        // check caller->respond("Successfully Added");
        check caller->respond({message: "Stakeholder registered successfully"});
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
        stream<Stakeholder, sql:Error?> resultStream = self.dbClient->query(sortStakeholdersByTypeParameterizedQuery(type_id, user_email));
        check from Stakeholder stakeholder in resultStream
            do {
                stakeholders.push(stakeholder);
            };
        check resultStream.close();
        return stakeholders;
    }

    function searchStakeholderByEmail(string email_address, string user_email) returns Stakeholder[]|error? {
        Stakeholder[] stakeholders = [];
        stream<Stakeholder, sql:Error?> resultStream = self.dbClient->query(searchStakeholderByEmailParameterizedQuery(email_address, user_email));
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

    //survey codes

    // Create a new survey
    resource function post newSurvey(http:Caller caller, http:Request req) returns error? {
        json surveyData = check req.getJsonPayload();
        string title = (check surveyData.title).toString();
        string description = (check surveyData.description).toString();
        string user_email = (check surveyData.user_email).toString();

        sql:ExecutionResult _ = check self.dbClient->execute(`INSERT INTO surveys (title, description,user_email) VALUES (${title}, ${description},${user_email})`);

        check caller->respond({
            statusCode: 200,
            message: "Survey created successfully"
        });

        return;
    }

    // update a survey
    resource function put updateSurvey(http:Caller caller, http:Request req) returns error? {
        json surveyData = check req.getJsonPayload();
        string title = check surveyData.title;
        string description = check surveyData.description;
        string id = (check surveyData.id).toString();

        sql:ExecutionResult _ = check self.dbClient->execute(`UPDATE surveys 
        SET title = ${title}, description = ${description}
        WHERE id=${id}`);

        // check caller->respond("Survey updated successfully");

        check caller->respond({
            statusCode: 204,
            message: "Survey updated successfully"
        });

        return;
    }

    // Get all surveys
    resource function get allSurveys(string user_email) returns Survey[]|error {
        Survey[] surveys = [];
        sql:ParameterizedQuery query = `SELECT * FROM surveys WHERE status = '1' AND user_email=${user_email}`;
        stream<Survey, sql:Error?> resultStream = self.dbClient->query(query);

        check from Survey survey in resultStream
            do {
                surveys.push(survey);
            };

        check resultStream.close();
        return surveys;
    }

    // Get survey by ID
    resource function get surveyById(int id) returns Survey|error? {
        sql:ParameterizedQuery query = `SELECT * FROM surveys WHERE id = ${id}`;
        stream<record {|int id; string title; string description;|}, sql:Error?> resultStream = self.dbClient->query(query);

        // Survey survey;
        // json survey = {};
        var result = resultStream.next();
        if result is record {|Survey value;|} {
            Survey survey = result.value;
            check resultStream.close();
            return survey;
        } else {
            check resultStream.close();
            json errorResponse = {message: "Survey not found"};
            http:Response response = new;
            response.statusCode = 404;
            response.setJsonPayload(errorResponse);
            return error("Survey not found");
        }
    }

    // Delete a survey
    resource function put deleteSurvey(string id) returns error? {
        // Execute the SQL delete statement
        // sql:ExecutionResult result = check self.dbClient->execute(`DELETE FROM surveys WHERE id = ${id}`);
        sql:ExecutionResult result = check self.dbClient->execute(`UPDATE surveys 
        SET status = 0 WHERE id=${id}`);

        // Check if any rows were deleted
        if (result.affectedRowCount == 0) {
            return error("Survey not found");
        }

        // Return a success message
        return;
    }

    // Add a question to a survey
    resource function post addQuestion(http:Request req) returns error? {
        json questionData = check req.getJsonPayload();
        int surveyId = <int>(check questionData.surveyId);
        string questionText = (check questionData.questionText).toString();
        string questionType = (check questionData.questionType).toString();
        json[] choices = <json[]>(check questionData.choices);

        sql:ParameterizedQuery query = `INSERT INTO questions (survey_id, question_text, question_type) VALUES (${surveyId}, ${questionText}, ${questionType})`;
        sql:ExecutionResult result = check self.dbClient->execute(query);

        // Retrieve the last inserted ID
        int|string? lastInsertId = result.lastInsertId;

        if lastInsertId is int {
            io:println("Last Inserted ID: ", lastInsertId);

            // Insert choices if applicable (for multiple_choice, checkbox, or rating types)
            if (questionType == "multiple_choice" || questionType == "checkbox" || questionType == "rating") {
                foreach var choice in choices {
                    sql:ParameterizedQuery choiceQuery = `INSERT INTO choices (question_id, choice_text)
                                                  VALUES (${lastInsertId}, ${choice.toString()})`;
                    _ = check self.dbClient->execute(choiceQuery);
                }
            }
        } else {
            io:println("Unable to obtain last insert ID");

        }
        return;
    }

    // Update Question by ID
    resource function put updateQuestion(http:Caller caller, http:Request req) returns error? {
        json questionData = check req.getJsonPayload();
        int id = <int>(check questionData.id); // Get the question ID from the request body
        int surveyId = <int>(check questionData.surveyId);
        string questionText = (check questionData.questionText).toString();
        string questionType = (check questionData.questionType).toString();
        json[] choices = <json[]>(check questionData.choices);

        // Update the question in the database
        sql:ParameterizedQuery query = `UPDATE questions 
                                        SET survey_id = ${surveyId}, 
                                            question_text = ${questionText}, 
                                            question_type = ${questionType} 
                                        WHERE id = ${id}`;
        _ = check self.dbClient->execute(query);

        // If the question type has choices, update them
        if (questionType == "multiple_choice" || questionType == "checkbox" || questionType == "rating") {
            // Delete existing choices
            sql:ParameterizedQuery deleteQuery = `DELETE FROM choices WHERE question_id = ${id}`;
            _ = check self.dbClient->execute(deleteQuery);

            // Insert new choices
            foreach var choice in choices {
                sql:ParameterizedQuery choiceQuery = `INSERT INTO choices (question_id, choice_text)
                                                      VALUES (${id}, ${choice.toString()})`;
                _ = check self.dbClient->execute(choiceQuery);
            }
        }

        // Send a response indicating successful update
        check caller->respond({
            statusCode: 204,
            message: "Question updated successfully"
        });

        return;
    }

    // Get all questions
    resource function get allQuestion(string user_email) returns TransformedQuestion[]|error {
        AllQuestion[] allQuestions = [];

        // Query to get all active questions
        // sql:ParameterizedQuery query = `SELECT * FROM questions WHERE status = '1' AND survey_id IN (SELECT id as survey_id FROM surveys WHERE user_email IN ('${userEmail}'))`;
        stream<Question, sql:Error?> resultStream = self.dbClient->query(allQuestionParameterizedQuery(user_email));

        check from Question question in resultStream
            do {

                Choice[] choicesByQuestionId = check self.getChoicesByQuestionId(question.id);

                AllQuestion allQuestion = {
                    question: question,
                    choices: choicesByQuestionId
                };

                // Push the question and its choices to the final list
                allQuestions.push(allQuestion);
            };

        // Close the result stream for questions
        check resultStream.close();

        // Transform questions to the desired output format
        TransformedQuestion[] transformedQuestions = self.transformQuestions(allQuestions);

        return transformedQuestions;
    }

    resource function get allChoicesByQuestionId(int id) returns Choice[]|error {
        Choice[] listResult = check self.getChoicesByQuestionId(id);
        return listResult;
    }

    public function getChoicesByQuestionId(int id) returns Choice[]|error {
        // Initialize an empty array to store choices
        Choice[]? choices = null;

        // Query to get choices for the current question
        sql:ParameterizedQuery query1 = `SELECT * FROM choices WHERE question_id = ${id} AND status = '1'`;
        stream<Choice, sql:Error?> resultStream1 = self.dbClient->query(query1);

        check from Choice choice in resultStream1
            do {
                // Initialize the array if it's not done already
                if (choices is null) {
                    choices = [];
                }

                // Safely push choices into the array
                // choices.push(choice);
                (<Choice[]>choices).push(choice);
            };

        // Close the result stream for choices
        check resultStream1.close();

        // If choices are not found, ensure the array is empty
        if (choices is null) {
            choices = []; // This guarantees that the array is not null
        }

        return <Choice[]>choices;
    }

    // Submit a response
    resource function post submitResponse(http:Caller caller, http:Request req, int surveyId) returns error? {
        // Parse the request body
        json questionData = check req.getJsonPayload();
        string questionText = (check questionData.question_text).toString();
        string questionType = (check questionData.question_type).toString();

        // Insert the new question into the `questions` table
        sql:ParameterizedQuery query = `INSERT INTO questions (survey_id, question_text, question_type) 
                                        VALUES (${surveyId}, ${questionText}, ${questionType})`;
        _ = check self.dbClient->execute(query);

        // Respond with a success message
        check caller->respond({
            message: "Question added successfully"
        });
    }

    public function transformQuestions(AllQuestion[] allQuestions) returns TransformedQuestion[] {
        TransformedQuestion[] transformedQuestions = [];

        foreach var item in allQuestions {
            TransformedQuestion transformedQuestion = {
                id: item.question.id,
                surveyId: item.question.survey_id,
                questionText: item.question.question_text,
                questionType: item.question.question_type,
                choices: from var choice in item.choices
                    select choice.choice_text
            };

            transformedQuestions.push(transformedQuestion);
        }

        return transformedQuestions;
    }

    // Update status to 0 for both the question and its related choices
    resource function put deleteQuestion(http:Request req) returns error? {
        // Extract the id from the request body
        json requestBody = check req.getJsonPayload();
        string id = (check requestBody.id).toString();

        // Update the status of all choices related to this question to 0
        sql:ExecutionResult _ = check self.dbClient->execute(`UPDATE choices 
        SET status = 0 WHERE question_id=${id}`);

        // Update the status of the question to 0
        sql:ExecutionResult questionResult = check self.dbClient->execute(`UPDATE questions 
        SET status = 0 WHERE id=${id}`);

        // Check if any rows were affected for the question
        if (questionResult.affectedRowCount == 0) {
            return error("Question not found");
        }

        // Return a success message
        return;
    }

    // Get all responses
    resource function get allResponses() returns TransformedResponse[]|error {
        AllResponse[] allResponses = [];

        // Query to get all responses
        sql:ParameterizedQuery query = `SELECT * FROM responses`;
        stream<Response, sql:Error?> resultStream = self.dbClient->query(query);

        check from Response response in resultStream
            do {
                // Fetch the corresponding stakeholder for this response
                sql:ParameterizedQuery stakeholderQuery = `SELECT * FROM stakeholders WHERE id = ${response.stakeholder_id}`;
                Stakeholder? stakeholder = check self.dbClient->queryRow(stakeholderQuery);

                // Fetch the corresponding survey for this response
                sql:ParameterizedQuery surveyQuery = `SELECT * FROM surveys WHERE id = ${response.survey_id}`;
                Survey? survey = check self.dbClient->queryRow(surveyQuery);

                // Fetch the corresponding question for this response
                sql:ParameterizedQuery questionQuery = `SELECT * FROM questions WHERE id = ${response.question_id}`;
                Question? question = check self.dbClient->queryRow(questionQuery);

                // Ensure that stakeholder, survey, and question exist
                if (stakeholder is Stakeholder && survey is Survey && question is Question) {
                    AllResponse allResponse = {
                        response: response,
                        stakeholder: stakeholder,
                        survey: survey,
                        question: question
                    };

                    // Push the response and its related data to the final list
                    allResponses.push(allResponse);
                }
            };

        // Close the result stream for responses
        check resultStream.close();

        // Transform responses to the desired output format
        TransformedResponse[] transformedResponses = self.transformResponses(allResponses);

        return transformedResponses;
    }

    // Function to transform responses into the desired format
    public function transformResponses(AllResponse[] allResponses) returns TransformedResponse[] {
        TransformedResponse[] transformedResponses = [];

        foreach var item in allResponses {
            TransformedResponse transformedResponse = {
                id: item.response.id,
                stakeholderId: item.response.stakeholder_id,
                surveyId: item.response.survey_id,
                questionId: item.response.question_id,
                responseText: item.response.response_text
            };

            transformedResponses.push(transformedResponse);
        }

        return transformedResponses;
    }

    // Get all submissions
    resource function get allSubmissions() returns TransformedSubmission[]|error {
        AllSubmission[] allSubmissions = [];

        // Query to get all submissions
        sql:ParameterizedQuery query = `SELECT * FROM survey_submissions`;
        stream<Submission, sql:Error?> resultStream = self.dbClient->query(query);

        // Iterate over the stream to fetch each submission
        record {|Submission value;|}? nextSubmission = check resultStream.next();

        while nextSubmission is record {|Submission value;|} {
            Submission submission = nextSubmission.value;

            // Fetch the corresponding stakeholder for this submission
            sql:ParameterizedQuery stakeholderQuery = `SELECT * FROM stakeholders WHERE id = ${submission.stakeholder_id}`;
            Stakeholder? stakeholder = check self.dbClient->queryRow(stakeholderQuery);

            // Fetch the corresponding survey for this submission
            sql:ParameterizedQuery surveyQuery = `SELECT * FROM surveys WHERE id = ${submission.survey_id}`;
            Survey? survey = check self.dbClient->queryRow(surveyQuery);

            // Ensure that stakeholder and survey exist
            if (stakeholder is Stakeholder && survey is Survey) {
                AllSubmission allSubmission = {
                    submission: submission,
                    stakeholder: stakeholder,
                    survey: survey
                };

                // Push the submission and its related data to the final list
                allSubmissions.push(allSubmission);
            }

            // Fetch the next submission in the stream
            nextSubmission = check resultStream.next();
        }

        // Close the result stream for submissions
        check resultStream.close();

        // Transform submissions to the desired output format
        TransformedSubmission[] transformedSubmissions = self.transformSubmissions(allSubmissions);

        return transformedSubmissions;
    }

    // Function to transform submissions into the desired format
    public function transformSubmissions(AllSubmission[] allSubmissions) returns TransformedSubmission[] {
        TransformedSubmission[] transformedSubmissions = [];

        foreach var item in allSubmissions {
            TransformedSubmission transformedSubmission = {
                id: item.submission.id,
                stakeholderId: item.submission.stakeholder_id,
                surveyId: item.submission.survey_id,
                stakeholderName: item.stakeholder.stakeholder_name,
                surveyTitle: item.survey.title,
                submittedAt: item.submission.submitted_at
            };

            transformedSubmissions.push(transformedSubmission);
        }

        return transformedSubmissions;
    }

    resource function post share(http:Caller caller, http:Request req) returns error? {
        json|error payload = req.getJsonPayload();
        if (payload is json) {
            // Extract survey title and selected stakeholder types from the payload
            string surveyId = (check payload.surveyId).toString();
            string surveyTitle = (check payload.surveyTitle).toString();
            string user_email = (check payload.user_email).toString();
            json[] selectedTypes = <json[]>(check payload.selectedTypes);

            string stringResult = selectedTypes.toString();

            // Convert the array to a string and remove the brackets
            string formattedString = stringResult.toString().substring(1, stringResult.toString().length() - 1);

            // Remove quotation marks manually
            string finalString = "";
            byte[] byteArray = string:toBytes(formattedString);
            foreach byte b in byteArray {
                if (b != 34) { // ASCII value of double quote is 34
                    finalString += check string:fromBytes([b]);
                }
            }

            // Fetch stakeholders based on types
            Stakeholder[] stakeholders = check self.getStakeholdersByType(selectedTypes, user_email);

            // Send the survey to the selected stakeholders
            check self.sendSurveyToStakeholders(surveyTitle, stakeholders, surveyId);

            // Send a response back to the frontend
            json response = {
                message: "Survey shared successfully with " + stakeholders.length().toString() + " stakeholders."
            };
            check caller->respond(response);
        } else {
            check caller->respond({message: "Invalid payload"});
        }
    }

    // Function to fetch stakeholders by type
    function getStakeholdersByType(json[] types, string user_email) returns Stakeholder[]|error {
        Stakeholder[] stakeholders = [];

        // Iterate over each element in the json array
        foreach var typ in types {
            // Ensure the element is a string before processing
            if (typ is string) {
                // Prepare SQL query to fetch stakeholders by types
                sql:ParameterizedQuery query = `SELECT * FROM stakeholders WHERE 
    stakeholder_type IN (SELECT id FROM stakeholder_types WHERE type_name = ${typ.toString()}) 
    AND user_email = ${user_email.toString()}`;

                stream<Stakeholder, sql:Error?> resultStream = self.dbClient->query(query);
                // Collect results from stream
                check from Stakeholder stakeholder in resultStream
                    do {
                        stakeholders.push(stakeholder);
                    };
            } else {
                io:println("Invalid type found in array");
            }
        }

        return stakeholders;
    }

    // Function to send survey emails to stakeholders
    function sendSurveyToStakeholders(string surveyTitle, Stakeholder[] stakeholders, string surveyId) returns error? {
        EmailDetails[] emailList = [];
        foreach Stakeholder stakeholder in stakeholders {

            string generateSurveyLink = "http://localhost:3000/survey/view?stakeholderemail=" + stakeholder.email_address + "&surveyid=" + surveyId + "";

            EmailDetails e = {recipient: stakeholder.email_address, subject: surveyTitle, bodyHtml: "<!DOCTYPE html><html lang=en><head><meta charset=UTF-8><meta name=viewport content=width=device-width,initial-scale=1.0><style>body{font-family:Arial,sans-serif;background-color:#f4f4f4;margin:0;padding:20px}.email-container{background-color:#ffffff;padding:20px;border-radius:8px;box-shadow:0 2px 4px rgba(0,0,0,0.1);max-width:600px;margin:auto}h2{color:#333333}p{color:#555555}.survey-button{display:inline-block;background-color:#28a745;color:#ffffff;padding:12px 20px;border-radius:5px;text-decoration:none;font-weight:bold}.survey-button:hover{background-color:#218838}</style><title>New Survey Available</title></head><body><div class=email-container><h2>New Survey Available</h2><p>Hello,</p><p>We are excited to inform you that a new survey is now available for you to participate in.</p><p>Please click the button below to access the survey:</p><a href='" + generateSurveyLink + "' class=survey-button>Take the Survey</a><p>Thank you for your time and feedback!</p></div></body></html>"};
            emailList.push(e);

        }

        // Send each email
        foreach EmailDetails email in emailList {
            // Send email and capture any error
            error? result = sendEmailSetOfStakeholders(email);
            if (result is error) {
                io:println("Failed to send email to ", email.recipient, ": ", result.message());
            } else {
                io:println("Email sent successfully to ", email.recipient);
            }
        }
    }

}
