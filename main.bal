import ballerina/io;
import stakeholder_management_backend.store;


final store:Client sClient = check new();

public function main() returns error? {
   store:EmployeeInsert employee1 = {
       id: "emp_01",
       firstName: "John",
       lastName: "Doe",
       email: "johnd@xyz.com",
       phone: "1234567890",
       hireDate: {
           year: 2020,
           month: 10,
           day: 10
       },
       managerId: "mng_01",
       jobTitle: "Software Engineer"
   };


   string[] employeeIds = check sClient->/employees.post([employee1]);
   io:println("Inserted employee id: " + employeeIds[0]);
}