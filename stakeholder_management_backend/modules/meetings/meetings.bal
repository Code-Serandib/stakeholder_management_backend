import ballerina/email;
import ballerina/http;
import ballerina/log;
import ballerina/sql;

public function schedule(sql:Client dbClient, NewMeeting newMeeting, email:SmtpClient emailClient) returns MeetingCreated|error? {
    transaction {
        sql:ExecutionResult result = check dbClient->execute(`
            INSERT INTO meetings (title, description, meeting_date, meeting_time, location)
            VALUES (${newMeeting.title}, ${newMeeting.description}, ${newMeeting.meeting_date}, ${newMeeting.meeting_time}, ${newMeeting.location})
        `);

        int|string? lastInsertId = result.lastInsertId;

        if lastInsertId is int {
            int meetingId = lastInsertId;

            string[] stakeholderEmails = [];
            foreach int stakeholderId in newMeeting.stakeholders {

                string|sql:Error emailResult = dbClient->queryRow(`
                    SELECT email_address FROM stakeholders WHERE id = ${stakeholderId}
                `);

                if emailResult is string {
                    stakeholderEmails.push(emailResult);
                }

                _ = check dbClient->execute(`
                    INSERT INTO meeting_stakeholders (meeting_id, stakeholder_id)
                    VALUES (${meetingId}, ${stakeholderId})
                `);
            }

            check commit;

            error? sendEmailsResult = sendEmails(stakeholderEmails, newMeeting, emailClient);

            if sendEmailsResult is error {
                log:printError("email sending failed");
            }

            return <MeetingCreated>{
                body: {
                    id: meetingId,
                    ...newMeeting
                }
            };
        } else {
            rollback;
            return error("Error occurred while retrieving the last insert ID");
        }
    }
}

public function getUpcomingMeetings(sql:Client dbClient) returns MeetingRecord[]|error {
    sql:ParameterizedQuery query = `SELECT M.id, M.title, M.description, M.meeting_date, 
    M.meeting_time, M.location, 
    GROUP_CONCAT(S.stakeholder_name) AS stakeholders 
    FROM meetings M 
    LEFT JOIN meeting_stakeholders MS ON M.id = MS.meeting_id 
    LEFT JOIN stakeholders S ON MS.stakeholder_id = S.id 
    WHERE M.meeting_date >= CURRENT_DATE 
    GROUP BY M.id, M.title, M.description, M.meeting_date, M.meeting_time, M.location 
    ORDER BY M.meeting_date ASC;`;

    stream<MeetingRecord, sql:Error?> meetingStream = dbClient->query(query);
    return from MeetingRecord meeting in meetingStream
        select meeting;
}

public function getAllMeetings(sql:Client dbClient) returns MeetingRecord[]|error {
    sql:ParameterizedQuery query = `SELECT M.id, M.title, M.description, M.meeting_date, 
       M.meeting_time, M.location, 
       GROUP_CONCAT(S.id, ':', S.stakeholder_name) AS stakeholders 
        FROM meetings M 
    LEFT JOIN meeting_stakeholders MS ON M.id = MS.meeting_id 
    LEFT JOIN stakeholders S ON MS.stakeholder_id = S.id
    GROUP BY M.id
    ORDER BY M.meeting_date ASC`;
    stream<MeetingRecord, sql:Error?> meetingStream = dbClient->query(query);
    return from MeetingRecord meeting in meetingStream
        select meeting;
}

public function getMeetingById(int id, sql:Client dbClient) returns MeetingRecord|http:NotFound {
    sql:ParameterizedQuery query = `SELECT M.id, M.title, M.description, M.meeting_date, 
    M.meeting_time, M.location, 
    GROUP_CONCAT(S.id, ':', S.stakeholder_name) AS stakeholders 
    FROM meetings M 
    LEFT JOIN meeting_stakeholders MS ON M.id = MS.meeting_id 
    LEFT JOIN stakeholders S ON MS.stakeholder_id = S.id 
    WHERE M.id = ${id} 
    GROUP BY M.id, M.title, M.description, M.meeting_date, M.meeting_time, M.location;`;

    MeetingRecord|error meeting = dbClient->queryRow(query);
    return meeting is MeetingRecord ? meeting : http:NOT_FOUND;
}

public function getMeetingCountHeldEachMonth(sql:Client dbClient) returns MeetingCount[]|error {
    sql:ParameterizedQuery query = `
        SELECT 
            MONTHNAME(MIN(M.meeting_date)) AS month,
            YEAR(MIN(M.meeting_date)) AS year,
            COUNT(M.id) AS count,
            MIN(M.meeting_date) AS order_date
        FROM meetings M
        WHERE M.meeting_date <= CURRENT_DATE
        AND YEAR(M.meeting_date) = YEAR(CURRENT_DATE)
        GROUP BY YEAR(M.meeting_date), MONTH(M.meeting_date)
        ORDER BY order_date
    `;

    stream<MeetingCount, sql:Error?> meetingStream = dbClient->query(query);
    return from MeetingCount meeting in meetingStream
        select meeting;
}

public function getTotalMeetingCount(sql:Client dbClient) returns int|error {
    sql:ParameterizedQuery query = `
        SELECT COUNT(*) AS total_count
        FROM meetings
    `;

    record {|int total_count;|}|sql:Error result = dbClient->queryRow(query);

    if result is record {|int total_count;|} {
        return result.total_count;
    } else {
        return error("Failed to retrieve total meetings count");
    }
}
