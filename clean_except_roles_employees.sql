SET FOREIGN_KEY_CHECKS=0;

-- Clean temporary/cached tables
TRUNCATE TABLE attendance;
TRUNCATE TABLE daily_stock;
TRUNCATE TABLE efficiency_summary;
TRUNCATE TABLE job_assignment;
TRUNCATE TABLE login_audit;
TRUNCATE TABLE method_study;
TRUNCATE TABLE operation;
TRUNCATE TABLE pacemaker_registry;
TRUNCATE TABLE packing_log;
TRUNCATE TABLE production_log;
TRUNCATE TABLE qc_defect;
TRUNCATE TABLE qc_log;
TRUNCATE TABLE rtm_stock;
TRUNCATE TABLE sam_study;
TRUNCATE TABLE shift;
TRUNCATE TABLE shift_break;
TRUNCATE TABLE shift_template;
TRUNCATE TABLE stock_availability;
TRUNCATE TABLE temp_qr_mapping;
TRUNCATE TABLE tray;
TRUNCATE TABLE wash_batch;
TRUNCATE TABLE workstation;

-- Update role activities to match frontend requirements
UPDATE role SET activities = 'HR_DASHBOARD,HR_MANAGE_ROLES,HR_MANAGE_EMPLOYEES,HR_ATTENDANCE_REPORT,PROFILE_MANAGEMENT' WHERE role_name = 'HR/Admin' OR role_name = 'HR';
UPDATE role SET activities = 'SUPERVISOR_WORK_ASSIGNMENT,SUPERVISOR_EFFICIENCY,SUPERVISOR_HISTORY,SUPERVISOR_ATTENDANCE,SUPERVISOR_LINE_BALANCING,PROFILE_MANAGEMENT' WHERE role_name = 'Supervisor' OR role_name = 'SUPERVISOR';

SET FOREIGN_KEY_CHECKS=1;

SELECT 'CLEANUP COMPLETE' AS status, COUNT(*) AS total_employees FROM employee;
