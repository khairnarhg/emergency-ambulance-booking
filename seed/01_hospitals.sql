-- RakshaPoorvak Seed: MGM Hospital branches (Navi Mumbai)
-- Hospitals: 1=Vashi, 2=Kamothe, 3=CBD Belapur

TRUNCATE TABLE hospitals RESTART IDENTITY CASCADE;

INSERT INTO hospitals (name, address, latitude, longitude, created_at, updated_at) VALUES
('MGM Hospital Vashi',        'Plot 7, Sector 1, Vashi, Navi Mumbai',       19.07710000, 73.00130000, NOW(), NOW()),
('MGM Hospital Kamothe',      'Sector 21, Kamothe, Navi Mumbai',            19.01780000, 73.09870000, NOW(), NOW()),
('MGM Hospital CBD Belapur',  'Sector 8, CBD Belapur, Navi Mumbai',         19.02350000, 73.03880000, NOW(), NOW());
