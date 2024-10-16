import ballerina/sql;

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
