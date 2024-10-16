import ballerina/sql;

string jdbcUrl = string `${DB_URL}?user=${DB_USERNAME}&password=${DB_PASSWORD}`;

function initDatabase(sql:Client dbClient) returns error? {
    // Create users table if it doesn't exist
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

    // Create meetings table for stakeholder meetings
    _ = check dbClient->execute(`CREATE TABLE IF NOT EXISTS meetings (
                                    id INT AUTO_INCREMENT PRIMARY KEY,
                                    title VARCHAR(100) NOT NULL,
                                    description TEXT,
                                    meeting_date DATE NOT NULL,
                                    meeting_time TIME NOT NULL,
                                    location VARCHAR(100))`);

    // Create a junction table to link meetings and stakeholders (Many-to-Many relationship)
    _ = check dbClient->execute(`CREATE TABLE IF NOT EXISTS meeting_stakeholders (
                                    meeting_id INT NOT NULL,
                                    stakeholder_id INT NOT NULL,
                                    attended BOOLEAN NULL DEFAULT 0,
                                    PRIMARY KEY (meeting_id, stakeholder_id),
                                    FOREIGN KEY (meeting_id) REFERENCES meetings(id) ON DELETE CASCADE,
                                    FOREIGN KEY (stakeholder_id) REFERENCES stakeholders(id) ON DELETE CASCADE
                                )`);

    _ = check dbClient->execute(`CREATE TABLE IF NOT EXISTS surveys (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    status INT DEFAULT 1,
    user_email VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_email) REFERENCES users(email) ON DELETE CASCADE
)`);

    _ = check dbClient->execute(`CREATE TABLE IF NOT EXISTS questions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    survey_id INT NOT NULL,
    question_text TEXT NOT NULL,
    question_type ENUM('text', 'multiple_choice', 'checkbox', 'rating') NOT NULL,
    status INT DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (survey_id) REFERENCES surveys(id) ON DELETE CASCADE
)`);

    _ = check dbClient->execute(`CREATE TABLE IF NOT EXISTS choices (
    id INT AUTO_INCREMENT PRIMARY KEY,
    question_id INT NOT NULL,
    choice_text VARCHAR(255) NOT NULL,
    status INT DEFAULT 1,
    FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE
)`);

    _ = check dbClient->execute(`CREATE TABLE IF NOT EXISTS responses (
    id INT AUTO_INCREMENT PRIMARY KEY,
    stakeholder_id INT,  
    survey_id INT NOT NULL,
    question_id INT NOT NULL,
    response_text TEXT NOT NULL,  -- Stores the actual response
    status INT DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (survey_id) REFERENCES surveys(id) ON DELETE CASCADE,
    FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE,
    FOREIGN KEY (stakeholder_id) REFERENCES stakeholders(id) ON DELETE SET NULL
)`);

    _ = check dbClient->execute(`CREATE TABLE IF NOT EXISTS survey_submissions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    stakeholder_id INT,  -- Optional
    survey_id INT NOT NULL,
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (survey_id) REFERENCES surveys(id) ON DELETE CASCADE,
    FOREIGN KEY (stakeholder_id) REFERENCES stakeholders(id) ON DELETE SET NULL  -- Optional
)`);

    _ = check dbClient->execute(`INSERT IGNORE INTO stakeholder_types (id, type_name) VALUES
	(1, 'user'),
	(2, 'buyer');`);

};
