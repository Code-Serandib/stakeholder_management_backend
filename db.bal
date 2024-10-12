import ballerina/sql;
// OAuth2 Configuration
configurable string CLIENT_ID = ?;
configurable string CLIENT_SECRET = ?;
configurable string REDIRECT_URI = "http://localhost:3000/sign-in";
configurable string TOKEN_URL = "https://oauth2.googleapis.com/token";
configurable string AUTH_URL = "https://accounts.google.com/o/oauth2/auth";
// configurable string SCOPE = "https://www.googleapis.com/auth/userinfo.email";
configurable string SCOPE = "https://www.googleapis.com/auth/userinfo.profile https://www.googleapis.com/auth/userinfo.email";
configurable string DB_URL = ?;
configurable string DB_USERNAME = ?;
configurable string DB_PASSWORD = ?;

string jdbcUrl = string `${DB_URL}?user=${DB_USERNAME}&password=${DB_PASSWORD}`;

function initDatabase(sql:Client dbClient) returns error? {
    _ = check dbClient->execute(`CREATE TABLE IF NOT EXISTS users (
                                    username VARCHAR(50) NOT NULL,
                                    password VARCHAR(100) NOT NULL,
                                    email VARCHAR(100) PRIMARY KEY NOT NULL,
                                    organizationName VARCHAR(70),
                                    organizationType VARCHAR(50),
                                    industry VARCHAR(50),
                                    address VARCHAR(100),
                                    country VARCHAR(40),
                                    administratorName VARCHAR(50),
                                    contactNumber VARCHAR(10),
                                    role VARCHAR(40),
                                    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP)`);

    _ = check dbClient->execute(`CREATE TABLE IF NOT EXISTS stakeholder_types (
                                    id INT AUTO_INCREMENT PRIMARY KEY,
                                    type_name VARCHAR(50) NOT NULL
                                )`);

    _ = check dbClient->execute(`CREATE TABLE IF NOT EXISTS stakeholders (
                                    id INT AUTO_INCREMENT PRIMARY KEY,
                                    stakeholder_name VARCHAR(255) NOT NULL,
                                    stakeholder_type INT,
                                    description TEXT,
                                    email_address VARCHAR(255) NOT NULL,
                                    user_email VARCHAR(100),
                                    FOREIGN KEY (stakeholder_type) REFERENCES stakeholder_types(id),
                                    FOREIGN KEY (user_email) REFERENCES users(email)
)`);

    
};