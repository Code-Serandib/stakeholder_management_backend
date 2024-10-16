import ballerina/sql;
public function stakeholderRegisterParameterizedQuery(Stakeholder stakeholder) returns sql:ParameterizedQuery {
    string stakeholder_name = stakeholder.stakeholder_name;
    int stakeholder_type = stakeholder.stakeholder_type;
    string description = stakeholder.description;
    string email_address = stakeholder.email_address;
    string user_email = stakeholder.user_email;

    sql:ParameterizedQuery query = `INSERT INTO stakeholders  
        (stakeholder_name , stakeholder_type , description , email_address , user_email) VALUES 
        (${stakeholder_name}, ${stakeholder_type}, ${description}, ${email_address}, ${user_email})`;
    return query;
};

public function getAllStakeholderParameterizedQuery(string user_email) returns sql:ParameterizedQuery {
    sql:ParameterizedQuery query = `SELECT * FROM stakeholders s JOIN stakeholder_types st ON s.stakeholder_type= st.id WHERE user_email = ${user_email}`;
    return query;
};

function sortStakeholdersByTypeParameterizedQuery(string type_id, string user_email) returns sql:ParameterizedQuery {
    sql:ParameterizedQuery query = `SELECT * FROM stakeholders WHERE stakeholder_type = ${type_id} and user_email = ${user_email}`;
    return query;
};

function searchStakeholderByEmailParameterizedQuery(string email_address, string user_email) returns sql:ParameterizedQuery {
    string searchEmail = "%" + email_address + "%";
    sql:ParameterizedQuery query = `SELECT * FROM stakeholders WHERE email_address LIKE ${searchEmail} AND user_email = ${user_email}`;
    return query;
};