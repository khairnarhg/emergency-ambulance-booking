-- RakshaPoorvak Seed: Users and role assignments
-- Password for ALL users: password123
-- User IDs: 1-5 patients, 6-9 drivers, 10 staff, 11-13 doctors

TRUNCATE TABLE users RESTART IDENTITY CASCADE;

INSERT INTO users (email, password_hash, full_name, phone, created_at, updated_at) VALUES
('patient1@test.com',  '$2a$10$dXJ3SW6G7P50lGmMQgel2OB7PZ2TYf.M8fGVKXPXNqMNpJ4wQqXJe', 'Rahul Sharma',      '9876543210', NOW(), NOW()),
('patient2@test.com',  '$2a$10$dXJ3SW6G7P50lGmMQgel2OB7PZ2TYf.M8fGVKXPXNqMNpJ4wQqXJe', 'Priya Patel',       '9876543211', NOW(), NOW()),
('patient3@test.com',  '$2a$10$dXJ3SW6G7P50lGmMQgel2OB7PZ2TYf.M8fGVKXPXNqMNpJ4wQqXJe', 'Amit Joshi',        '9876543217', NOW(), NOW()),
('patient4@test.com',  '$2a$10$dXJ3SW6G7P50lGmMQgel2OB7PZ2TYf.M8fGVKXPXNqMNpJ4wQqXJe', 'Sneha Reddy',       '9876543218', NOW(), NOW()),
('patient5@test.com',  '$2a$10$dXJ3SW6G7P50lGmMQgel2OB7PZ2TYf.M8fGVKXPXNqMNpJ4wQqXJe', 'Karan Mehta',       '9876543219', NOW(), NOW()),
('driver1@test.com',   '$2a$10$dXJ3SW6G7P50lGmMQgel2OB7PZ2TYf.M8fGVKXPXNqMNpJ4wQqXJe', 'Vikram Singh',      '9876543212', NOW(), NOW()),
('driver2@test.com',   '$2a$10$dXJ3SW6G7P50lGmMQgel2OB7PZ2TYf.M8fGVKXPXNqMNpJ4wQqXJe', 'Anil Kumar',        '9876543213', NOW(), NOW()),
('driver3@test.com',   '$2a$10$dXJ3SW6G7P50lGmMQgel2OB7PZ2TYf.M8fGVKXPXNqMNpJ4wQqXJe', 'Suresh Patil',      '9876543220', NOW(), NOW()),
('driver4@test.com',   '$2a$10$dXJ3SW6G7P50lGmMQgel2OB7PZ2TYf.M8fGVKXPXNqMNpJ4wQqXJe', 'Ravi Chauhan',      '9876543221', NOW(), NOW()),
('staff@hospital.com', '$2a$10$dXJ3SW6G7P50lGmMQgel2OB7PZ2TYf.M8fGVKXPXNqMNpJ4wQqXJe', 'Admin Staff',       '9876543214', NOW(), NOW()),
('doctor1@test.com',   '$2a$10$dXJ3SW6G7P50lGmMQgel2OB7PZ2TYf.M8fGVKXPXNqMNpJ4wQqXJe', 'Dr. Meera Nair',    '9876543215', NOW(), NOW()),
('doctor2@test.com',   '$2a$10$dXJ3SW6G7P50lGmMQgel2OB7PZ2TYf.M8fGVKXPXNqMNpJ4wQqXJe', 'Dr. Rajesh Gupta',  '9876543216', NOW(), NOW()),
('doctor3@test.com',   '$2a$10$dXJ3SW6G7P50lGmMQgel2OB7PZ2TYf.M8fGVKXPXNqMNpJ4wQqXJe', 'Dr. Sunita Rao',    '9876543222', NOW(), NOW());

-- Role IDs from V1 migration: 1=USER, 2=DRIVER, 3=HOSPITAL_STAFF, 4=DOCTOR, 5=ADMIN
INSERT INTO user_roles (user_id, role_id) VALUES
(1,  1),   -- patient1 → USER
(2,  1),   -- patient2 → USER
(3,  1),   -- patient3 → USER
(4,  1),   -- patient4 → USER
(5,  1),   -- patient5 → USER
(6,  2),   -- driver1  → DRIVER
(7,  2),   -- driver2  → DRIVER
(8,  2),   -- driver3  → DRIVER
(9,  2),   -- driver4  → DRIVER
(10, 3),   -- staff    → HOSPITAL_STAFF
(11, 4),   -- doctor1  → DOCTOR
(12, 4),   -- doctor2  → DOCTOR
(13, 4);   -- doctor3  → DOCTOR
