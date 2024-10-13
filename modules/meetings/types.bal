import ballerina/http;
import ballerina/sql;

public type Meeting record {|
    @sql:Column {name: "id"}
    readonly int id;
    @sql:Column {name: "title"}
    string title;
    @sql:Column {name: "description"}
    string description?;
    @sql:Column {name: "meeting_date"}
    string meeting_date;
    @sql:Column {name: "meeting_time"}
    string meeting_time;
    @sql:Column {name: "location"}
    string location?;
    int[] stakeholders;
|};

public type MeetingRecord record {|
    @sql:Column {name: "id"}
    readonly int id;
    @sql:Column {name: "title"}
    string title;
    @sql:Column {name: "description"}
    string description?;
    @sql:Column {name: "meeting_date"}
    string meeting_date;
    @sql:Column {name: "meeting_time"}
    string meeting_time;
    @sql:Column {name: "location"}
    string location?;
    string stakeholders;
|};

public type NewMeeting record {|
    string title;
    string description?;
    string meeting_date;
    string meeting_time;
    string location?;
    int[] stakeholders;
|};

public type MeetingCreated record {|
    *http:Created;
    Meeting body;
|};

public type AttendaceRecord record {|
    int meetingId;
    int stakeholderId;
    boolean? attended;
|};

public type Attendace record {|
    @sql:Column {name: "stakeholder_id"}
    int stakeholderId;
    @sql:Column {name: "attended"}
    boolean attendance;
|};


public type MeetingCount record {
    string month;
    int year;
    int count;
};