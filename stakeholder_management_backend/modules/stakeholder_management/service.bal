import ballerina/sql;

public function getAllStakeholders(string user_email, sql:Client dbClient) returns Stakeholder[]|error {
    Stakeholder[] stakeholders = [];
    stream<Stakeholder, sql:Error?> resultStream = dbClient->query(getAllStakeholderParameterizedQuery(user_email));

    check from Stakeholder stakeholder in resultStream
        do {
            stakeholders.push(stakeholder);
        };

    check resultStream.close();
    return stakeholders;
}

public function sortStakeholdersByType(string type_id, string user_email, sql:Client dbClient) returns Stakeholder[]|error {
    Stakeholder[] stakeholders = [];
    stream<Stakeholder, sql:Error?> resultStream = dbClient->query(sortStakeholdersByTypeParameterizedQuery(type_id, user_email));
    check from Stakeholder stakeholder in resultStream
        do {
            stakeholders.push(stakeholder);
        };
    check resultStream.close();
    return stakeholders;
}

public function searchStakeholderByEmail(string email_address, string user_email, sql:Client dbClient) returns Stakeholder[]|error? {
    Stakeholder[] stakeholders = [];
    stream<Stakeholder, sql:Error?> resultStream = dbClient->query(searchStakeholderByEmailParameterizedQuery(email_address, user_email));
    check from Stakeholder stakeholder in resultStream
        do {
            stakeholders.push(stakeholder);
        };
    check resultStream.close();
    return stakeholders;
}

public isolated function getAllStakeholderTypes(sql:Client dbClient) returns StakeholderType[]|error {
    StakeholderType[] types = [];
    stream<StakeholderType, sql:Error?> resultStream = dbClient->query(`SELECT * FROM stakeholder_types`);
    check from StakeholderType typ in resultStream
        do {
            types.push(typ);
        };
    check resultStream.close();
    return types;
}
