import ballerina/http;

public function calculateSIM(http:Client metricsAPIClient, Stakeholder[] stakeholders) returns json|error {
    // Make the POST request to the /calculate_sim endpoint
    json simResponse = check metricsAPIClient->/calculate_sim.post({
        "stakeholders": stakeholders
    });
    return simResponse;
}

public function calculateDynamicStakeholderImpact(http:Client metricsAPIClient, Stakeholder[] stakeholders, float[] deltaBehavior) returns json|error {
    json dsiResult = check metricsAPIClient->/calculate_dsi.post({
        "stakeholders": stakeholders,
        "deltaBehavior": deltaBehavior
    });
    return dsiResult;
}

public function calculateStakeholderNetworkStability(http:Client metricsAPIClient, Stakeholder[] stakeholders, float[] deltaBehavior) returns json|error {
    json snsResult = check metricsAPIClient->/calculate_sns.post({
        "stakeholders": stakeholders,
        "deltaBehavior": deltaBehavior
    });
    return snsResult;
}

public function calculateSystemicInfluenceScore(http:Client metricsAPIClient, Stakeholder[] stakeholders) returns json|error {
    json sisResult = check metricsAPIClient->/calculate_sis.post({
        "stakeholders": stakeholders
    });
    return sisResult;
}




