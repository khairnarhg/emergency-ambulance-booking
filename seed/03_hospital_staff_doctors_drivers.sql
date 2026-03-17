-- RakshaPoorvak Seed: Hospital staff, doctors, drivers
-- Depends on: 01_hospitals, 02_users_and_roles

TRUNCATE TABLE hospital_staff, doctors, drivers RESTART IDENTITY CASCADE;

-- Staff: user 10 (Admin Staff) → MGM Vashi (hospital 1)
INSERT INTO hospital_staff (user_id, hospital_id, created_at, updated_at) VALUES
(10, 1, NOW(), NOW());

-- Doctors: IDs 1-3
INSERT INTO doctors (user_id, hospital_id, status, specialization, created_at, updated_at) VALUES
(11, 1, 'AVAILABLE', 'Emergency Medicine', NOW(), NOW()),   -- Dr. Meera Nair → Vashi
(12, 2, 'AVAILABLE', 'Trauma Surgery',     NOW(), NOW()),   -- Dr. Rajesh Gupta → Kamothe
(13, 3, 'AVAILABLE', 'Cardiology',         NOW(), NOW());   -- Dr. Sunita Rao → CBD Belapur

-- Drivers: IDs 1-4
INSERT INTO drivers (user_id, hospital_id, status, license_number, created_at, updated_at) VALUES
(6,  1, 'AVAILABLE', 'MH43-2020-12345', NOW(), NOW()),   -- Vikram Singh → Vashi
(7,  2, 'AVAILABLE', 'MH43-2019-67890', NOW(), NOW()),   -- Anil Kumar → Kamothe
(8,  1, 'AVAILABLE', 'MH43-2021-54321', NOW(), NOW()),   -- Suresh Patil → Vashi
(9,  3, 'AVAILABLE', 'MH43-2022-11111', NOW(), NOW());   -- Ravi Chauhan → CBD Belapur
