-- RakshaPoorvak Seed: Drivers with ambulance assignments
-- Depends on: 02_users_and_roles, 01_hospitals, 04_ambulances

TRUNCATE TABLE drivers RESTART IDENTITY CASCADE;

-- Drivers with ambulance assignments:
-- Driver 1 (Vikram Singh, Vashi) → Ambulance 1 (MH-43-AB-1001)
-- Driver 2 (Anil Kumar, Kamothe) → Ambulance 3 (MH-43-CD-2001)
-- Driver 3 (Suresh Patil, Vashi) → Ambulance 2 (MH-43-AB-1002)
-- Driver 4 (Ravi Chauhan, CBD Belapur) → Ambulance 5 (MH-43-EF-3001)

INSERT INTO drivers (user_id, hospital_id, status, license_number, ambulance_id, created_at, updated_at) VALUES
(6,  1, 'AVAILABLE', 'MH43-2020-12345', 1, NOW(), NOW()),   -- Vikram Singh → Vashi, Ambulance 1
(7,  2, 'AVAILABLE', 'MH43-2019-67890', 3, NOW(), NOW()),   -- Anil Kumar → Kamothe, Ambulance 3
(8,  1, 'AVAILABLE', 'MH43-2021-54321', 2, NOW(), NOW()),   -- Suresh Patil → Vashi, Ambulance 2
(9,  3, 'AVAILABLE', 'MH43-2022-11111', 5, NOW(), NOW());   -- Ravi Chauhan → CBD Belapur, Ambulance 5
