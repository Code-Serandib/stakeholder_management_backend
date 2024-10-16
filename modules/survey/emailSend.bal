import ballerina/email;
import ballerina/io;

// Function to send an email
 function sendEmailSetOfStakeholders(EmailDetails emailDetails) returns error? {

    email:SmtpConfiguration smtpConfig = {
        port: 587, 
        security: email:START_TLS_AUTO
    };

    email:SmtpClient smtpClient = check new email:SmtpClient(
        host = "smtp.gmail.com",
        username = "from@gmail.com",
        password = "abcc cccc cccc cccc",
        clientConfig = smtpConfig
    );

    email:Message emailMessage = {
        'from: "from@gmail.com",
        to: [emailDetails.recipient],
        subject: emailDetails.subject,
        htmlBody: emailDetails.bodyHtml
    };

    check smtpClient->sendMessage(emailMessage);
}

// Function to send an email
function sendEmailToStakeholder(string recipientEmail, string subject, string messageBody) returns error? {
    email:SmtpClient smtpClient = check new (host = "smtp.gmail.com",
        port = 465,
        username = "your@gmail.com",
        password = "cccc cccc cccc cccc", 
        security = email:SSL
        // auth = true,
    );

    email:Message emailMessage = {
        'from: "your@gmail.com",
        to: recipientEmail,
        subject: subject,
        htmlBody: messageBody
    };

    check smtpClient->sendMessage(emailMessage);
    io:println("Email sent successfully to " + recipientEmail);
}
