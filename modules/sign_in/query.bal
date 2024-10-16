import ballerina/sql;
public function getUserData(string email) returns sql:ParameterizedQuery {
    sql:ParameterizedQuery query = `SELECT * FROM users WHERE email=${email}`;
    return query;
};

public function signupParameterizedQuery(Users users) returns sql:ParameterizedQuery {
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

public function updateUserParameterizedQuery(Users users) returns sql:ParameterizedQuery {
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