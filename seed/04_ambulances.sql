-- RakshaPoorvak Seed: Ambulances across MGM branches
-- Ambulance IDs: 1-6

TRUNCATE TABLE ambulances RESTART IDENTITY CASCADE;

INSERT INTO ambulances (hospital_id, registration_number, status, current_latitude, current_longitude, created_at, updated_at) VALUES
(1, 'MH-43-AB-1001', 'AVAILABLE', 19.07600000, 72.99880000, NOW(), NOW()),   -- Vashi Station
(1, 'MH-43-AB-1002', 'AVAILABLE', 19.06300000, 73.01200000, NOW(), NOW()),   -- Sanpada
(2, 'MH-43-CD-2001', 'AVAILABLE', 19.02000000, 73.09600000, NOW(), NOW()),   -- Kamothe Station
(2, 'MH-43-CD-2002', 'AVAILABLE', 19.03450000, 73.07200000, NOW(), NOW()),   -- Kharghar
(3, 'MH-43-EF-3001', 'AVAILABLE', 19.02200000, 73.04000000, NOW(), NOW()),   -- CBD Belapur Station
(3, 'MH-43-EF-3002', 'AVAILABLE', 19.03300000, 73.01650000, NOW(), NOW());   -- Nerul
