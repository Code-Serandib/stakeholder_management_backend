import ballerina/http;
import stakeholder_management_backend.risk_modeling;
import ballerina/data.jsondata;
import stakeholder_management_backend.engagement_metrics;

service /api on new http:Listener(9091) {

    final http:Client metricsAPIClient;

    function init() returns error? {
        self.metricsAPIClient = check new("http://localhost:9090/stakeholder-analytics");
    }

    //risk score
    resource function post risk_score(http:Caller caller, risk_modeling:RiskInput riskInput) returns error? {

        json|error? riskScore = risk_modeling:calculateRiskScore(self.metricsAPIClient, riskInput);

        if riskScore is json{

            json response = { "riskScore": riskScore };
            check caller->respond(response);
 
        } else {

            json response = { "error": riskScore.message()};
            check caller->respond(response);

        }
    }

    //calculate_project_risk
    resource function post project_risk(http:Caller caller, http:Request req) returns error? {
        json payload = check req.getJsonPayload();

        risk_modeling:RiskInput[] riskInputs = check jsondata:parseAsType(check payload.riskInputs);
        float[] influences = check jsondata:parseAsType(check payload.influences);

        json|error? projectRisk = risk_modeling:calculateProjectRisk(self.metricsAPIClient, riskInputs, influences);

        if projectRisk is json{

            json response = { "projectRisk": projectRisk };
            check caller->respond(response);
 
        } else {

            json response = { "error": projectRisk.message()};
            check caller->respond(response);

        }
    }

    //calculate_project_risk
    resource function post engagement_drop_alert(http:Caller caller, http:Request req) returns error? {
        json payload = check req.getJsonPayload();

        risk_modeling:RiskInput[] riskInputs = check jsondata:parseAsType(check payload.riskInputs);
        float engamenetTreshold = check payload.Te;

        json|error? engagementDropAlerts = risk_modeling:engagementDropAlert(self.metricsAPIClient, riskInputs, engamenetTreshold);

        if engagementDropAlerts is json{

            json response = { "engagementDropAlerts": engagementDropAlerts };
            check caller->respond(response);
 
        } else {

            json response = { "error": engagementDropAlerts.message()};
            check caller->respond(response);

        }
    }

    //calculate priority score
    resource function post priority_score(http:Caller caller, engagement_metrics:EPSInput epsInput) returns error? {

        json|error? Eps = engagement_metrics:calculateEps(self.metricsAPIClient, epsInput);

        if Eps is json{

            json response = { "EpsResult": Eps };
            check caller->respond(response);
 
        } else {

            json response = { "error": Eps.message()};
            check caller->respond(response);

        }
    }

    //calculate balanced score metrics
    resource function post balanced_score(http:Caller caller, engagement_metrics:BSCInput bscInput) returns error? {

        json|error? Bsc = engagement_metrics:calculateBsc(self.metricsAPIClient, bscInput);

        if Bsc is json{

            json response = { "BscResult": Bsc };
            check caller->respond(response);
 
        } else {

            json response = { "error": Bsc.message()};
            check caller->respond(response);

        }
    }

    //calculate total engament score
    resource function post engagement_score(http:Caller caller, engagement_metrics:TESInput tesInput) returns error? {

        json|error? Tsc = engagement_metrics:calculateTes(self.metricsAPIClient, tesInput);

        if Tsc is json{

            json response = { "TscResult": Tsc };
            check caller->respond(response);
 
        } else {

            json response = { "error": Tsc.message()};
            check caller->respond(response);

        }
    }
}
