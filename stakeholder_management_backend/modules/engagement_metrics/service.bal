import ballerina/http;
public function calculateEps(http:Client metricsAPIClient, EPSInput epsInput) returns json|error{
    json epsRecord = check metricsAPIClient->/calculate_eps.post(epsInput);
    return epsRecord;
}

public function calculateBsc(http:Client metricsAPIClient, BSCInput bscInput) returns json|error{
    json bscRecord = check metricsAPIClient->/calculate_bsc.post(bscInput);
    return bscRecord;
}

public function calculateTes(http:Client metricsAPIClient, TESInput tesInput) returns json|error{
    json tesRecord = check metricsAPIClient->/calculate_tes.post(tesInput);
    return tesRecord;
}