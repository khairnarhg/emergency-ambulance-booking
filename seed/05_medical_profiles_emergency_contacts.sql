-- RakshaPoorvak Seed: Medical profiles and emergency contacts for patients

TRUNCATE TABLE medical_profiles, emergency_contacts RESTART IDENTITY CASCADE;

-- Medical profiles (user IDs 1-5 are patients)
INSERT INTO medical_profiles (user_id, blood_group, allergies, conditions, notes, created_at, updated_at) VALUES
(1, 'B+',  'Penicillin',  'Asthma',          'Uses inhaler daily',        NOW(), NOW()),
(2, 'O-',  NULL,          'Diabetes Type 2',  'On metformin 500mg twice daily', NOW(), NOW()),
(3, 'A+',  'Sulfa drugs', 'Hypertension',     'Takes Amlodipine 5mg',     NOW(), NOW()),
(4, 'AB+', 'Aspirin',     NULL,               NULL,                        NOW(), NOW()),
(5, 'O+',  NULL,          NULL,               NULL,                        NOW(), NOW());

-- Emergency contacts
INSERT INTO emergency_contacts (user_id, name, phone, relationship, created_at, updated_at) VALUES
(1, 'Sunita Sharma',  '9876500001', 'Mother',  NOW(), NOW()),
(1, 'Rajesh Sharma',  '9876500002', 'Father',  NOW(), NOW()),
(2, 'Vikash Patel',   '9876500003', 'Husband', NOW(), NOW()),
(3, 'Neha Joshi',     '9876500004', 'Wife',    NOW(), NOW()),
(3, 'Ravi Joshi',     '9876500005', 'Brother', NOW(), NOW()),
(4, 'Arjun Reddy',    '9876500006', 'Father',  NOW(), NOW()),
(5, 'Pooja Mehta',    '9876500007', 'Sister',  NOW(), NOW());
