-- Seed production data for 2026-06-19
-- Employees: reuse existing (Siva Parvati=1022, S D Noori=1023, T Ramya=1050)
--            create new: Maryambe=1061, Rukiya=1062, Sunitha=1063, Sravanthi=1064, Jabina=1065

-- ── 1. Insert missing employees ─────────────────────────────────────────────
INSERT IGNORE INTO employee (emp_id, name, email, status, role_id, emp_date, created_at)
VALUES
  (1061, 'Maryambe',  'maryambe@palms.local',  'ACTIVE', 2, '2026-06-19', NOW()),
  (1062, 'Rukiya',    'rukiya@palms.local',     'ACTIVE', 2, '2026-06-19', NOW()),
  (1063, 'Sunitha',   'sunitha@palms.local',    'ACTIVE', 2, '2026-06-19', NOW()),
  (1064, 'Sravanthi', 'sravanthi@palms.local',  'ACTIVE', 2, '2026-06-19', NOW()),
  (1065, 'Jabina',    'jabina@palms.local',     'ACTIVE', 2, '2026-06-19', NOW());

-- ── 2. Production logs for 2026-06-19 ────────────────────────────────────────
-- shift_id=1, date via logged_at
-- ws_id: Back Yoke Adding=16, Front Kansai Left Placket=18, Pocket Hemming=21,
--         Pocket Iron=20, Pocket Attach=22, Front Right Patti=19, Edge Cutting=4
-- hour_slot: 9=slot1, 10=slot2 ... (hour of the slot start)
-- sam_earned = pieces * SAM

-- Maryambe (1061) | Back Yoke Adding | SAM=1.2 | ws=16
INSERT INTO production_log (emp_id, ws_id, shift_id, hour_slot, pieces_produced, sam_earned, logged_at) VALUES
(1061, 16, 1, 10, 22,  26.400, '2026-06-19 10:00:00'),
(1061, 16, 1, 11, 23,  27.600, '2026-06-19 11:00:00'),
(1061, 16, 1, 12, 10,  12.000, '2026-06-19 12:00:00'),
(1061, 16, 1, 13, 25,  30.000, '2026-06-19 13:00:00'),
(1061, 16, 1, 14, 25,  30.000, '2026-06-19 14:00:00'),
(1061, 16, 1, 15, 60,  72.000, '2026-06-19 15:00:00'),
(1061, 16, 1, 16, 16,  19.200, '2026-06-19 16:00:00');

-- Rukiya (1062) | Front Kansai Left Placket | SAM=2.0 | ws=18
INSERT INTO production_log (emp_id, ws_id, shift_id, hour_slot, pieces_produced, sam_earned, logged_at) VALUES
(1062, 18, 1, 10, 50, 100.000, '2026-06-19 10:00:00'),
(1062, 18, 1, 11, 45,  90.000, '2026-06-19 11:00:00'),
(1062, 18, 1, 12, 30,  60.000, '2026-06-19 12:00:00'),
(1062, 18, 1, 13, 42,  84.000, '2026-06-19 13:00:00'),
(1062, 18, 1, 14, 50, 100.000, '2026-06-19 14:00:00'),
(1062, 18, 1, 15, 30,  60.000, '2026-06-19 15:00:00');

-- Sunitha (1063) | Pocket Hemming | SAM=0.8 | ws=21
INSERT INTO production_log (emp_id, ws_id, shift_id, hour_slot, pieces_produced, sam_earned, logged_at) VALUES
(1063, 21, 1, 10, 75, 60.000, '2026-06-19 10:00:00'),
(1063, 21, 1, 11, 85, 68.000, '2026-06-19 11:00:00'),
(1063, 21, 1, 12, 75, 60.000, '2026-06-19 12:00:00');

-- Sravanthi (1064) | Pocket Iron | SAM=0.6 | ws=20
INSERT INTO production_log (emp_id, ws_id, shift_id, hour_slot, pieces_produced, sam_earned, logged_at) VALUES
(1064, 20, 1, 10, 30, 18.000, '2026-06-19 10:00:00'),
(1064, 20, 1, 11, 60, 36.000, '2026-06-19 11:00:00'),
(1064, 20, 1, 12, 50, 30.000, '2026-06-19 12:00:00'),
(1064, 20, 1, 13, 30, 18.000, '2026-06-19 13:00:00'),
(1064, 20, 1, 14, 60, 36.000, '2026-06-19 14:00:00'),
(1064, 20, 1, 15, 50, 30.000, '2026-06-19 15:00:00'),
(1064, 20, 1, 16, 30, 18.000, '2026-06-19 16:00:00');

-- T Ramya (1050) | Pocket Attach | SAM=1.2 | ws=22
INSERT INTO production_log (emp_id, ws_id, shift_id, hour_slot, pieces_produced, sam_earned, logged_at) VALUES
(1050, 22, 1, 10, 50, 60.000, '2026-06-19 10:00:00'),
(1050, 22, 1, 11, 40, 48.000, '2026-06-19 11:00:00'),
(1050, 22, 1, 12, 40, 48.000, '2026-06-19 12:00:00'),
(1050, 22, 1, 13, 50, 60.000, '2026-06-19 13:00:00'),
(1050, 22, 1, 14, 40, 48.000, '2026-06-19 14:00:00'),
(1050, 22, 1, 15, 40, 48.000, '2026-06-19 15:00:00'),
(1050, 22, 1, 16, 30, 36.000, '2026-06-19 16:00:00');

-- Jabina (1065) | Front Right Patti | SAM=1.2 | ws=19
INSERT INTO production_log (emp_id, ws_id, shift_id, hour_slot, pieces_produced, sam_earned, logged_at) VALUES
(1065, 19, 1, 10, 35, 42.000, '2026-06-19 10:00:00'),
(1065, 19, 1, 11, 20, 24.000, '2026-06-19 11:00:00'),
(1065, 19, 1, 12, 10, 12.000, '2026-06-19 12:00:00'),
(1065, 19, 1, 13, 30, 36.000, '2026-06-19 13:00:00'),
(1065, 19, 1, 15, 20, 24.000, '2026-06-19 15:00:00'),
(1065, 19, 1, 16, 30, 36.000, '2026-06-19 16:00:00');

-- Siva Parvati (1022) | Front Right Patti | SAM=1.2 | ws=19
INSERT INTO production_log (emp_id, ws_id, shift_id, hour_slot, pieces_produced, sam_earned, logged_at) VALUES
(1022, 19, 1, 10, 50, 60.000, '2026-06-19 10:00:00'),
(1022, 19, 1, 11, 10, 12.000, '2026-06-19 11:00:00'),
(1022, 19, 1, 12, 17, 20.400, '2026-06-19 12:00:00'),
(1022, 19, 1, 13, 35, 42.000, '2026-06-19 13:00:00'),
(1022, 19, 1, 16, 35, 42.000, '2026-06-19 16:00:00');

-- S D Noori (1023) | Edge Cutting | SAM=0.3 | ws=4
INSERT INTO production_log (emp_id, ws_id, shift_id, hour_slot, pieces_produced, sam_earned, logged_at) VALUES
(1023,  4, 1, 10, 175, 52.500, '2026-06-19 10:00:00'),
(1023,  4, 1, 11,  52, 15.600, '2026-06-19 11:00:00'),
(1023,  4, 1, 12,  20,  6.000, '2026-06-19 12:00:00'),
(1023,  4, 1, 13,  32,  9.600, '2026-06-19 13:00:00'),
(1023,  4, 1, 14, 150, 45.000, '2026-06-19 14:00:00');
