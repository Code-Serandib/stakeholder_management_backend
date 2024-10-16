import stakeholder_management_backend.stakeholder_management;

import ballerina/http;
import ballerina/sql;

public function getNewSurvey(http:Caller caller, http:Request req, sql:Client dbClient) returns error? {
    json surveyData = check req.getJsonPayload();
    string title = (check surveyData.title).toString();
    string description = (check surveyData.description).toString();
    string user_email = (check surveyData.user_email).toString();

    sql:ExecutionResult _ = check dbClient->execute(`INSERT INTO surveys (title, description,user_email) VALUES (${title}, ${description},${user_email})`);

    check caller->respond({
        statusCode: 200,
        message: "Survey created successfully"
    });

    return;
}

public function getUpdateSurvey(http:Caller caller, http:Request req, sql:Client dbClient) returns error? {
    json surveyData = check req.getJsonPayload();
    string title = check surveyData.title;
    string description = check surveyData.description;
    string id = (check surveyData.id).toString();

    sql:ExecutionResult _ = check dbClient->execute(`UPDATE surveys 
        SET title = ${title}, description = ${description}
        WHERE id=${id}`);

    check caller->respond({
        statusCode: 204,
        message: "Survey updated successfully"
    });

    return;
}

public function getAllSurveys(string user_email, sql:Client dbClient) returns Survey[]|error {
    Survey[] surveys = [];
    sql:ParameterizedQuery query = `SELECT * FROM surveys WHERE status = '1' AND user_email=${user_email}`;
    stream<Survey, sql:Error?> resultStream = dbClient->query(query);

    check from Survey survey in resultStream
        do {
            surveys.push(survey);
        };

    check resultStream.close();
    return surveys;
}

public function getSurveyById(int id, sql:Client dbClient) returns Survey|error? {
    sql:ParameterizedQuery query = `SELECT * FROM surveys WHERE id = ${id}`;
    stream<record {|int id; string title; string description;|}, sql:Error?> resultStream = dbClient->query(query);

    var result = resultStream.next();
    if result is record {|Survey value;|} {
        Survey survey = result.value;
        check resultStream.close();
        return survey;
    } else {
        check resultStream.close();
        json errorResponse = {message: "Survey not found"};
        http:Response response = new;
        response.statusCode = 404;
        response.setJsonPayload(errorResponse);
        return error("Survey not found");
    }
}

public function putDeleteSurvey(string id, sql:Client dbClient) returns error? {
    sql:ExecutionResult result = check dbClient->execute(`UPDATE surveys 
        SET status = 0 WHERE id=${id}`);
    if (result.affectedRowCount == 0) {
        return error("Survey not found");
    }
    return;
}

public function postAddQuestion(http:Request req, sql:Client dbClient) returns error? {
    json questionData = check req.getJsonPayload();
    int surveyId = <int>(check questionData.surveyId);
    string questionText = (check questionData.questionText).toString();
    string questionType = (check questionData.questionType).toString();
    json[] choices = <json[]>(check questionData.choices);

    sql:ParameterizedQuery query = `INSERT INTO questions (survey_id, question_text, question_type) VALUES (${surveyId}, ${questionText}, ${questionType})`;
    sql:ExecutionResult result = check dbClient->execute(query);

    int|string? lastInsertId = result.lastInsertId;

    if lastInsertId is int {
        // io:println("Last Inserted ID: ", lastInsertId);

        if (questionType == "multiple_choice" || questionType == "checkbox" || questionType == "rating") {
            foreach var choice in choices {
                sql:ParameterizedQuery choiceQuery = `INSERT INTO choices (question_id, choice_text)
                                                  VALUES (${lastInsertId}, ${choice.toString()})`;
                _ = check dbClient->execute(choiceQuery);
            }
        }
    } else {
        // io:println("Unable to obtain last insert ID");

    }
    return;
}

public function putUpdateQuestion(http:Caller caller, http:Request req, sql:Client dbClient) returns error? {
    json questionData = check req.getJsonPayload();
    int id = <int>(check questionData.id);
    int surveyId = <int>(check questionData.surveyId);
    string questionText = (check questionData.questionText).toString();
    string questionType = (check questionData.questionType).toString();
    json[] choices = <json[]>(check questionData.choices);

    sql:ParameterizedQuery query = `UPDATE questions 
                                        SET survey_id = ${surveyId}, 
                                            question_text = ${questionText}, 
                                            question_type = ${questionType} 
                                        WHERE id = ${id}`;
    _ = check dbClient->execute(query);

    if (questionType == "multiple_choice" || questionType == "checkbox" || questionType == "rating") {
        sql:ParameterizedQuery deleteQuery = `DELETE FROM choices WHERE question_id = ${id}`;
        _ = check dbClient->execute(deleteQuery);

        foreach var choice in choices {
            sql:ParameterizedQuery choiceQuery = `INSERT INTO choices (question_id, choice_text)
                                                      VALUES (${id}, ${choice.toString()})`;
            _ = check dbClient->execute(choiceQuery);
        }
    }

    check caller->respond({
        statusCode: 204,
        message: "Question updated successfully"
    });

    return;
}

public function getAllQuestion(string user_email, sql:Client dbClient) returns TransformedQuestion[]|error {
    AllQuestion[] allQuestions = [];

    stream<Question, sql:Error?> resultStream = dbClient->query(allQuestionParameterizedQuery(user_email));
    check from Question question in resultStream
        do {

            Choice[] choicesByQuestionId = check getChoicesByQuestionId(question.id, dbClient);

            AllQuestion allQuestion = {
                question: question,
                choices: choicesByQuestionId
            };
            allQuestions.push(allQuestion);
        };
    check resultStream.close();
    TransformedQuestion[] transformedQuestions = transformQuestions(allQuestions);

    return transformedQuestions;
}

public function putDeleteQuestion(http:Request req, sql:Client dbClient) returns error? {
    json requestBody = check req.getJsonPayload();
    string id = (check requestBody.id).toString();

    sql:ExecutionResult _ = check dbClient->execute(`UPDATE choices 
        SET status = 0 WHERE question_id=${id}`);

    sql:ExecutionResult questionResult = check dbClient->execute(`UPDATE questions 
        SET status = 0 WHERE id=${id}`);

    if (questionResult.affectedRowCount == 0) {
        return error("Question not found");
    }

    return;
}

public function getAllResponses(sql:Client dbClient) returns TransformedResponse[]|error {
    AllResponse[] allResponses = [];

    sql:ParameterizedQuery query = `SELECT * FROM responses`;
    stream<Response, sql:Error?> resultStream = dbClient->query(query);

    check from Response response in resultStream
        do {
            sql:ParameterizedQuery stakeholderQuery = `SELECT * FROM stakeholders WHERE id = ${response.stakeholder_id}`;
            stakeholder_management:Stakeholder? stakeholder = check dbClient->queryRow(stakeholderQuery);

            sql:ParameterizedQuery surveyQuery = `SELECT * FROM surveys WHERE id = ${response.survey_id}`;
            Survey? survey = check dbClient->queryRow(surveyQuery);

            sql:ParameterizedQuery questionQuery = `SELECT * FROM questions WHERE id = ${response.question_id}`;
            Question? question = check dbClient->queryRow(questionQuery);

            if (stakeholder is stakeholder_management:Stakeholder && survey is Survey && question is Question) {
                AllResponse allResponse = {
                    response: response,
                    stakeholder: stakeholder,
                    survey: survey,
                    question: question
                };

                allResponses.push(allResponse);
            }
        };

    check resultStream.close();
    TransformedResponse[] transformedResponses = transformResponses(allResponses);

    return transformedResponses;
}

public function getAllSubmissions(sql:Client dbClient) returns TransformedSubmission[]|error {
    AllSubmission[] allSubmissions = [];

    sql:ParameterizedQuery query = `SELECT * FROM survey_submissions`;
    stream<Submission, sql:Error?> resultStream = dbClient->query(query);

    record {|Submission value;|}? nextSubmission = check resultStream.next();

    while nextSubmission is record {|Submission value;|} {
        Submission submission = nextSubmission.value;

        sql:ParameterizedQuery stakeholderQuery = `SELECT * FROM stakeholders WHERE id = ${submission.stakeholder_id}`;
        stakeholder_management:Stakeholder? stakeholder = check dbClient->queryRow(stakeholderQuery);

        sql:ParameterizedQuery surveyQuery = `SELECT * FROM surveys WHERE id = ${submission.survey_id}`;
        Survey? survey = check dbClient->queryRow(surveyQuery);

        if (stakeholder is stakeholder_management:Stakeholder && survey is Survey) {
            AllSubmission allSubmission = {
                submission: submission,
                stakeholder: stakeholder,
                survey: survey
            };
            allSubmissions.push(allSubmission);
        }
        nextSubmission = check resultStream.next();
    }
    check resultStream.close();
    TransformedSubmission[] transformedSubmissions = transformSubmissions(allSubmissions);

    return transformedSubmissions;
}

public function getCheckStakeholder(http:Caller caller, http:Request req, sql:Client dbClient) returns error? {
    string? stakeholderEmail = req.getQueryParamValue("stakeholderemail");
    string? surveyId = req.getQueryParamValue("surveyid");

    if stakeholderEmail is () || surveyId is () {
        check caller->respond({
            statusCode: http:STATUS_BAD_REQUEST,
            message: "Missing stakeholder email or survey ID"
        });
        return;
    }

    sql:ParameterizedQuery parameterizedQuery = getStakeholderIdParameterizedQuery(<string>stakeholderEmail);
    int? stakeholderId = check dbClient->queryRow(parameterizedQuery);

    if stakeholderId is () {
        check caller->respond({
            statusCode: http:STATUS_BAD_REQUEST,
            message: "Stakeholder not found"
        });
        return;
    }

    stream<record {|int count; string? user_email;|}, sql:Error?> resultStream = dbClient->query(
        checkStakeholderParameterizedQuery(stakeholderEmail, surveyId, <int>stakeholderId)
        );

    record {|record {|int count; string? user_email;|} value;|}|sql:Error? result = resultStream.next();

    if result is error {
        // io:println(result);
        check caller->respond({
            statusCode: http:STATUS_INTERNAL_SERVER_ERROR,
            message: "Database query failed"
        });
        return;
    }

    if result is () || result.value.count == 0 {
        // io:println(result);
        check caller->respond({
            statusCode: http:STATUS_FORBIDDEN,
            message: "Invalid stakeholder or survey, or you already submitted"
        });
        return;
    }

    string? userEmail = result.value.user_email;
    check caller->respond({"message": "Valid stakeholder and survey", "email": userEmail ?: "No email found"});
}

public function postSubmitSurvey(http:Caller caller, http:Request req, sql:Client dbClient) returns error? {
    json requestBody = check req.getJsonPayload();
    string stakeholderEmail = (check requestBody.stakeholderEmail).toString();
    int surveyId = <int>check requestBody.surveyId;
    json responses = check requestBody.responses;

    sql:ParameterizedQuery parameterizedQuery = getStakeholderIdParameterizedQuery(stakeholderEmail);
    int? stakeholderId = check dbClient->queryRow(parameterizedQuery);

    if stakeholderId is () {
        http:Response res = new;
        res.statusCode = 404;
        res.setPayload({message: "Stakeholder not found for email: " + stakeholderEmail});
        check caller->respond(res);
        return;
    }

    sql:ParameterizedQuery surveySubmissionParameterizedQueryResult = surveySubmissionParameterizedQuery(stakeholderId, surveyId);
    _ = check dbClient->execute(surveySubmissionParameterizedQueryResult);

    if responses is map<anydata> {
        foreach var [questionIdStr, response] in responses.entries() {
            int qId = check 'int:fromString(questionIdStr);

            if response is json[] {
                foreach var choice in response {
                    string choiceValue = choice.toString();
                    sql:ParameterizedQuery parameterizedQueryResult = submitResponseParameterizedQuery(stakeholderId, surveyId, qId, choiceValue);
                    _ = check dbClient->execute(parameterizedQueryResult);
                }
            } else {
                string responseValue = response.toString();
                sql:ParameterizedQuery parameterizedQueryResult = submitResponseParameterizedQuery(stakeholderId, surveyId, qId, responseValue);
                _ = check dbClient->execute(parameterizedQueryResult);
            }
        }
    }

    http:Response res = new;
    res.setPayload({message: "Survey responses submitted successfully"});
    check caller->respond(res);
}

public function postShare(http:Caller caller, http:Request req, sql:Client dbClient) returns error? {
    json|error payload = req.getJsonPayload();

    if (payload is json) {
        // Extract survey title and selected stakeholder types from the payload
        string surveyId = (check payload.surveyId).toString();
        string surveyTitle = (check payload.surveyTitle).toString();
        string user_email = (check payload.user_email).toString();
        json[] selectedTypes = <json[]>(check payload.selectedTypes);

        string stringResult = selectedTypes.toString();

        // Convert the array to a string and remove the brackets
        string formattedString = stringResult.toString().substring(1, stringResult.toString().length() - 1);

        // Remove quotation marks manually
        string finalString = "";
        byte[] byteArray = string:toBytes(formattedString);
        foreach byte b in byteArray {
            if (b != 34) { // ASCII value of double quote is 34
                finalString += check string:fromBytes([b]);
            }
        }

        // Fetch stakeholders based on types
        stakeholder_management:Stakeholder[] stakeholders = check getStakeholdersByType(selectedTypes, user_email, dbClient);

        // Send the survey to the selected stakeholders
        check sendSurveyToStakeholders(surveyTitle, stakeholders, surveyId);

        // Send a response back to the frontend
        json response = {
            message: "Survey shared successfully with " + stakeholders.length().toString() + " stakeholders."
        };
        check caller->respond(response);
    } else {
        check caller->respond({message: "Invalid payload"});
    }

}

// Function to fetch stakeholders by type
public function getStakeholdersByType(json[] types, string user_email, sql:Client dbClient) returns stakeholder_management:Stakeholder[]|error {
    stakeholder_management:Stakeholder[] stakeholders = [];

    // Iterate over each element in the json array
    foreach var typ in types {
        // Ensure the element is a string before processing
        if (typ is string) {
            // Prepare SQL query to fetch stakeholders by types
            sql:ParameterizedQuery query = `SELECT * FROM stakeholders WHERE 
    stakeholder_type IN (SELECT id FROM stakeholder_types WHERE type_name = ${typ.toString()}) 
    AND user_email = ${user_email.toString()}`;

            stream<stakeholder_management:Stakeholder, sql:Error?> resultStream = dbClient->query(query);
            // Collect results from stream
            check from stakeholder_management:Stakeholder stakeholder in resultStream
                do {
                    stakeholders.push(stakeholder);
                };
        } else {
            // io:println("Invalid type found in array");
        }
    }

    return stakeholders;
}

// Function to send survey emails to stakeholders
public function sendSurveyToStakeholders(string surveyTitle, stakeholder_management:Stakeholder[] stakeholders, string surveyId) returns error? {
    EmailDetails[] emailList = [];
    foreach stakeholder_management:Stakeholder stakeholder in stakeholders {

        string generateSurveyLink = "http://localhost:3000/survey/view?stakeholderemail=" + stakeholder.email_address + "&surveyid=" + surveyId + "";

        EmailDetails e = {recipient: stakeholder.email_address, subject: surveyTitle, bodyHtml: "<!DOCTYPE html><html lang=en><head><meta charset=UTF-8><meta name=viewport content=width=device-width,initial-scale=1.0><style>body{font-family:Arial,sans-serif;background-color:#f4f4f4;margin:0;padding:20px}.email-container{background-color:#ffffff;padding:20px;border-radius:8px;box-shadow:0 2px 4px rgba(0,0,0,0.1);max-width:600px;margin:auto}h2{color:#333333}p{color:#555555}.survey-button{display:inline-block;background-color:#28a745;color:#ffffff;padding:12px 20px;border-radius:5px;text-decoration:none;font-weight:bold}.survey-button:hover{background-color:#218838}</style><title>New Survey Available</title></head><body><div class=email-container><h2>New Survey Available</h2><p>Hello,</p><p>We are excited to inform you that a new survey is now available for you to participate in.</p><p>Please click the button below to access the survey:</p><a href='" + generateSurveyLink + "' class=survey-button>Take the Survey</a><p>Thank you for your time and feedback!</p></div></body></html>"};
        emailList.push(e);

    }

    // Send each email
    foreach EmailDetails email in emailList {
        // Send email and capture any error
        error? result = sendEmailSetOfStakeholders(email);
        if (result is error) {
            // io:println("Failed to send email to ", email.recipient, ": ", result.message());
        } else {
            // io:println("Email sent successfully to ", email.recipient);
        }
    }
}


public  function getAllSubmissionsBySurveyId(string surveyId, sql:Client dbClient) returns SubmissionCount[]|error {
    SubmissionCount[] submissions = [];


    // Query to get all submissions
    sql:ParameterizedQuery query = `SELECT COUNT(*) AS count, DATE(submitted_at) AS submitted_at FROM survey_submissions WHERE survey_id= ${surveyId} GROUP BY DATE(submitted_at)`;
    stream<SubmissionCount, sql:Error?> resultStream = dbClient->query(query);

    // Iterate over the stream to fetch each submission
    record {| SubmissionCount value; |}? nextSubmission = check resultStream.next();
    
    while nextSubmission is record {| SubmissionCount value; |} {
        SubmissionCount submission = nextSubmission.value;

                // Push the submission and its related data to the final list
                submissions.push(submission);

            // Fetch the next submission in the stream
            nextSubmission = check resultStream.next();
        }

        // Close the result stream for submissions
        check resultStream.close();

        // io:println(submissions);

        return submissions;
    }