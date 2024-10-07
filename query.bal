import ballerina/sql;

function stakeholderRegisterParameterizedQuery(Stakeholder stakeholder) returns sql:ParameterizedQuery {
    string stakeholder_name = stakeholder.stakeholder_name;
    int stakeholder_type =  stakeholder.stakeholder_type;
    string description = stakeholder.description;
    string email_address = stakeholder.email_address;
    string user_email = stakeholder.user_email;

    sql:ParameterizedQuery query = `INSERT INTO stakeholders  
        (stakeholder_name , stakeholder_type , description , email_address , user_email) VALUES 
        (${stakeholder_name}, ${stakeholder_type}, ${description}, ${email_address}, ${user_email})`;
    return query;
};

function getAllStakeholderParameterizedQuery(string user_email) returns sql:ParameterizedQuery {

    sql:ParameterizedQuery query = `SELECT * FROM stakeholders WHERE user_email = ${user_email}`;
    return query;
};