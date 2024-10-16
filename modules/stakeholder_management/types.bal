public type Stakeholder record {
    int id?;
    string stakeholder_name;
    int stakeholder_type;
    string description;
    string email_address;
    string user_email;
};

public type StakeholderType record {
    int id;
    string type_name;
};