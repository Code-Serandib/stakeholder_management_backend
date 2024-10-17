import ballerina/data.jsondata;
import ballerina/http;

public function getSIM(http:Caller caller, http:Request req, http:Client metricsAPIClient) returns error? {
    json payload = check req.getJsonPayload();

    Stakeholder[] stakeholders = check jsondata:parseAsType(check payload.stakeholders);
    json|error? simResponse = calculateSIM(metricsAPIClient, stakeholders);

    if simResponse is json {
        json response = {"Stakeholder Influence Matrix (SIM)": simResponse};
        check caller->respond(response);
    } else {
        json response = {"error": simResponse.message()};
        check caller->respond(response);
    }
}

public function getDynamicStakeholderImpact(http:Caller caller, http:Request req, http:Client metricsAPIClient) returns error? {
    json payload = check req.getJsonPayload();

    Stakeholder[] stakeholders = check jsondata:parseAsType(check payload.stakeholders);
    float[] deltaBehavior = check jsondata:parseAsType(check payload.deltaBehavior);

    json|error? dsiResult = calculateDynamicStakeholderImpact(metricsAPIClient, stakeholders, deltaBehavior);

    if dsiResult is json {
        json response = {"Dynamic Stakeholder Impact (DSI)": dsiResult};
        check caller->respond(response);
    } else {
        json response = {"error": dsiResult.message()};
        check caller->respond(response);
    }
}

public function getStakeholderNetworkStability(http:Caller caller, http:Request req, http:Client metricsAPIClient) returns error? {
    json payload = check req.getJsonPayload();

    Stakeholder[] stakeholders = check jsondata:parseAsType(check payload.stakeholders);
    float[] deltaBehavior = check jsondata:parseAsType(check payload.deltaBehavior);

    json|error? snsResult = calculateStakeholderNetworkStability(metricsAPIClient, stakeholders, deltaBehavior);

    if snsResult is json {
        json response = {"Stakeholder Network Stability (SNS)": snsResult};
        check caller->respond(response);
    } else {
        json response = {"error": snsResult.message()};
        check caller->respond(response);
    }
}

public function getSystemicInfluenceScore(http:Caller caller, http:Request req, http:Client metricsAPIClient) returns error? {
    json payload = check req.getJsonPayload();

    Stakeholder[] stakeholders = check jsondata:parseAsType(check payload.stakeholders);

    json|error? sisResult = calculateSystemicInfluenceScore(metricsAPIClient, stakeholders);

    if sisResult is json {
        json response = {"Systemic Influence Score (SIS)": sisResult};
        check caller->respond(response);
    } else {
        json response = {"error": sisResult.message()};
        check caller->respond(response);
    }
}

