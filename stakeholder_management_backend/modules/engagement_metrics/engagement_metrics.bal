import ballerina/http;

public function getPriorityScore(http:Caller caller, EPSInput epsInput, http:Client metricsAPIClient) returns error? {
    json|error? Eps = calculateEps(metricsAPIClient, epsInput);

    if Eps is json {

        json response = {"EpsResult": Eps};
        check caller->respond(response);

    } else {

        json response = {"error": Eps.message()};
        check caller->respond(response);

    }
}

public function getBalancedScore(http:Caller caller, BSCInput bscInput, http:Client metricsAPIClient) returns error? {
    json|error? Bsc = calculateBsc(metricsAPIClient, bscInput);

    if Bsc is json {

        json response = {"BscResult": Bsc};
        check caller->respond(response);

    } else {

        json response = {"error": Bsc.message()};
        check caller->respond(response);

    }
}

public function getEngagementScore(http:Caller caller, TESInput tesInput, http:Client metricsAPIClient) returns error? {
    json|error? Tsc = calculateTes(metricsAPIClient, tesInput);

    if Tsc is json {

        json response = {"TscResult": Tsc};
        check caller->respond(response);

    } else {

        json response = {"error": Tsc.message()};
        check caller->respond(response);

    }
}
