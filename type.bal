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