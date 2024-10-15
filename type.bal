type Users record {|
    string? organizationName;
    string? organizationType;
    string? industry;
    string address;
    string country;
    string administratorName;
    string email;
    string? contactNumber;
    string? role;
    string username;
    string password;
|};

type SignInInput record {|
    string email;
    string password;
|};

type Stakeholder record {
    int id?;
    string stakeholder_name;
    int stakeholder_type;
    string description;
    string email_address;
    string user_email;
};

type StakeholderType record {
    int id;
    string type_name;
};

type Survey record {
int id;
 string title;
 string description;
 };

  
  type Question record {
    int id;
    int survey_id;
    string question_text;
    string question_type;   
};

type Choice record {
    int id;
    int question_id;
    string choice_text; 
};

type AllQuestion record {
    Question question;
    Choice[] choices;
};

type TransformedQuestion record {
    int id;
    int surveyId;
    string questionText;
    string questionType;
    string[] choices?;
};

type Response record {
    int id;
    int stakeholder_id;
    int survey_id;
    int question_id;
    string response_text;
};

type AllResponse record {
    Response response;
    Stakeholder stakeholder;
    Survey survey;
    Question question;
};

type TransformedResponse record {
    int id;
    int stakeholderId;
    int surveyId;
    int questionId;
    string responseText;
};

type Submission record {
    int id;
    int stakeholder_id;
    int survey_id;
    string submitted_at;
};

type AllSubmission record {
    Submission submission;
    Stakeholder stakeholder;
    Survey survey;
};

type TransformedSubmission record {
    int id;
    int stakeholderId;
    int surveyId;
    string stakeholderName;
    string surveyTitle;
    string submittedAt;
};

// Define a record to hold email details
type EmailDetails record {
    string recipient;
    string subject;
    string bodyHtml;
};

