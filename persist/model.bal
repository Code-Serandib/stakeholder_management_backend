import ballerina/persist as _;
import ballerina/time;

public type Employee record {|
   readonly string id;
   string firstName;
   string lastName;
   string email;
   string phone;
   time:Date hireDate;
   string? managerId;
   string jobTitle;
|};