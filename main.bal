import stakeholder_management_backend.engagement_metrics;
import stakeholder_management_backend.meetings;
import stakeholder_management_backend.risk_modeling;
import stakeholder_management_backend.sign_in;
import stakeholder_management_backend.stakeholder_equilibrium;
import stakeholder_management_backend.stakeholder_management;
import stakeholder_management_backend.theoretical_depth;

import ballerina/email;
import ballerina/http;
import ballerina/io;
import ballerina/jwt;
import ballerina/sql;
import ballerinax/java.jdbc;
import ballerinax/mysql.driver as _;
import stakeholder_management_backend.survey;


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
    final email:SmtpClient emailClient;

    function init() returns error? {
        self.metricsAPIClient = check new ("http://localhost:9090/stakeholder-analytics");
        self.dbClient = check new jdbc:Client(jdbcUrl);
        check initDatabase(self.dbClient);

        email:SmtpConfiguration smtpConfig = {
            port: 2525,
            security: email:START_TLS_AUTO
        };

        self.emailClient = check new (SMTP_EMAIL, SMTP_USERNAME, SMTP_PASSWORD, smtpConfig);
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

    // ********************************* Analytical insight **********************************
    // **************************************** START ****************************************

    //risk score
    resource function post risk_score(http:Caller caller, risk_modeling:RiskInput riskInput) returns error? {
        return risk_modeling:getRiskScore(caller, riskInput, self.metricsAPIClient);
    }

    //calculate_project_risk
    resource function post project_risk(http:Caller caller, http:Request req) returns error? {
        return risk_modeling:getProjectRisk(caller, req, self.metricsAPIClient);
    }

    //calculate_project_risk
    resource function post engagement_drop_alert(http:Caller caller, http:Request req) returns error? {
        return risk_modeling:getEngagementDropAlert(caller, req, self.metricsAPIClient);
    }

    //calculate priority score
    resource function post priority_score(http:Caller caller, engagement_metrics:EPSInput epsInput) returns error? {
        return engagement_metrics:getPriorityScore(caller, epsInput, self.metricsAPIClient);
    }

    //calculate balanced score metrics
    resource function post balanced_score(http:Caller caller, engagement_metrics:BSCInput bscInput) returns error? {
        return engagement_metrics:getBalancedScore(caller, bscInput, self.metricsAPIClient);
    }

    //calculate total engament score
    resource function post engagement_score(http:Caller caller, engagement_metrics:TESInput tesInput) returns error? {
        return engagement_metrics:getEngagementScore(caller, tesInput, self.metricsAPIClient);
    }

    //influence_index
    resource function post influence_index_cal(http:Caller caller, theoretical_depth:SEmetrics se_metrics) returns error? {
        return theoretical_depth:getAllStakeholdersInfluenceIndex(caller, se_metrics, self.metricsAPIClient);
    }

    //nashEquilibrium
    resource function post nash_equilibrium_cal(http:Caller caller, theoretical_depth:CustomTable customTable) returns error? {
        return theoretical_depth:getNashEquilibrium(caller, customTable, self.metricsAPIClient);
    }

    //socialExchange
    resource function post social_exchange_cal(http:Caller caller, theoretical_depth:StakeholderRelation stakeholderRelation) returns error? {
        return theoretical_depth:getSocialExchange(caller, stakeholderRelation, self.metricsAPIClient);
    }

    // Calculate SIM
    resource function post calculate_sim(http:Caller caller, http:Request req) returns error? {
        return stakeholder_equilibrium:getSIM(caller, req, self.metricsAPIClient);
    }

    // Calculate DSI
    resource function post calculate_dsi(http:Caller caller, http:Request req) returns error? {
        return stakeholder_equilibrium:getDynamicStakeholderImpact(caller, req, self.metricsAPIClient);
    }

    // Calculate SNS 
    resource function post calculate_sns(http:Caller caller, http:Request req) returns error? {
        return stakeholder_equilibrium:getStakeholderNetworkStability(caller, req, self.metricsAPIClient);
    }

    // Calculate SIS 
    resource function post calculate_sis(http:Caller caller, http:Request req) returns error? {
        return stakeholder_equilibrium:getSystemicInfluenceScore(caller, req, self.metricsAPIClient);
    }
    // ********************************* Analytical insight **********************************
    // ***************************************** END *****************************************

    // ********************************** Meeting Mnagement **********************************
    // **************************************** START ****************************************

    resource function post schedule_meeting(meetings:NewMeeting newMeeting) returns meetings:MeetingCreated|error? {
        meetings:MeetingCreated|error? createdMeeting = meetings:schedule(self.dbClient, newMeeting, self.emailClient);
        return createdMeeting;
    }

    // Get all upcoming meetings
    resource function get upcoming_meetings() returns meetings:MeetingRecord[]|error? {
        meetings:MeetingRecord[] upcomingMeetings = check meetings:getUpcomingMeetings(self.dbClient);
        return upcomingMeetings;
    }

    // Get all meetings
    resource function get all_meetings() returns meetings:MeetingRecord[]|error {
        meetings:MeetingRecord[] upcomingMeetings = check meetings:getAllMeetings(self.dbClient);
        return upcomingMeetings;
    }

    // Get a single meeting by ID
    resource function get meetings/[int id]() returns meetings:MeetingRecord|http:NotFound {
        meetings:MeetingRecord|http:NotFound meetingById = meetings:getMeetingById(id, self.dbClient);
        return meetingById;
    }

    //mark attendance
    resource function post mark_attendance(meetings:AttendaceRecord attendanceRecord) returns error? {
        return meetings:markAttendance(self.dbClient, attendanceRecord);
    }

    // get All attendance
    resource function get attendance/[int meetingId]() returns meetings:Attendace[]|error {
        return meetings:getAttendance(meetingId, self.dbClient);
    }

    resource function get meetingCountByMonth() returns meetings:MeetingCount[]|error {
        meetings:MeetingCount[]|error meetingCountHeldEachMonth = meetings:getMeetingCountHeldEachMonth(self.dbClient);
        return meetingCountHeldEachMonth;
    }

    // Get total meetings count
    resource function get totalMeetingsCount() returns int|error {
        int|error totalMeetingCount = meetings:getTotalMeetingCount(self.dbClient);
        return totalMeetingCount;
    }
    // ********************************** Meeting Mnagement **********************************
    // ***************************************** END *****************************************

    // ********************************** Google Authentication **********************************
    // ****************************************** START ******************************************

    resource function get googleLogin(http:Caller caller, http:Request req) returns error? {
        http:Response redirectResponse = new;
        redirectResponse.setHeader("Location", authorizationUrl);
        redirectResponse.statusCode = http:REDIRECT_FOUND_302;
        check caller->respond(redirectResponse);
    }

    // Callback route to handle Google OAuth2 response
    resource function get callback(http:Caller caller, http:Request req) returns error? {
        string? authCode = req.getQueryParamValue("code");
        return getGoogleAuthValidation(authCode, caller, self.dbClient);
    }

    resource function post getUserDataFromAccessToken(http:Caller caller, http:Request req) returns error? {
        return getUserDataFromAccessToken(caller, req, self.dbClient);
    }

    // Function to handle refreshing the access token using the refresh token
    resource function post refreshToken(http:Caller caller, http:Request req) returns error? {
        return getRefreshToken(caller, req);
    }
    // ********************************** Google Authentication **********************************
    // ******************************************* END *******************************************

    // ********************************** Sign-up ***********************************
    // *********************************** START ************************************

    resource function post signup(http:Caller caller, sign_in:Users users) returns error? {
        sql:ExecutionResult _ = check self.dbClient->execute(sign_in:signupParameterizedQuery(users));
        check caller->respond("Sign up successful");
    }
    // ********************************** Sign-up ***********************************
    // ************************************ END *************************************

    // ******************************** User Profile *********************************
    // *********************************** START *************************************

    resource function post userProfileUpdate(http:Caller caller, sign_in:Users users) returns error? {
        sql:ExecutionResult _ = check self.dbClient->execute(sign_in:updateUserParameterizedQuery(users));
        check caller->respond("Update successful");
    }

    resource function get getUserDetails(string? email) returns sign_in:Users|error {
        return sign_in:getUserDetails(email, self.dbClient);
    }
    // ******************************** User Profile *********************************
    // ************************************ END **************************************

    // **************************** JWT Validation & Sign-in ******************************
    // ************************************** START ***************************************

    resource function post signIn(http:Caller caller, sign_in:SignInInput signInInput) returns error? {
        return sign_in:getSignIn(caller, signInInput, self.dbClient);
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
        return getValidateToken(caller, req);
    }
    // **************************** JWT Validation & Sign-in ******************************
    // ************************************** END ***************************************

    // ********************************** Stakeholder Mnagement **********************************
    // ****************************************** START ******************************************

    // Get total stakeholders count
    resource function get totalStakeholdersCount() returns int|error {
        return stakeholder_management:getTotalStakeholdersCount(self.dbClient);
    }

    resource function post registerStakeholder(http:Caller caller, http:Request req) returns error? {
        return stakeholder_management:getRegisterStakeholder(caller, req, self.dbClient);
    }

    // Fetch all stakeholders for a given user_email
    resource function get getAllStakeholder(string user_email) returns stakeholder_management:Stakeholder[]|error? {
        return stakeholder_management:getAllStakeholders(user_email, self.dbClient);
    }

    resource function get sort(string stakeholder_type, string user_email) returns stakeholder_management:Stakeholder[]|error {
        return stakeholder_management:sortStakeholdersByType(stakeholder_type, user_email, self.dbClient);
    }

    resource function get search(string email_address, string user_email) returns stakeholder_management:Stakeholder[]|error? {
        return stakeholder_management:searchStakeholderByEmail(email_address, user_email, self.dbClient);
    }

    resource function get types() returns stakeholder_management:StakeholderType[]|error {
        return stakeholder_management:getAllStakeholderTypes(self.dbClient);
    }
    // ********************************** Stakeholder Mnagement **********************************
    // ******************************************* END *******************************************

    // ************************************ Survey Mnagement *************************************
    // ****************************************** START ******************************************

    // Create a new survey
    resource function post newSurvey(http:Caller caller, http:Request req) returns error? {
        return survey:getNewSurvey(caller, req, self.dbClient);
    }

    // update a survey
    resource function put updateSurvey(http:Caller caller, http:Request req) returns error? {
        return survey:getUpdateSurvey(caller, req, self.dbClient);
    }

    // Get all surveys
    resource function get allSurveys(string user_email) returns survey:Survey[]|error {
        return survey:getAllSurveys(user_email, self.dbClient);
    }

    // Get survey by ID
    resource function get surveyById(int id) returns survey:Survey|error? {
        return survey:getSurveyById(id, self.dbClient);
    }

    // Delete a survey
    resource function put deleteSurvey(string id) returns error? {
        return survey:putDeleteSurvey(id, self.dbClient);
    }

    // Add a question to a survey
    resource function post addQuestion(http:Request req) returns error? {
        return survey:postAddQuestion(req, self.dbClient);
    }

    // Update Question by ID
    resource function put updateQuestion(http:Caller caller, http:Request req) returns error? {
        return survey:putUpdateQuestion(caller, req, self.dbClient);
    }

    // Get all questions
    resource function get allQuestion(string user_email) returns survey:TransformedQuestion[]|error {
        return survey:getAllQuestion(user_email, self.dbClient);
    }

    resource function get allChoicesByQuestionId(int id) returns survey:Choice[]|error {
        survey:Choice[] listResult = check survey:getChoicesByQuestionId(id, self.dbClient);
        return listResult;
    }

    // Update status to 0 for both the question and its related choices
    resource function put deleteQuestion(http:Request req) returns error? {
        return survey:putDeleteQuestion(req, self.dbClient);
    }

    // Get all responses
    resource function get allResponses() returns survey:TransformedResponse[]|error {
        return survey:getAllResponses(self.dbClient);
    }

    // Get all submissions
    resource function get allSubmissions() returns survey:TransformedSubmission[]|error {
        return survey:getAllSubmissions(self.dbClient);
    }

    resource function get checkStakeholder(http:Caller caller, http:Request req) returns error? {
        return survey:getCheckStakeholder(caller, req, self.dbClient);
    }

    resource function post submitSurvey(http:Caller caller, http:Request req) returns error? {
        return survey:postSubmitSurvey(caller, req, self.dbClient);
    }

//share survey using email
    resource function post share(http:Caller caller, http:Request req) returns error? {
        return survey:postShare(caller, req, self.dbClient);
    }
    // ************************************ Survey Mnagement *************************************
    // ******************************************* END *******************************************

}
