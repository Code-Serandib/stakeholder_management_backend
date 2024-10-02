import ballerina/http;
import ballerina/sql;

public type Meeting record {|
    @sql:Column {name: "ID"}
    readonly int id;
    @sql:Column {name: "TITLE"}
    string title;
    @sql:Column {name: "DESCRIPTION"}
    string description?;
    @sql:Column {name: "MEETING_DATE"}
    string meeting_date;
    @sql:Column {name: "MEETING_TIME"}
    string meeting_time;
    @sql:Column {name: "LOCATION"}
    string location?;
    @sql:Column {name: "STAKEHOLDERS"}
    string stakeholders?;
|};

public type NewMeeting record {|
    string title;
    string description?;
    string meeting_date;
    string meeting_time;
    string location?;
    string stakeholders?;
|};

public type MeetingCreated record {|
    *http:Created;
    Meeting body;
|};
