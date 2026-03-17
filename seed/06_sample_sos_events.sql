-- RakshaPoorvak Seed: SOS events, triage records, medications, location updates
-- 12 COMPLETED historical events (spread over 30 days) + 2 active events for demo
--
-- ID reference (all tables use RESTART IDENTITY so IDs are deterministic):
--   Users:      1=Rahul, 2=Priya, 3=Amit, 4=Sneha, 5=Karan
--   Hospitals:  1=Vashi, 2=Kamothe, 3=CBD Belapur
--   Ambulances: 1=AB-1001(Vashi), 2=AB-1002(Vashi), 3=CD-2001(Kamothe),
--               4=CD-2002(Kamothe), 5=EF-3001(CBD), 6=EF-3002(CBD)
--   Drivers:    1=Vikram(Vashi), 2=Anil(Kamothe), 3=Suresh(Vashi), 4=Ravi(CBD)
--   Doctors:    1=Meera(Vashi), 2=Rajesh(Kamothe), 3=Sunita(CBD)

TRUNCATE TABLE sos_events, triage_records, medications, location_updates RESTART IDENTITY CASCADE;

-- ============================================================
-- COMPLETED SOS EVENTS (1-12)
-- ============================================================

INSERT INTO sos_events (user_id, hospital_id, ambulance_id, driver_id, doctor_id,
    latitude, longitude, address, status, symptoms, criticality,
    completed_at, created_at, updated_at) VALUES

-- 1: Rahul, chest pain, 28 days ago
(1, 1, 1, 1, 1,
 19.07000000, 73.00500000, 'Sector 17, Vashi, Navi Mumbai',
 'COMPLETED', 'Chest pain, breathlessness, radiating pain to left arm', 'CRITICAL',
 NOW() - INTERVAL '28 days' + INTERVAL '35 minutes',
 NOW() - INTERVAL '28 days', NOW() - INTERVAL '28 days' + INTERVAL '35 minutes'),

-- 2: Priya, road accident, 25 days ago
(2, 2, 3, 2, 2,
 19.02500000, 73.08800000, 'Sector 12, Kamothe, Navi Mumbai',
 'COMPLETED', 'Road accident, suspected leg fracture, abrasions', 'HIGH',
 NOW() - INTERVAL '25 days' + INTERVAL '28 minutes',
 NOW() - INTERVAL '25 days', NOW() - INTERVAL '25 days' + INTERVAL '28 minutes'),

-- 3: Amit, allergic reaction, 23 days ago
(3, 1, 2, 3, 1,
 19.06200000, 73.01000000, 'Sanpada Junction, Navi Mumbai',
 'COMPLETED', 'Severe allergic reaction, facial swelling, difficulty breathing', 'CRITICAL',
 NOW() - INTERVAL '23 days' + INTERVAL '22 minutes',
 NOW() - INTERVAL '23 days', NOW() - INTERVAL '23 days' + INTERVAL '22 minutes'),

-- 4: Sneha, fainting, 20 days ago
(4, 3, 5, 4, 3,
 19.02600000, 73.03500000, 'Sector 11, CBD Belapur, Navi Mumbai',
 'COMPLETED', 'Fainting spell, dizziness, nausea', 'MEDIUM',
 NOW() - INTERVAL '20 days' + INTERVAL '25 minutes',
 NOW() - INTERVAL '20 days', NOW() - INTERVAL '20 days' + INTERVAL '25 minutes'),

-- 5: Rahul, asthma attack, 18 days ago
(1, 1, 1, 1, 1,
 19.06800000, 73.02000000, 'Turbhe MIDC, Navi Mumbai',
 'COMPLETED', 'Severe asthma attack, wheezing, unable to speak full sentences', 'HIGH',
 NOW() - INTERVAL '18 days' + INTERVAL '20 minutes',
 NOW() - INTERVAL '18 days', NOW() - INTERVAL '18 days' + INTERVAL '20 minutes'),

-- 6: Karan, abdominal pain, 15 days ago
(5, 2, 4, 2, 2,
 19.03800000, 73.06800000, 'Kharghar Sector 4, Navi Mumbai',
 'COMPLETED', 'Severe abdominal pain, vomiting, unable to stand', 'MEDIUM',
 NOW() - INTERVAL '15 days' + INTERVAL '30 minutes',
 NOW() - INTERVAL '15 days', NOW() - INTERVAL '15 days' + INTERVAL '30 minutes'),

-- 7: Priya, fall injury, 12 days ago
(2, 1, 2, 3, 1,
 19.05600000, 73.00800000, 'Juinagar Railway Station, Navi Mumbai',
 'COMPLETED', 'Fall from stairs, severe back pain, limited mobility', 'HIGH',
 NOW() - INTERVAL '12 days' + INTERVAL '18 minutes',
 NOW() - INTERVAL '12 days', NOW() - INTERVAL '12 days' + INTERVAL '18 minutes'),

-- 8: Amit, seizure, 10 days ago
(3, 3, 6, 4, 3,
 19.03500000, 73.01800000, 'Nerul Sector 20, Navi Mumbai',
 'COMPLETED', 'Seizure, loss of consciousness, foaming at mouth', 'CRITICAL',
 NOW() - INTERVAL '10 days' + INTERVAL '24 minutes',
 NOW() - INTERVAL '10 days', NOW() - INTERVAL '10 days' + INTERVAL '24 minutes'),

-- 9: Sneha, bleeding wound, 7 days ago
(4, 1, 1, 1, 1,
 19.04800000, 73.02500000, 'Palm Beach Road, Navi Mumbai',
 'COMPLETED', 'Deep laceration on forearm, heavy bleeding', 'HIGH',
 NOW() - INTERVAL '7 days' + INTERVAL '15 minutes',
 NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days' + INTERVAL '15 minutes'),

-- 10: Karan, fever + breathing, 5 days ago
(5, 2, 3, 2, 2,
 19.01000000, 73.11000000, 'Panvel Station Road, Navi Mumbai',
 'COMPLETED', 'High fever for 3 days, difficulty breathing, body aches', 'MEDIUM',
 NOW() - INTERVAL '5 days' + INTERVAL '32 minutes',
 NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days' + INTERVAL '32 minutes'),

-- 11: Rahul, palpitations, 3 days ago
(1, 3, 5, 4, 3,
 19.02000000, 73.04200000, 'Sector 15, CBD Belapur, Navi Mumbai',
 'COMPLETED', 'Heart palpitations, anxiety, chest tightness', 'HIGH',
 NOW() - INTERVAL '3 days' + INTERVAL '20 minutes',
 NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days' + INTERVAL '20 minutes'),

-- 12: Priya, minor accident, 1 day ago
(2, 1, 2, 3, 1,
 19.15500000, 73.02000000, 'Airoli Bridge, Navi Mumbai',
 'COMPLETED', 'Minor road accident, neck pain, suspected whiplash', 'LOW',
 NOW() - INTERVAL '1 day' + INTERVAL '25 minutes',
 NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day' + INTERVAL '25 minutes');

-- ============================================================
-- ACTIVE SOS EVENTS (13-14) for demo
-- ============================================================

-- 13: Amit - CREATED (fresh dispatch demo, no assignment yet)
INSERT INTO sos_events (user_id, hospital_id, latitude, longitude, address,
    status, symptoms, criticality, created_at, updated_at) VALUES
(3, NULL, 19.03700000, 73.07000000, 'Near Kharghar Railway Station, Navi Mumbai',
 'CREATED', 'Sudden chest tightness, profuse sweating, numbness in left hand', 'HIGH',
 NOW() - INTERVAL '2 minutes', NOW() - INTERVAL '2 minutes');

-- 14: Rahul - DRIVER_ENROUTE_TO_PATIENT (live tracking demo)
INSERT INTO sos_events (user_id, hospital_id, ambulance_id, driver_id, doctor_id,
    latitude, longitude, address, status, symptoms, criticality,
    created_at, updated_at) VALUES
(1, 1, 1, 1, 1,
 19.07300000, 73.00800000, 'Sector 10, Vashi, Navi Mumbai',
 'DRIVER_ENROUTE_TO_PATIENT', 'Found unconscious on road, possible head injury, bleeding from forehead', 'CRITICAL',
 NOW() - INTERVAL '8 minutes', NOW() - INTERVAL '3 minutes');

-- Mark ambulance MH-43-AB-1001 as DISPATCHED and driver 1 as BUSY
UPDATE ambulances SET status = 'DISPATCHED',
    current_latitude = 19.07550000, current_longitude = 73.00300000,
    updated_at = NOW()
WHERE id = 1;

UPDATE drivers SET status = 'BUSY', updated_at = NOW() WHERE id = 1;

-- ============================================================
-- TRIAGE RECORDS (one per completed event)
-- ============================================================

INSERT INTO triage_records (sos_event_id, heart_rate, systolic_bp, diastolic_bp,
    spo2, temperature, notes, recorded_at, created_at) VALUES
(1,  112, 160, 95, 91, 37.00, 'ECG shows ST elevation. Suspected STEMI. Oxygen administered.',
     NOW() - INTERVAL '28 days' + INTERVAL '12 minutes', NOW() - INTERVAL '28 days' + INTERVAL '12 minutes'),
(2,  98,  130, 85, 96, 36.90, 'Open fracture right tibia. Splint applied. Patient conscious and oriented.',
     NOW() - INTERVAL '25 days' + INTERVAL '10 minutes', NOW() - INTERVAL '25 days' + INTERVAL '10 minutes'),
(3,  120, 90,  60, 89, 37.30, 'Anaphylaxis grade III. Lip and tongue edema. Stridor present.',
     NOW() - INTERVAL '23 days' + INTERVAL '8 minutes',  NOW() - INTERVAL '23 days' + INTERVAL '8 minutes'),
(4,  65,  100, 65, 97, 36.60, 'Vasovagal syncope. No head injury. Patient recovered after lying down.',
     NOW() - INTERVAL '20 days' + INTERVAL '10 minutes', NOW() - INTERVAL '20 days' + INTERVAL '10 minutes'),
(5,  105, 135, 88, 88, 36.80, 'Severe bronchospasm. Accessory muscle use. Peak flow 150 L/min.',
     NOW() - INTERVAL '18 days' + INTERVAL '8 minutes',  NOW() - INTERVAL '18 days' + INTERVAL '8 minutes'),
(6,  88,  125, 80, 98, 37.90, 'Right lower quadrant tenderness. Guarding present. Suspect appendicitis.',
     NOW() - INTERVAL '15 days' + INTERVAL '12 minutes', NOW() - INTERVAL '15 days' + INTERVAL '12 minutes'),
(7,  92,  140, 90, 96, 37.00, 'Thoracolumbar tenderness. No neurological deficit. Cervical collar applied.',
     NOW() - INTERVAL '12 days' + INTERVAL '7 minutes',  NOW() - INTERVAL '12 days' + INTERVAL '7 minutes'),
(8,  115, 150, 95, 90, 38.60, 'Post-ictal state. GCS 10. Tongue bite noted. No focal deficit.',
     NOW() - INTERVAL '10 days' + INTERVAL '9 minutes',  NOW() - INTERVAL '10 days' + INTERVAL '9 minutes'),
(9,  108, 110, 70, 95, 37.00, 'Deep laceration 8cm, radial artery spared. Pressure bandage applied.',
     NOW() - INTERVAL '7 days' + INTERVAL '6 minutes',   NOW() - INTERVAL '7 days' + INTERVAL '6 minutes'),
(10, 96,  120, 78, 93, 39.60, 'Bilateral creps on auscultation. Suspect community-acquired pneumonia.',
     NOW() - INTERVAL '5 days' + INTERVAL '14 minutes',  NOW() - INTERVAL '5 days' + INTERVAL '14 minutes'),
(11, 135, 155, 98, 96, 37.10, 'SVT on monitor. Vagal maneuvers attempted. Rate >150 bpm.',
     NOW() - INTERVAL '3 days' + INTERVAL '8 minutes',   NOW() - INTERVAL '3 days' + INTERVAL '8 minutes'),
(12, 78,  120, 80, 99, 37.00, 'Mild cervical sprain. Full ROM. No neurological signs. NEXUS negative.',
     NOW() - INTERVAL '1 day' + INTERVAL '10 minutes',   NOW() - INTERVAL '1 day' + INTERVAL '10 minutes');

-- ============================================================
-- MEDICATIONS (1-2 per completed event)
-- ============================================================

INSERT INTO medications (sos_event_id, name, dosage, notes, administered_at, created_at) VALUES
-- Event 1: Chest pain
(1,  'Aspirin',            '300mg chewable', 'Antiplatelet for suspected MI',
     NOW() - INTERVAL '28 days' + INTERVAL '14 minutes', NOW() - INTERVAL '28 days' + INTERVAL '14 minutes'),
(1,  'Nitroglycerin',      '0.4mg sublingual', 'Pain persisted; second dose considered at hospital',
     NOW() - INTERVAL '28 days' + INTERVAL '16 minutes', NOW() - INTERVAL '28 days' + INTERVAL '16 minutes'),

-- Event 2: Leg fracture
(2,  'Morphine',           '4mg IV',         'Pain management for open fracture',
     NOW() - INTERVAL '25 days' + INTERVAL '12 minutes', NOW() - INTERVAL '25 days' + INTERVAL '12 minutes'),
(2,  'Tetanus Toxoid',     '0.5ml IM',       'Prophylaxis for open wound',
     NOW() - INTERVAL '25 days' + INTERVAL '15 minutes', NOW() - INTERVAL '25 days' + INTERVAL '15 minutes'),

-- Event 3: Allergic reaction
(3,  'Epinephrine',        '0.3mg IM',       'Auto-injector for anaphylaxis',
     NOW() - INTERVAL '23 days' + INTERVAL '9 minutes',  NOW() - INTERVAL '23 days' + INTERVAL '9 minutes'),
(3,  'Diphenhydramine',    '50mg IV',        'Adjunct antihistamine',
     NOW() - INTERVAL '23 days' + INTERVAL '12 minutes', NOW() - INTERVAL '23 days' + INTERVAL '12 minutes'),

-- Event 4: Fainting
(4,  'Normal Saline',      '500ml IV bolus', 'Volume resuscitation for hypotension',
     NOW() - INTERVAL '20 days' + INTERVAL '12 minutes', NOW() - INTERVAL '20 days' + INTERVAL '12 minutes'),

-- Event 5: Asthma
(5,  'Salbutamol',         '5mg nebulizer',  'Continuous nebulization in ambulance',
     NOW() - INTERVAL '18 days' + INTERVAL '10 minutes', NOW() - INTERVAL '18 days' + INTERVAL '10 minutes'),
(5,  'Prednisolone',       '40mg oral',      'Systemic corticosteroid for severe exacerbation',
     NOW() - INTERVAL '18 days' + INTERVAL '12 minutes', NOW() - INTERVAL '18 days' + INTERVAL '12 minutes'),

-- Event 6: Abdominal pain
(6,  'Ondansetron',        '4mg IV',         'Anti-emetic',
     NOW() - INTERVAL '15 days' + INTERVAL '14 minutes', NOW() - INTERVAL '15 days' + INTERVAL '14 minutes'),
(6,  'Pantoprazole',       '40mg IV',        'Proton pump inhibitor',
     NOW() - INTERVAL '15 days' + INTERVAL '16 minutes', NOW() - INTERVAL '15 days' + INTERVAL '16 minutes'),

-- Event 7: Back injury
(7,  'Diclofenac',         '75mg IM',        'NSAID for acute pain',
     NOW() - INTERVAL '12 days' + INTERVAL '9 minutes',  NOW() - INTERVAL '12 days' + INTERVAL '9 minutes'),

-- Event 8: Seizure
(8,  'Diazepam',           '5mg IV',         'Benzodiazepine for seizure termination',
     NOW() - INTERVAL '10 days' + INTERVAL '10 minutes', NOW() - INTERVAL '10 days' + INTERVAL '10 minutes'),
(8,  'Levetiracetam',      '1000mg IV',      'Anti-epileptic loading dose',
     NOW() - INTERVAL '10 days' + INTERVAL '14 minutes', NOW() - INTERVAL '10 days' + INTERVAL '14 minutes'),

-- Event 9: Bleeding wound
(9,  'Tranexamic Acid',    '1g IV',          'Antifibrinolytic for hemorrhage control',
     NOW() - INTERVAL '7 days' + INTERVAL '8 minutes',   NOW() - INTERVAL '7 days' + INTERVAL '8 minutes'),
(9,  'Lidocaine',          '10ml local infiltration', 'Local anesthesia for wound exploration',
     NOW() - INTERVAL '7 days' + INTERVAL '10 minutes',  NOW() - INTERVAL '7 days' + INTERVAL '10 minutes'),

-- Event 10: Fever + breathing
(10, 'Paracetamol',        '1g IV',          'Antipyretic',
     NOW() - INTERVAL '5 days' + INTERVAL '16 minutes',  NOW() - INTERVAL '5 days' + INTERVAL '16 minutes'),

-- Event 11: Palpitations
(11, 'Metoprolol',         '5mg IV',         'Rate control for SVT',
     NOW() - INTERVAL '3 days' + INTERVAL '10 minutes',  NOW() - INTERVAL '3 days' + INTERVAL '10 minutes'),
(11, 'Lorazepam',          '1mg IV',         'Anxiolytic',
     NOW() - INTERVAL '3 days' + INTERVAL '12 minutes',  NOW() - INTERVAL '3 days' + INTERVAL '12 minutes'),

-- Event 12: Minor accident
(12, 'Ibuprofen',          '400mg oral',     'Analgesic for cervical sprain',
     NOW() - INTERVAL '1 day' + INTERVAL '12 minutes',   NOW() - INTERVAL '1 day' + INTERVAL '12 minutes');

-- ============================================================
-- LOCATION UPDATES (GPS trails for completed events + active event 14)
-- Each trail: hospital departure → en route → patient pickup → return to hospital
-- ============================================================

INSERT INTO location_updates (sos_event_id, ambulance_id, latitude, longitude, recorded_at, created_at) VALUES

-- Event 1: Amb 1, Vashi hospital → Sector 17 → back (28 days ago)
(1, 1, 19.07710000, 73.00130000, NOW() - INTERVAL '28 days' + INTERVAL '3 minutes',  NOW() - INTERVAL '28 days' + INTERVAL '3 minutes'),
(1, 1, 19.07500000, 73.00250000, NOW() - INTERVAL '28 days' + INTERVAL '6 minutes',  NOW() - INTERVAL '28 days' + INTERVAL '6 minutes'),
(1, 1, 19.07200000, 73.00400000, NOW() - INTERVAL '28 days' + INTERVAL '9 minutes',  NOW() - INTERVAL '28 days' + INTERVAL '9 minutes'),
(1, 1, 19.07000000, 73.00500000, NOW() - INTERVAL '28 days' + INTERVAL '12 minutes', NOW() - INTERVAL '28 days' + INTERVAL '12 minutes'),
(1, 1, 19.07200000, 73.00350000, NOW() - INTERVAL '28 days' + INTERVAL '20 minutes', NOW() - INTERVAL '28 days' + INTERVAL '20 minutes'),
(1, 1, 19.07500000, 73.00200000, NOW() - INTERVAL '28 days' + INTERVAL '28 minutes', NOW() - INTERVAL '28 days' + INTERVAL '28 minutes'),
(1, 1, 19.07710000, 73.00130000, NOW() - INTERVAL '28 days' + INTERVAL '34 minutes', NOW() - INTERVAL '28 days' + INTERVAL '34 minutes'),

-- Event 2: Amb 3, Kamothe hospital → Sector 12 → back (25 days ago)
(2, 3, 19.01780000, 73.09870000, NOW() - INTERVAL '25 days' + INTERVAL '2 minutes',  NOW() - INTERVAL '25 days' + INTERVAL '2 minutes'),
(2, 3, 19.02000000, 73.09500000, NOW() - INTERVAL '25 days' + INTERVAL '5 minutes',  NOW() - INTERVAL '25 days' + INTERVAL '5 minutes'),
(2, 3, 19.02300000, 73.09100000, NOW() - INTERVAL '25 days' + INTERVAL '8 minutes',  NOW() - INTERVAL '25 days' + INTERVAL '8 minutes'),
(2, 3, 19.02500000, 73.08800000, NOW() - INTERVAL '25 days' + INTERVAL '10 minutes', NOW() - INTERVAL '25 days' + INTERVAL '10 minutes'),
(2, 3, 19.02300000, 73.09200000, NOW() - INTERVAL '25 days' + INTERVAL '18 minutes', NOW() - INTERVAL '25 days' + INTERVAL '18 minutes'),
(2, 3, 19.01780000, 73.09870000, NOW() - INTERVAL '25 days' + INTERVAL '27 minutes', NOW() - INTERVAL '25 days' + INTERVAL '27 minutes'),

-- Event 3: Amb 2, Vashi → Sanpada → back (23 days ago)
(3, 2, 19.06300000, 73.01200000, NOW() - INTERVAL '23 days' + INTERVAL '2 minutes',  NOW() - INTERVAL '23 days' + INTERVAL '2 minutes'),
(3, 2, 19.06250000, 73.01100000, NOW() - INTERVAL '23 days' + INTERVAL '4 minutes',  NOW() - INTERVAL '23 days' + INTERVAL '4 minutes'),
(3, 2, 19.06200000, 73.01000000, NOW() - INTERVAL '23 days' + INTERVAL '6 minutes',  NOW() - INTERVAL '23 days' + INTERVAL '6 minutes'),
(3, 2, 19.06250000, 73.01100000, NOW() - INTERVAL '23 days' + INTERVAL '14 minutes', NOW() - INTERVAL '23 days' + INTERVAL '14 minutes'),
(3, 2, 19.07000000, 73.00500000, NOW() - INTERVAL '23 days' + INTERVAL '18 minutes', NOW() - INTERVAL '23 days' + INTERVAL '18 minutes'),
(3, 2, 19.07710000, 73.00130000, NOW() - INTERVAL '23 days' + INTERVAL '21 minutes', NOW() - INTERVAL '23 days' + INTERVAL '21 minutes'),

-- Event 4: Amb 5, CBD Belapur → Sector 11 → back (20 days ago)
(4, 5, 19.02200000, 73.04000000, NOW() - INTERVAL '20 days' + INTERVAL '3 minutes',  NOW() - INTERVAL '20 days' + INTERVAL '3 minutes'),
(4, 5, 19.02400000, 73.03800000, NOW() - INTERVAL '20 days' + INTERVAL '5 minutes',  NOW() - INTERVAL '20 days' + INTERVAL '5 minutes'),
(4, 5, 19.02600000, 73.03500000, NOW() - INTERVAL '20 days' + INTERVAL '8 minutes',  NOW() - INTERVAL '20 days' + INTERVAL '8 minutes'),
(4, 5, 19.02400000, 73.03700000, NOW() - INTERVAL '20 days' + INTERVAL '16 minutes', NOW() - INTERVAL '20 days' + INTERVAL '16 minutes'),
(4, 5, 19.02350000, 73.03880000, NOW() - INTERVAL '20 days' + INTERVAL '24 minutes', NOW() - INTERVAL '20 days' + INTERVAL '24 minutes'),

-- Event 5: Amb 1, Vashi → Turbhe → back (18 days ago)
(5, 1, 19.07710000, 73.00130000, NOW() - INTERVAL '18 days' + INTERVAL '2 minutes',  NOW() - INTERVAL '18 days' + INTERVAL '2 minutes'),
(5, 1, 19.07400000, 73.00800000, NOW() - INTERVAL '18 days' + INTERVAL '5 minutes',  NOW() - INTERVAL '18 days' + INTERVAL '5 minutes'),
(5, 1, 19.07000000, 73.01500000, NOW() - INTERVAL '18 days' + INTERVAL '7 minutes',  NOW() - INTERVAL '18 days' + INTERVAL '7 minutes'),
(5, 1, 19.06800000, 73.02000000, NOW() - INTERVAL '18 days' + INTERVAL '9 minutes',  NOW() - INTERVAL '18 days' + INTERVAL '9 minutes'),
(5, 1, 19.07200000, 73.01200000, NOW() - INTERVAL '18 days' + INTERVAL '14 minutes', NOW() - INTERVAL '18 days' + INTERVAL '14 minutes'),
(5, 1, 19.07710000, 73.00130000, NOW() - INTERVAL '18 days' + INTERVAL '19 minutes', NOW() - INTERVAL '18 days' + INTERVAL '19 minutes'),

-- Event 6: Amb 4, Kamothe → Kharghar → back (15 days ago)
(6, 4, 19.03450000, 73.07200000, NOW() - INTERVAL '15 days' + INTERVAL '3 minutes',  NOW() - INTERVAL '15 days' + INTERVAL '3 minutes'),
(6, 4, 19.03600000, 73.07000000, NOW() - INTERVAL '15 days' + INTERVAL '6 minutes',  NOW() - INTERVAL '15 days' + INTERVAL '6 minutes'),
(6, 4, 19.03800000, 73.06800000, NOW() - INTERVAL '15 days' + INTERVAL '9 minutes',  NOW() - INTERVAL '15 days' + INTERVAL '9 minutes'),
(6, 4, 19.03000000, 73.07500000, NOW() - INTERVAL '15 days' + INTERVAL '18 minutes', NOW() - INTERVAL '15 days' + INTERVAL '18 minutes'),
(6, 4, 19.02200000, 73.08800000, NOW() - INTERVAL '15 days' + INTERVAL '24 minutes', NOW() - INTERVAL '15 days' + INTERVAL '24 minutes'),
(6, 4, 19.01780000, 73.09870000, NOW() - INTERVAL '15 days' + INTERVAL '29 minutes', NOW() - INTERVAL '15 days' + INTERVAL '29 minutes'),

-- Event 7: Amb 2, Sanpada → Juinagar → Vashi hospital (12 days ago)
(7, 2, 19.06300000, 73.01200000, NOW() - INTERVAL '12 days' + INTERVAL '2 minutes',  NOW() - INTERVAL '12 days' + INTERVAL '2 minutes'),
(7, 2, 19.05900000, 73.01000000, NOW() - INTERVAL '12 days' + INTERVAL '4 minutes',  NOW() - INTERVAL '12 days' + INTERVAL '4 minutes'),
(7, 2, 19.05600000, 73.00800000, NOW() - INTERVAL '12 days' + INTERVAL '5 minutes',  NOW() - INTERVAL '12 days' + INTERVAL '5 minutes'),
(7, 2, 19.06200000, 73.00600000, NOW() - INTERVAL '12 days' + INTERVAL '10 minutes', NOW() - INTERVAL '12 days' + INTERVAL '10 minutes'),
(7, 2, 19.07000000, 73.00300000, NOW() - INTERVAL '12 days' + INTERVAL '14 minutes', NOW() - INTERVAL '12 days' + INTERVAL '14 minutes'),
(7, 2, 19.07710000, 73.00130000, NOW() - INTERVAL '12 days' + INTERVAL '17 minutes', NOW() - INTERVAL '12 days' + INTERVAL '17 minutes'),

-- Event 8: Amb 6, CBD Belapur → Nerul → back (10 days ago)
(8, 6, 19.03300000, 73.01650000, NOW() - INTERVAL '10 days' + INTERVAL '2 minutes',  NOW() - INTERVAL '10 days' + INTERVAL '2 minutes'),
(8, 6, 19.03400000, 73.01700000, NOW() - INTERVAL '10 days' + INTERVAL '5 minutes',  NOW() - INTERVAL '10 days' + INTERVAL '5 minutes'),
(8, 6, 19.03500000, 73.01800000, NOW() - INTERVAL '10 days' + INTERVAL '7 minutes',  NOW() - INTERVAL '10 days' + INTERVAL '7 minutes'),
(8, 6, 19.03100000, 73.02500000, NOW() - INTERVAL '10 days' + INTERVAL '14 minutes', NOW() - INTERVAL '10 days' + INTERVAL '14 minutes'),
(8, 6, 19.02700000, 73.03200000, NOW() - INTERVAL '10 days' + INTERVAL '19 minutes', NOW() - INTERVAL '10 days' + INTERVAL '19 minutes'),
(8, 6, 19.02350000, 73.03880000, NOW() - INTERVAL '10 days' + INTERVAL '23 minutes', NOW() - INTERVAL '10 days' + INTERVAL '23 minutes'),

-- Event 9: Amb 1, Vashi → Palm Beach Rd → back (7 days ago)
(9, 1, 19.07710000, 73.00130000, NOW() - INTERVAL '7 days' + INTERVAL '2 minutes',  NOW() - INTERVAL '7 days' + INTERVAL '2 minutes'),
(9, 1, 19.06500000, 73.01000000, NOW() - INTERVAL '7 days' + INTERVAL '4 minutes',  NOW() - INTERVAL '7 days' + INTERVAL '4 minutes'),
(9, 1, 19.04800000, 73.02500000, NOW() - INTERVAL '7 days' + INTERVAL '6 minutes',  NOW() - INTERVAL '7 days' + INTERVAL '6 minutes'),
(9, 1, 19.05500000, 73.01800000, NOW() - INTERVAL '7 days' + INTERVAL '10 minutes', NOW() - INTERVAL '7 days' + INTERVAL '10 minutes'),
(9, 1, 19.07710000, 73.00130000, NOW() - INTERVAL '7 days' + INTERVAL '14 minutes', NOW() - INTERVAL '7 days' + INTERVAL '14 minutes'),

-- Event 10: Amb 3, Kamothe → Panvel → back (5 days ago)
(10, 3, 19.01780000, 73.09870000, NOW() - INTERVAL '5 days' + INTERVAL '3 minutes',  NOW() - INTERVAL '5 days' + INTERVAL '3 minutes'),
(10, 3, 19.01500000, 73.10300000, NOW() - INTERVAL '5 days' + INTERVAL '7 minutes',  NOW() - INTERVAL '5 days' + INTERVAL '7 minutes'),
(10, 3, 19.01200000, 73.10700000, NOW() - INTERVAL '5 days' + INTERVAL '10 minutes', NOW() - INTERVAL '5 days' + INTERVAL '10 minutes'),
(10, 3, 19.01000000, 73.11000000, NOW() - INTERVAL '5 days' + INTERVAL '13 minutes', NOW() - INTERVAL '5 days' + INTERVAL '13 minutes'),
(10, 3, 19.01300000, 73.10500000, NOW() - INTERVAL '5 days' + INTERVAL '20 minutes', NOW() - INTERVAL '5 days' + INTERVAL '20 minutes'),
(10, 3, 19.01780000, 73.09870000, NOW() - INTERVAL '5 days' + INTERVAL '31 minutes', NOW() - INTERVAL '5 days' + INTERVAL '31 minutes'),

-- Event 11: Amb 5, CBD Belapur → Sector 15 → back (3 days ago)
(11, 5, 19.02350000, 73.03880000, NOW() - INTERVAL '3 days' + INTERVAL '2 minutes',  NOW() - INTERVAL '3 days' + INTERVAL '2 minutes'),
(11, 5, 19.02200000, 73.04000000, NOW() - INTERVAL '3 days' + INTERVAL '4 minutes',  NOW() - INTERVAL '3 days' + INTERVAL '4 minutes'),
(11, 5, 19.02000000, 73.04200000, NOW() - INTERVAL '3 days' + INTERVAL '6 minutes',  NOW() - INTERVAL '3 days' + INTERVAL '6 minutes'),
(11, 5, 19.02100000, 73.04100000, NOW() - INTERVAL '3 days' + INTERVAL '12 minutes', NOW() - INTERVAL '3 days' + INTERVAL '12 minutes'),
(11, 5, 19.02350000, 73.03880000, NOW() - INTERVAL '3 days' + INTERVAL '19 minutes', NOW() - INTERVAL '3 days' + INTERVAL '19 minutes'),

-- Event 12: Amb 2, Sanpada → Airoli → Vashi hospital (1 day ago)
(12, 2, 19.06300000, 73.01200000, NOW() - INTERVAL '1 day' + INTERVAL '3 minutes',  NOW() - INTERVAL '1 day' + INTERVAL '3 minutes'),
(12, 2, 19.08000000, 73.01500000, NOW() - INTERVAL '1 day' + INTERVAL '6 minutes',  NOW() - INTERVAL '1 day' + INTERVAL '6 minutes'),
(12, 2, 19.10000000, 73.01800000, NOW() - INTERVAL '1 day' + INTERVAL '9 minutes',  NOW() - INTERVAL '1 day' + INTERVAL '9 minutes'),
(12, 2, 19.13000000, 73.02000000, NOW() - INTERVAL '1 day' + INTERVAL '12 minutes', NOW() - INTERVAL '1 day' + INTERVAL '12 minutes'),
(12, 2, 19.15500000, 73.02000000, NOW() - INTERVAL '1 day' + INTERVAL '14 minutes', NOW() - INTERVAL '1 day' + INTERVAL '14 minutes'),
(12, 2, 19.13000000, 73.01800000, NOW() - INTERVAL '1 day' + INTERVAL '18 minutes', NOW() - INTERVAL '1 day' + INTERVAL '18 minutes'),
(12, 2, 19.10000000, 73.01200000, NOW() - INTERVAL '1 day' + INTERVAL '21 minutes', NOW() - INTERVAL '1 day' + INTERVAL '21 minutes'),
(12, 2, 19.07710000, 73.00130000, NOW() - INTERVAL '1 day' + INTERVAL '24 minutes', NOW() - INTERVAL '1 day' + INTERVAL '24 minutes'),

-- Event 14 (active): Amb 1 dispatched from Vashi, en route to Sector 10
(14, 1, 19.07710000, 73.00130000, NOW() - INTERVAL '7 minutes', NOW() - INTERVAL '7 minutes'),
(14, 1, 19.07650000, 73.00250000, NOW() - INTERVAL '6 minutes', NOW() - INTERVAL '6 minutes'),
(14, 1, 19.07600000, 73.00350000, NOW() - INTERVAL '5 minutes', NOW() - INTERVAL '5 minutes'),
(14, 1, 19.07550000, 73.00500000, NOW() - INTERVAL '4 minutes', NOW() - INTERVAL '4 minutes'),
(14, 1, 19.07500000, 73.00650000, NOW() - INTERVAL '3 minutes', NOW() - INTERVAL '3 minutes');
