import ballerina/http;
public function calculateInfluenceIndex(http:Client metricsAPIClient, SEmetrics se_metrics) returns json|error{
    json influenceIndexRecord = check metricsAPIClient->/analytics.post(se_metrics);
    return influenceIndexRecord;
}

public function calculateNashEquilibrium(http:Client metricsAPIClient, CustomTable customTable) returns json|error{
    json nashEquilibriumRecord = check metricsAPIClient->/gt_analytics.post(customTable);
    return nashEquilibriumRecord;
}

public function calculateSocialExchange(http:Client metricsAPIClient, StakeholderRelation stakeholderRelation) returns json|error{
    json socialExchangeRecord = check metricsAPIClient->/relationshipValue.post(stakeholderRelation);
    return socialExchangeRecord;
}