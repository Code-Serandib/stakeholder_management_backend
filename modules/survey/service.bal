import ballerina/sql;

public function getChoicesByQuestionId(int id, sql:Client dbClient) returns Choice[]|error {
    Choice[]? choices = null;
    sql:ParameterizedQuery query1 = `SELECT * FROM choices WHERE question_id = ${id} AND status = '1'`;
    stream<Choice, sql:Error?> resultStream1 = dbClient->query(query1);

    check from Choice choice in resultStream1
        do {
            if (choices is null) {
                choices = [];
            }
            (<Choice[]>choices).push(choice);
        };
    check resultStream1.close();

    if (choices is null) {
        choices = [];
    }

    return <Choice[]>choices;
}

public function transformQuestions(AllQuestion[] allQuestions) returns TransformedQuestion[] {
    TransformedQuestion[] transformedQuestions = [];

    foreach var item in allQuestions {
        TransformedQuestion transformedQuestion = {
            id: item.question.id,
            surveyId: item.question.survey_id,
            questionText: item.question.question_text,
            questionType: item.question.question_type,
            choices: from var choice in item.choices
                select choice.choice_text
        };

        transformedQuestions.push(transformedQuestion);
    }

    return transformedQuestions;
}

public function transformResponses(AllResponse[] allResponses) returns TransformedResponse[] {
    TransformedResponse[] transformedResponses = [];

    foreach var item in allResponses {
        TransformedResponse transformedResponse = {
            id: item.response.id,
            stakeholderId: item.response.stakeholder_id,
            surveyId: item.response.survey_id,
            questionId: item.response.question_id,
            responseText: item.response.response_text
        };

        transformedResponses.push(transformedResponse);
    }

    return transformedResponses;
}

public function transformSubmissions(AllSubmission[] allSubmissions) returns TransformedSubmission[] {
    TransformedSubmission[] transformedSubmissions = [];

    foreach var item in allSubmissions {
        TransformedSubmission transformedSubmission = {
            id: item.submission.id,
            stakeholderId: item.submission.stakeholder_id,
            surveyId: item.submission.survey_id,
            stakeholderName: item.stakeholder.stakeholder_name,
            surveyTitle: item.survey.title,
            submittedAt: item.submission.submitted_at
        };

        transformedSubmissions.push(transformedSubmission);
    }

    return transformedSubmissions;
}
