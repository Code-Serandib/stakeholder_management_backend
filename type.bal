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