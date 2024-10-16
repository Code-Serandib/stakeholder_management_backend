import stakeholder_management_backend.stakeholder_management;
public type Survey record {
    int id;
    string title;
    string description;
};

public type Question record {
    int id;
    int survey_id;
    string question_text;
    string question_type;   
};

public type Choice record {
    int id;
    int question_id;
    string choice_text; 
};

public type AllQuestion record {
    Question question;
    Choice[] choices;
};

public type TransformedQuestion record {
    int id;
    int surveyId;
    string questionText;
    string questionType;
    string[] choices?;
};

public type Response record {
    int id;
    int stakeholder_id;
    int survey_id;
    int question_id;
    string response_text;
};

public type AllResponse record {
    Response response;
    stakeholder_management:Stakeholder stakeholder;
    Survey survey;
    Question question;
};

public type TransformedResponse record {
    int id;
    int stakeholderId;
    int surveyId;
    int questionId;
    string responseText;
};

public type TransformedSubmission record {
    int id;
    int stakeholderId;
    int surveyId;
    string stakeholderName;
    string surveyTitle;
    string submittedAt;
};

public type Submission record {
    int id;
    int stakeholder_id;
    int survey_id;
    string submitted_at;
};

public type AllSubmission record {
    Submission submission;
    stakeholder_management:Stakeholder stakeholder;
    Survey survey;
};

// Define a record to hold email details
public type EmailDetails record {
    string recipient;
    string subject;
    string bodyHtml;
};