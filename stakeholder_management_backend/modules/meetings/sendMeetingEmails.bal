import ballerina/email;
public function sendEmails(string[] emails, NewMeeting meeting, email:SmtpClient emailClient) returns error? {

    string htmlBody = string `
    <html>
    <head>
        <style>
            body {
                font-family: Arial, sans-serif;
                background-color: #f4f4f4;
                margin: 0;
                padding: 0;
                color: #333;
            }
            .container {
                max-width: 600px;
                margin: 20px auto;
                background-color: #fff;
                padding: 20px;
                border-radius: 8px;
                box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
            }
            .header {
                background-color: #4CAF50;
                color: white;
                padding: 15px;
                text-align: center;
                border-radius: 8px 8px 0 0;
            }
            .header h1 {
                margin: 0;
            }
            .content {
                margin: 20px;
                font-size: 16px;
            }
            .content p {
                margin: 0 0 15px;
            }
            .content ul {
                list-style: none;
                padding: 0;
            }
            .content ul li {
                background: #eee;
                padding: 10px;
                margin-bottom: 10px;
                border-radius: 4px;
            }
            .footer {
                text-align: center;
                margin-top: 20px;
                font-size: 12px;
                color: #888;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>Meeting Invitation</h1>
            </div>
            <div class="content">
                <p>Dear Stakeholder,</p>
                <p>You're invited to a meeting:</p>
                <ul>
                    <li><strong>Title:</strong> ${meeting.title}</li>
                    <li><strong>Date:</strong> ${meeting.meeting_date}</li>
                    <li><strong>Time:</strong> ${meeting.meeting_time}</li>
                    <li><strong>Location:</strong> ${meeting.location ?: "TBD"}</li>
                </ul>
                <p>We look forward to your participation.</p>
            </div>
            <div class="footer">
                <p>This is an automated email. Please do not reply.</p>
            </div>
        </div>
    </body>
    </html>
    `;

    // Send emails asynchronously without waiting
    foreach string recipientEmail in emails {
        email:Message email = {
            'from: "codeserandib@gmail.com",
            to: recipientEmail,
            subject: "Meeting Invitation: " + meeting.title,
            htmlBody: htmlBody
        };

        _ = start sendEmailAsync(email, emailClient);
    }
}

function sendEmailAsync(email:Message email, email:SmtpClient emailClient) returns error? {
    check emailClient->sendMessage(email);
}
