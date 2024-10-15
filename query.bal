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

    // sql:ParameterizedQuery query = `SELECT * FROM stakeholders WHERE user_email = ${user_email}`;
    sql:ParameterizedQuery query = `SELECT * FROM stakeholders s JOIN stakeholder_types st ON s.stakeholder_type= st.id WHERE user_email = ${user_email}`;
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

function allQuestionParameterizedQuery(string user_email) returns sql:ParameterizedQuery {
    string email = user_email.toString();

    sql:ParameterizedQuery query = `SELECT * FROM questions WHERE status = '1' AND survey_id IN (SELECT id as survey_id FROM surveys WHERE user_email IN (${email}) and status = '1')`;
    return query;
};


function checkStakeholderParameterizedQuery(string stakeholderEmail, string surveyId, int stakeholderId) returns sql:ParameterizedQuery {
    
    sql:ParameterizedQuery query = `SELECT COUNT(*) AS count, user_email FROM surveys 
                                    WHERE id = ${surveyId.toString()} AND status = 1 AND user_email IN (
                                        SELECT user_email 
                                        FROM stakeholders 
                                        WHERE email_address = ${stakeholderEmail.toString()}
                                    )
                                    AND id NOT IN (
                                        SELECT survey_id 
                                        FROM survey_submissions 
                                        WHERE stakeholder_id = ${stakeholderId} 
                                        AND survey_id = ${surveyId}
                                    )`;
    return query;
}

// Function to get the stakeholder_id using the stakeholder's email
function getStakeholderIdParameterizedQuery(string stakeholderEmail) returns sql:ParameterizedQuery {
    sql:ParameterizedQuery query = `SELECT id FROM stakeholders WHERE email_address = ${stakeholderEmail}`;
    return query;
}

// Function to insert the response into the database
function submitResponseParameterizedQuery(int stakeholderId, int surveyId, int questionId, string responseText) returns sql:ParameterizedQuery {
    sql:ParameterizedQuery query = `INSERT INTO responses (stakeholder_id, survey_id, question_id, response_text)
                                     VALUES (${stakeholderId}, ${surveyId}, ${questionId}, ${responseText})`;

    return query;
}

// Function to insert the survey_submissions into the database
function surveySubmissionParameterizedQuery(int stakeholderId, int surveyId) returns sql:ParameterizedQuery {
    sql:ParameterizedQuery query = `INSERT INTO survey_submissions (stakeholder_id, survey_id)
                                     VALUES (${stakeholderId}, ${surveyId})`;

    return query;
}

