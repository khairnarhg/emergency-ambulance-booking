-- RakshaPoorvak Seed: Hospital staff and doctors
-- Depends on: 01_hospitals, 02_users_and_roles
-- NOTE: Drivers are created in 04b after ambulances

TRUNCATE TABLE hospital_staff, doctors RESTART IDENTITY CASCADE;

-- Staff: user 10 (Admin Staff) → MGM Vashi (hospital 1)
INSERT INTO hospital_staff (user_id, hospital_id, created_at, updated_at) VALUES
(10, 1, NOW(), NOW());

-- Doctors: IDs 1-3
INSERT INTO doctors (user_id, hospital_id, status, specialization, created_at, updated_at) VALUES
(11, 1, 'AVAILABLE', 'Emergency Medicine', NOW(), NOW()),   -- Dr. Meera Nair → Vashi
(12, 2, 'AVAILABLE', 'Trauma Surgery',     NOW(), NOW()),   -- Dr. Rajesh Gupta → Kamothe
(13, 3, 'AVAILABLE', 'Cardiology',         NOW(), NOW());   -- Dr. Sunita Rao → CBD Belapur
