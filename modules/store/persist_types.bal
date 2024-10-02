// AUTO-GENERATED FILE. DO NOT MODIFY.

// This file is an auto-generated file by Ballerina persistence layer for model.
// It should not be modified by hand.

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

public type EmployeeOptionalized record {|
    string id?;
    string firstName?;
    string lastName?;
    string email?;
    string phone?;
    time:Date hireDate?;
    string? managerId?;
    string jobTitle?;
|};

public type EmployeeTargetType typedesc<EmployeeOptionalized>;

public type EmployeeInsert Employee;

public type EmployeeUpdate record {|
    string firstName?;
    string lastName?;
    string email?;
    string phone?;
    time:Date hireDate?;
    string? managerId?;
    string jobTitle?;
|};

