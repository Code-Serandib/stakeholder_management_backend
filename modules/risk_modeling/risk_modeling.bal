import ballerina/http;

public function calculateRiskScore(http:Client metricsAPIClient, RiskInput riskInput) returns json|error{
    json riskRecord = check metricsAPIClient->/calculate_risk_score.post(riskInput);
    return riskRecord;
}

public function calculateProjectRisk(http:Client metricsAPIClient, RiskInput[] riskInputs, float[] influences) returns json|error{
    json projectRisk = check metricsAPIClient->/calculate_project_risk.post({
        "riskInputs" : riskInputs,
        "influences" : influences
    });
    return projectRisk;
}
 
public function engagementDropAlert(http:Client metricsAPIClient, RiskInput[] riskInputs, float engamenetTreshold) returns json|error{
    json dropAlerts = check metricsAPIClient->/engagement_drop_alert.post({
        "riskInputs" : riskInputs,
        "Te" : engamenetTreshold
    });
    return dropAlerts;
}