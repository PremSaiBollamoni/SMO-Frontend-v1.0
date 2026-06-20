SET FOREIGN_KEY_CHECKS=0;

DELETE FROM job_assignment;
DELETE FROM attendance;
DELETE FROM temp_qr_mapping;
DELETE FROM workstation;
DELETE FROM operation;
DELETE FROM login;
DELETE FROM employee;
DELETE FROM role;

SET FOREIGN_KEY_CHECKS=1;
SET FOREIGN_KEY_CHECKS=0;

INSERT INTO role (role_id, role_name, activities, status) VALUES 
(1, 'SUPERVISOR', 'SUPERVISOR_WORK_ASSIGNMENT,SUPERVISOR_EFFICIENCY,SUPERVISOR_HISTORY,SUPERVISOR_ATTENDANCE,SUPERVISOR_LINE_BALANCING,PROFILE_MANAGEMENT', 'ACTIVE'), 
(2, 'OPERATOR', 'OPERATOR_SCAN', 'ACTIVE'), 
(3, 'HR', 'HR_DASHBOARD,HR_MANAGE_ROLES,HR_MANAGE_EMPLOYEES,HR_ATTENDANCE_REPORT,PROFILE_MANAGEMENT', 'ACTIVE');

INSERT INTO employee (emp_id, name, email, phone, role_id, status, emp_date, created_at) VALUES (1001, 'Super', 'super@test.com', '91000001', 1, 'ACTIVE', CURDATE(), NOW()), (1002, 'Alice', 'alice@test.com', '91000002', 2, 'ACTIVE', CURDATE(), NOW()), (1003, 'Bob', 'bob@test.com', '91000003', 2, 'ACTIVE', CURDATE(), NOW()), (1004, 'Carol', 'carol@test.com', '91000004', 2, 'ACTIVE', CURDATE(), NOW()), (1005, 'Dave', 'dave@test.com', '91000005', 2, 'ACTIVE', CURDATE(), NOW()), (1006, 'HR', 'hr@test.com', '91000006', 3, 'ACTIVE', CURDATE(), NOW());

INSERT INTO login (emp_id, password, status, failed_login_attempts, password_hash_version) VALUES 
(1001, 'pass', 'ACTIVE', 0, 0), 
(1002, 'pass', 'ACTIVE', 0, 0), 
(1003, 'pass', 'ACTIVE', 0, 0), 
(1004, 'pass', 'ACTIVE', 0, 0), 
(1005, 'pass', 'ACTIVE', 0, 0), 
(1006, 'pass', 'ACTIVE', 0, 0);

SET FOREIGN_KEY_CHECKS=1;

SELECT 'DATABASE SEEDED' as status, COUNT(*) as total FROM employee;
