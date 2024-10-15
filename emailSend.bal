import ballerina/email;
import ballerina/io;

// Function to send an email
 function sendEmailSetOfStakeholders(EmailDetails emailDetails) returns error? {

    // Configure SMTP settings
    email:SmtpConfiguration smtpConfig = {
        port: 587, // Specify the port number
        security: email:START_TLS_AUTO // Specify security type
    };

    // Create the SMTP client
    email:SmtpClient smtpClient = check new email:SmtpClient(
        host = "smtp.gmail.com", // Use Gmail's SMTP server
        username = "from@gmail.com", // Your email
        password = "abcc cccc cccc cccc", // Your email password (consider using an app password)
        clientConfig = smtpConfig
    );

    // Create the email message
    email:Message emailMessage = {
        'from: "from@gmail.com", // Your email address
        to: [emailDetails.recipient],
        subject: emailDetails.subject,
        htmlBody: emailDetails.bodyHtml
    };

    // Send the email
    check smtpClient->sendMessage(emailMessage);
}

// Main function to send emails to multiple recipients
// public function main() returns error? {
//     // Define a list of email details
//     EmailDetails[] emailList = [
//         {recipient: "manula1@gmail.com", subject: "Subject 1", bodyHtml: "<!DOCTYPE html><html lang=en><head><meta charset=UTF-8><meta name=viewport content='width=device-width, initial-scale=1.0'><title>Simple HTML Page</title><style>body{font-family:Arial,sans-serif;margin:20px;}h1{color:#333;}p{font-size:16px;color:#555;}button{padding:10px 15px;background-color:#007BFF;color:white;border:none;border-radius:5px;cursor:pointer;}button:hover{background-color:#0056b3;}</style></head><body><h1>Welcome to My Simple HTML Page</h1><p>This is a simple example of an HTML page with a header, a paragraph, and a button.</p><button onclick=alert('Button Clicked!')>Click Me</button></body></html>"},
//         {recipient: "manula2@gmail.com", subject: "Subject 2", bodyHtml: "<!DOCTYPE html><html lang=en><head><meta charset=UTF-8><meta name=viewport content='width=device-width, initial-scale=1.0'><title>Simple HTML Page</title><style>body{font-family:Arial,sans-serif;margin:20px;}h1{color:#333;}p{font-size:16px;color:#555;}button{padding:10px 15px;background-color:#007BFF;color:white;border:none;border-radius:5px;cursor:pointer;}button:hover{background-color:#0056b3;}</style></head><body><h1>Welcome to My Simple HTML Page</h1><p>This is a simple example of an HTML page with a header, a paragraph, and a button.</p><button onclick=alert('Button Clicked!')>Click Me</button></body></html>"},
//         {recipient: "manula3@gmail.com", subject: "Subject 3", bodyHtml: "<!DOCTYPE html><html lang=en><head><meta charset=UTF-8><meta name=viewport content='width=device-width, initial-scale=1.0'><title>Simple HTML Page</title><style>body{font-family:Arial,sans-serif;margin:20px;}h1{color:#333;}p{font-size:16px;color:#555;}button{padding:10px 15px;background-color:#007BFF;color:white;border:none;border-radius:5px;cursor:pointer;}button:hover{background-color:#0056b3;}</style></head><body><h1>Welcome to My Simple HTML Page</h1><p>This is a simple example of an HTML page with a header, a paragraph, and a button.</p><button onclick=alert('Button Clicked!')>Click Me</button></body></html>"}
//     ];
    
//     // Send each email
//     foreach EmailDetails email in emailList {
//         // Send email and capture any error
//         error? result = sendEmailSetOfStakeholders(email);
//         if (result is error) {
//             io:println("Failed to send email to ", email.recipient, ": ", result.message());
//         } else {
//             io:println("Email sent successfully to ", email.recipient);
//         }
//     }
// }


// Function to send an email
function sendEmailToStakeholder(string recipientEmail, string subject, string messageBody) returns error? {
    // Create an SMTP client with the configuration
    email:SmtpClient smtpClient = check new (host = "smtp.gmail.com",
        port = 465,
        username = "your@gmail.com", // Your email
        password = "cccc cccc cccc cccc",    // App password or SMTP server password
        security = email:SSL
        // auth = true,
    );

    // Define the email message
    email:Message emailMessage = {
        'from: "your@gmail.com",
        to: recipientEmail,
        subject: subject,
        htmlBody: messageBody
    };

    // Send the email
    check smtpClient->sendMessage(emailMessage);
    io:println("Email sent successfully to " + recipientEmail);
}

// Example usage
// public function main() returns error? {
//     string stakeholderEmail = "manula@gmail.com"; // Replace with the stakeholder's email
//     string subject = "Survey Reminder";
//     string messageBody = "<!DOCTYPE html><html lang=en><head><meta charset=UTF-8><meta name=viewport content='width=device-width, initial-scale=1.0'><title>Simple HTML Page</title><style>body{font-family:Arial,sans-serif;margin:20px;}h1{color:#333;}p{font-size:16px;color:#555;}button{padding:10px 15px;background-color:#007BFF;color:white;border:none;border-radius:5px;cursor:pointer;}button:hover{background-color:#0056b3;}</style></head><body><h1>Welcome to My Simple HTML Page</h1><p>This is a simple example of an HTML page with a header, a paragraph, and a button.</p><button onclick=alert('Button Clicked!')>Click Me</button></body></html>";

//     // Send the email
//     check sendEmailToStakeholder(stakeholderEmail, subject, messageBody);
// }
