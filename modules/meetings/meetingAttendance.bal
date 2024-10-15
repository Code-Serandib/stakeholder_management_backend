import ballerina/sql;

public function markAttendance(sql:Client dbClient, AttendaceRecord attendanceRecord) returns error? {
    sql:ParameterizedQuery query = `UPDATE meeting_stakeholders 
                                     SET attended = ${attendanceRecord.attended} 
                                     WHERE meeting_id = ${attendanceRecord.meetingId} AND stakeholder_id = ${attendanceRecord.stakeholderId}`;
    _ = check dbClient->execute(query);
}

public function getAttendance(int meetingId, sql:Client dbClient) returns Attendace[]|error {
       sql:ParameterizedQuery query = `SELECT stakeholder_id,attended FROM meeting_stakeholders
                                     WHERE meeting_id = ${meetingId}`;
        stream<Attendace, sql:Error?> attendanceStream = dbClient->query(query);
        return from Attendace atendance in attendanceStream
            select atendance;
}