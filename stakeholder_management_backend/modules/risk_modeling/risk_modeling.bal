import ballerina/data.jsondata;
import ballerina/http;

public function getRiskScore(http:Caller caller, RiskInput riskInput, http:Client metricsAPIClient) returns error? {
    json|error? riskScore = calculateRiskScore(metricsAPIClient, riskInput);

    if riskScore is json {

        json response = {"riskScore": riskScore};
        check caller->respond(response);

    } else {

        json response = {"error": riskScore.message()};
        check caller->respond(response);

    }
}

public function getProjectRisk(http:Caller caller, http:Request req, http:Client metricsAPIClient) returns error? {
    json payload = check req.getJsonPayload();

    RiskInput[] riskInputs = check jsondata:parseAsType(check payload.riskInputs);
    float[] influences = check jsondata:parseAsType(check payload.influences);

    json|error? projectRisk = calculateProjectRisk(metricsAPIClient, riskInputs, influences);

    if projectRisk is json {

        json response = {"projectRisk": projectRisk};
        check caller->respond(response);

    } else {

        json response = {"error": projectRisk.message()};
        check caller->respond(response);

    }
}

public function getEngagementDropAlert(http:Caller caller, http:Request req, http:Client metricsAPIClient) returns error? {
    json payload = check req.getJsonPayload();

    RiskInput[] riskInputs = check jsondata:parseAsType(check payload.riskInputs);
    float engamenetTreshold = check payload.Te;

    json|error? engagementDropAlerts = engagementDropAlert(metricsAPIClient, riskInputs, engamenetTreshold);

    if engagementDropAlerts is json {

        json response = {"engagementDropAlerts": engagementDropAlerts};
        check caller->respond(response);

    } else {

        json response = {"error": engagementDropAlerts.message()};
        check caller->respond(response);

    }
}
