SET FOREIGN_KEY_CHECKS=0;

DELETE FROM job_assignment;
DELETE FROM attendance;
DELETE FROM temp_qr_mapping;
DELETE FROM bundle;
DELETE FROM workstation;
DELETE FROM operation;
DELETE FROM login;
DELETE FROM employee;
DELETE FROM role;

SET FOREIGN_KEY_CHECKS=1;
SET FOREIGN_KEY_CHECKS=0;

INSERT INTO role (role_id, role_name, status) VALUES (1, 'SUPERVISOR', 'ACTIVE'), (2, 'OPERATOR', 'ACTIVE'), (3, 'HR', 'ACTIVE');

INSERT INTO employee (emp_id, name, email, phone, role_id, status, emp_date, created_at) VALUES (1001, 'Super', 'super@test.com', '91000001', 1, 'ACTIVE', CURDATE(), NOW()), (1002, 'Alice', 'alice@test.com', '91000002', 2, 'ACTIVE', CURDATE(), NOW()), (1003, 'Bob', 'bob@test.com', '91000003', 2, 'ACTIVE', CURDATE(), NOW()), (1004, 'Carol', 'carol@test.com', '91000004', 2, 'ACTIVE', CURDATE(), NOW()), (1005, 'Dave', 'dave@test.com', '91000005', 2, 'ACTIVE', CURDATE(), NOW()), (1006, 'HR', 'hr@test.com', '91000006', 3, 'ACTIVE', CURDATE(), NOW());

INSERT INTO login (emp_id, password, status) VALUES (1001, 'pass', 'ACTIVE'), (1002, 'pass', 'ACTIVE'), (1003, 'pass', 'ACTIVE'), (1004, 'pass', 'ACTIVE'), (1005, 'pass', 'ACTIVE'), (1006, 'pass', 'ACTIVE');

INSERT INTO operation (op_id, op_code, op_name, zone, sequence_no, sam, industry_sam, skill_grade, target_pcs, status, created_at, observation_count, sam_source) VALUES (1, 'OP-01', 'Cutting', 'S1', 1, 0.5, 0.5, 'A', 100, 'ACTIVE', NOW(), 0, 'INDUSTRY'), (2, 'OP-02', 'Fusing', 'S1', 2, 0.5, 0.5, 'C', 90, 'ACTIVE', NOW(), 0, 'INDUSTRY'), (3, 'OP-03', 'Collar', 'S1', 3, 1.2, 1.2, 'A', 65, 'ACTIVE', NOW(), 0, 'INDUSTRY'), (4, 'OP-04', 'Edge', 'S1', 4, 0.3, 0.3, 'C', 120, 'ACTIVE', NOW(), 0, 'INDUSTRY'), (5, 'OP-05', 'Prep', 'S1', 5, 0.5, 0.5, 'C', 150, 'ACTIVE', NOW(), 0, 'INDUSTRY');

INSERT INTO workstation (ws_code, machine_code, status, op_id) VALUES ('STN-01', 'MACHINE-001', 'ACTIVE', 1), ('STN-02', 'MACHINE-002', 'ACTIVE', 2), ('STN-03', 'MACHINE-003', 'ACTIVE', 3), ('STN-04', 'MACHINE-004', 'ACTIVE', 4), ('STN-05', 'MACHINE-005', 'ACTIVE', 5);

INSERT INTO bundle (barcode, buyer_name, colour, size, style, order_no, qty, current_zone, status, entry_time, created_at) VALUES ('BND-001', 'ABC', 'White', 'M', 'SHIRT', 'ORD-001', 50, 'S1', 'ACTIVE', NOW(), NOW()), ('BND-002', 'ABC', 'Blue', 'L', 'SHIRT', 'ORD-001', 75, 'S1', 'ACTIVE', NOW(), NOW()), ('BND-003', 'XYZ', 'Red', 'S', 'SHIRT', 'ORD-002', 60, 'S1', 'ACTIVE', NOW(), NOW()), ('BND-004', 'XYZ', 'Green', 'M', 'SHIRT', 'ORD-002', 70, 'S1', 'ACTIVE', NOW(), NOW()), ('BND-005', 'PQR', 'Black', 'L', 'PANT', 'ORD-003', 80, 'S1', 'ACTIVE', NOW(), NOW()), ('BND-006', 'PQR', 'Navy', 'XL', 'PANT', 'ORD-003', 90, 'S1', 'ACTIVE', NOW(), NOW());

INSERT INTO temp_qr_mapping (qr_token, emp_id, mapping_date, mapped_at, mapped_by, is_freed) VALUES ('EMP-TEMP-001', 1002, CURDATE(), NOW(), 1001, 0), ('EMP-TEMP-002', 1003, CURDATE(), NOW(), 1001, 0), ('EMP-TEMP-003', 1004, CURDATE(), NOW(), 1001, 0), ('EMP-TEMP-004', 1005, CURDATE(), NOW(), 1001, 0);

INSERT INTO attendance (emp_id, att_date, check_in, temp_qr_token, machine_code, marked_by, status) VALUES (1002, CURDATE(), NOW(), 'EMP-TEMP-001', 'MACHINE-001', 1001, 'CHECKED_IN'), (1003, CURDATE(), NOW(), 'EMP-TEMP-002', 'MACHINE-003', 1001, 'CHECKED_IN'), (1004, CURDATE(), NOW(), 'EMP-TEMP-003', 'MACHINE-005', 1001, 'CHECKED_IN'), (1005, CURDATE(), NOW(), 'EMP-TEMP-004', 'MACHINE-002', 1001, 'CHECKED_IN');

INSERT INTO job_assignment (emp_id, ws_id, bundle_id, op_id, bundle_qty, sam_value, est_minutes, start_time, assigned_by, status, created_at) VALUES (1002, 1, 1, 1, 50, 0.5, 25, NOW(), 1001, 'IN_PROGRESS', NOW()), (1003, 3, 2, 3, 75, 1.2, 90, NOW(), 1001, 'IN_PROGRESS', NOW()), (1004, 5, 3, 5, 60, 0.5, 30, NOW(), 1001, 'IN_PROGRESS', NOW()), (1005, 2, 4, 2, 70, 0.5, 35, NOW(), 1001, 'IN_PROGRESS', NOW());

SET FOREIGN_KEY_CHECKS=1;

SELECT 'DATABASE SEEDED' as status, COUNT(*) as total FROM employee;
