pragma solidity ^0.4.14;

import './SafeMath.sol';
import './Ownable.sol';

contract Payroll is Ownable {
    using SafeMath for uint;
    struct Employee{
        address id;
        uint salary;
        uint lastPayday;
    }
    address owner;
    uint constant payDuration = 30 days;
    mapping(address=>Employee) employees;
    uint totalSalary;
    uint salaryIdent=1 ether;
    
    function Payroll() payable{
        owner=msg.sender;
        totalSalary=0;
    }

    modifier AddressNotEmpty(address employeeId) {
        assert(employeeId!=0x0);
        _;
    }
    
    modifier EmployeeExist(address employeeId) {
        Employee employee=employees[employeeId];
        assert(employee.id!=0x0);
        _;
    }
    
    modifier EmployeeNotExist(address employeeId){
        Employee employee=employees[employeeId];
        assert(employee.id==0x0);
        _;
    }
    
    function _partialPaid(Employee employee) private{
        if(employee.id!=0x0){
            uint payment=(employee.salary).mul((now.sub(employee.lastPayday))).div(payDuration);
            if(hasEnoughFund2(payment)) employee.id.transfer(payment);
        }
    }
    
    
    function addEmployee(address employeeId,uint salary) public onlyOwner AddressNotEmpty(employeeId) EmployeeNotExist(employeeId){
        salary=salary.mul(salaryIdent);
        employees[employeeId]=Employee(employeeId,salary,now);
        totalSalary=totalSalary.add(salary);
    }
    
    function removeEmployee(address employeeId) public payable onlyOwner EmployeeExist(employeeId){
        var employee=employees[employeeId];
        _partialPaid(employee);
        totalSalary=totalSalary.sub(employee.salary);
        delete employees[employeeId];
    }
    
    function updateEmployee(address employeeId, uint salary) public payable onlyOwner EmployeeExist(employeeId){
        Employee employee=employees[employeeId];
        _partialPaid(employees[employeeId]);
        salary=salary.mul(salaryIdent);
        totalSalary=totalSalary.add(salary).sub(employee.salary);
        employees[employeeId].id=employeeId;
        employees[employeeId].salary=salary;
        employees[employeeId].lastPayday=now;
    }
    
    function changePaymentAddress(address oldAddr,address newAddr) public onlyOwner AddressNotEmpty(newAddr) EmployeeExist(oldAddr) EmployeeNotExist(newAddr){
        Employee employee=employees[oldAddr];
        employees[newAddr]=Employee(newAddr,employee.salary,employee.lastPayday);
        delete employees[oldAddr];
    }
    
    function getSalary(address employeeId) public EmployeeExist(employeeId) returns(uint){
        Employee employee=employees[employeeId];
        return employee.salary;
    }
    
    function getLastPayday(address employeeId) public EmployeeExist(employeeId) returns(uint){
        Employee employee=employees[employeeId];
        return employee.lastPayday;
    }
    
    function addFund() public payable returns(uint){
        return address(this).balance;
    }
    
    function calculateRunway() public view returns(uint){
        require(totalSalary>0);
        return address(this).balance .div( totalSalary);
    }
    
    function hasEnoughFund() public returns(bool){
        return calculateRunway() > 0;
    }
    
    function hasEnoughFund2(uint value) internal returns(bool){
        return address(this).balance >= value;
    }
    
    function checkEmployee(address employeeId) public returns(uint salary,uint lastPayday){
        Employee employee=employees[employeeId];
        salary=employee.salary;
        lastPayday=employee.lastPayday;
    }
    
    function getPaid() public payable EmployeeExist(msg.sender){
        Employee employee=employees[msg.sender];
        require( hasEnoughFund() );
        uint newDay = employee.lastPayday.add( payDuration);
        assert(newDay<now);
        employees[msg.sender].lastPayday = newDay;
        employee.id.transfer(employee.salary);
    }
    
}