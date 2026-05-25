-- Reset operational data, preserve master data
USE smo;
SET FOREIGN_KEY_CHECKS = 0;

-- Tracking & assignments
TRUNCATE TABLE wiptracking;
TRUNCATE TABLE temp_active_assignments;
TRUNCATE TABLE temp_assignment_log;
TRUNCATE TABLE temp_bin_merges;
TRUNCATE TABLE temp_emp_qrs;

-- Merge history
TRUNCATE TABLE mergebin;
TRUNCATE TABLE bin_merge_history;

-- Bins & QR events
TRUNCATE TABLE bin_assignment_history;
TRUNCATE TABLE bin;
TRUNCATE TABLE qr_event;
TRUNCATE TABLE qr_scan_history;

-- Orders
TRUNCATE TABLE orders;

-- Routing & operations
TRUNCATE TABLE routing_edge;
TRUNCATE TABLE routingstep;
TRUNCATE TABLE routing;
TRUNCATE TABLE operation;

SET FOREIGN_KEY_CHECKS = 1;

SELECT 'Reset complete. Master data preserved.' AS status;
SELECT COUNT(*) AS bins FROM bin;
SELECT COUNT(*) AS routings FROM routing;
SELECT COUNT(*) AS operations FROM operation;
SELECT COUNT(*) AS wiptracking FROM wiptracking;
SELECT COUNT(*) AS styles FROM style;
SELECT COUNT(*) AS employees FROM employee;
SELECT COUNT(*) AS machines FROM machine;
