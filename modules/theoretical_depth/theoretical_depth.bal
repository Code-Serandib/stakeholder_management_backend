import ballerina/http;

public function getAllStakeholdersInfluenceIndex(http:Caller caller, SEmetrics se_metrics, http:Client metricsAPIClient) returns error? {
    json|error? influenceIndex = calculateInfluenceIndex(metricsAPIClient, se_metrics);

    if influenceIndex is json {

        json response = {"influenceIndex": influenceIndex};
        check caller->respond(response);

    } else {

        json response = {"error": influenceIndex.message()};
        check caller->respond(response);

    }
}

public function getNashEquilibrium(http:Caller caller, CustomTable customTable, http:Client metricsAPIClient) returns error? {
    json|error? nashEquilibrium = calculateNashEquilibrium(metricsAPIClient, customTable);

    if nashEquilibrium is json {

        json response = {"nashEquilibrium": nashEquilibrium};
        check caller->respond(response);

    } else {

        json response = {"error": nashEquilibrium.message()};
        check caller->respond(response);

    }
}

public function getSocialExchange(http:Caller caller, StakeholderRelation stakeholderRelation, http:Client metricsAPIClient) returns error? {
    json|error? socialExchange = calculateSocialExchange(metricsAPIClient, stakeholderRelation);

    if socialExchange is json {

        json response = {"socialExchange": socialExchange};
        check caller->respond(response);

    } else {

        json response = {"error": socialExchange.message()};
        check caller->respond(response);

    }
}
