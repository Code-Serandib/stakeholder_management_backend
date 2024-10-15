import ballerina/sql;

function signupParameterizedQuery(Users users) returns sql:ParameterizedQuery {
    string organizationName = users.organizationName ?: "";
    string organizationType = users.organizationType ?: "";
    string industry = users.industry ?: "";
    string address = users.address;
    string country = users.country;
    string administratorName = users.administratorName;
    string email = users.email;
    string contactNumber = users.contactNumber ?: "";
    string role = users.role ?: "";
    string username = users.username;
    string password = users.password;

    sql:ParameterizedQuery query = `INSERT INTO users 
        (organizationName, organizationType, industry, address, country, administratorName, email, contactNumber, role, username, password) VALUES 
        (${organizationName}, ${organizationType}, ${industry}, ${address}, ${country}, ${administratorName}, ${email}, ${contactNumber}, ${role}, ${username}, ${password})`;
    return query;
};

function updateUserParameterizedQuery(Users users) returns sql:ParameterizedQuery {
    string organizationName = users.organizationName ?: "";
    string organizationType = users.organizationType ?: "";
    string industry = users.industry ?: "";
    string address = users.address;
    string country = users.country;
    string administratorName = users.administratorName;
    string email = users.email;
    string contactNumber = users.contactNumber ?: "";
    string role = users.role ?: "";

    sql:ParameterizedQuery query = `UPDATE users SET organizationName=${organizationName}, organizationType=${organizationType},
        industry=${industry}, address=${address}, country=${country}, administratorName=${administratorName},
        contactNumber=${contactNumber}, role=${role} WHERE email=${email}`;
    return query;
};

function getUserData(string email) returns sql:ParameterizedQuery {
    sql:ParameterizedQuery query = `SELECT * FROM users WHERE email=${email}`;
    return query;
};

function stakeholderRegisterParameterizedQuery(Stakeholder stakeholder) returns sql:ParameterizedQuery {
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

function getAllStakeholderParameterizedQuery(string user_email) returns sql:ParameterizedQuery {

    sql:ParameterizedQuery query = `SELECT * FROM stakeholders WHERE user_email = ${user_email}`;
    return query;
};

function sortStakeholdersByTypeParameterizedQuery(string type_id, string user_email) returns sql:ParameterizedQuery {

    sql:ParameterizedQuery query = `SELECT * FROM stakeholders WHERE stakeholder_type = ${type_id} and user_email = ${user_email}`;
    return query;
};

function searchStakeholderByEmailParameterizedQuery(string email_address, string user_email) returns sql:ParameterizedQuery {

    string searchEmail = "%" + email_address + "%"; // Concatenate % symbols for the LIKE clause

    sql:ParameterizedQuery query = `SELECT * FROM stakeholders WHERE email_address LIKE ${searchEmail} AND user_email = ${user_email}`;
    return query;
};
