-- RakshaPoorvak Seed: Notifications for all recipient types
-- recipient_type: USER, DRIVER, HOSPITAL
-- recipient_id: user_id for USER/DRIVER, hospital_id for HOSPITAL

TRUNCATE TABLE notifications RESTART IDENTITY CASCADE;

INSERT INTO notifications (recipient_type, recipient_id, title, body, is_read, created_at) VALUES

-- === HOSPITAL notifications (recipient_id = hospital_id) ===

-- Active alert for event 13 (Amit, CREATED)
('HOSPITAL', 1, 'New SOS Alert – HIGH Priority',
 'Emergency reported near Kharghar Railway Station. Patient Amit Joshi reports chest tightness and sweating. Awaiting dispatch.',
 FALSE, NOW() - INTERVAL '2 minutes'),

-- Active alert for event 14 (Rahul, DRIVER_ENROUTE)
('HOSPITAL', 1, 'Ambulance Dispatched – CRITICAL',
 'MH-43-AB-1001 dispatched to Sector 10, Vashi. Driver Vikram Singh en route. Patient found unconscious with head injury.',
 FALSE, NOW() - INTERVAL '7 minutes'),

('HOSPITAL', 1, 'Driver En Route to Patient',
 'Vikram Singh (MH-43-AB-1001) is 3 minutes away from patient location at Sector 10, Vashi.',
 FALSE, NOW() - INTERVAL '4 minutes'),

-- Recent completed events
('HOSPITAL', 1, 'SOS Completed – Airoli Bridge',
 'Emergency #12 resolved. Patient Priya Patel treated for whiplash and transferred to ER. Total response time: 25 min.',
 TRUE, NOW() - INTERVAL '1 day' + INTERVAL '25 minutes'),

('HOSPITAL', 3, 'SOS Completed – CBD Belapur Sector 15',
 'Emergency #11 resolved. Patient Rahul Sharma treated for SVT. Rate controlled with IV Metoprolol. Response time: 20 min.',
 TRUE, NOW() - INTERVAL '3 days' + INTERVAL '20 minutes'),

('HOSPITAL', 1, 'SOS Completed – Palm Beach Road',
 'Emergency #9 resolved. Deep laceration managed. Patient Sneha Reddy transferred to surgical ward. Response time: 15 min.',
 TRUE, NOW() - INTERVAL '7 days' + INTERVAL '15 minutes'),

('HOSPITAL', 2, 'SOS Completed – Panvel Station Road',
 'Emergency #10 resolved. Patient Karan Mehta admitted for pneumonia workup. Response time: 32 min.',
 TRUE, NOW() - INTERVAL '5 days' + INTERVAL '32 minutes'),

('HOSPITAL', 1, 'Daily Summary – Vashi Branch',
 'Today: 0 active emergencies, 1 completed. Average response time: 18 min. All ambulances available.',
 TRUE, NOW() - INTERVAL '2 days'),

('HOSPITAL', 2, 'Ambulance Maintenance Reminder',
 'MH-43-CD-2002 is due for scheduled maintenance. Please coordinate with transport department.',
 FALSE, NOW() - INTERVAL '6 hours'),

-- === DRIVER notifications (recipient_id = user_id of driver) ===

-- Driver 1 (Vikram, user_id=6) – active dispatch
('DRIVER', 6, 'New Dispatch – CRITICAL',
 'Respond to Sector 10, Vashi. Patient unconscious with head injury. Use ambulance MH-43-AB-1001. Navigate via Vashi Bridge.',
 FALSE, NOW() - INTERVAL '7 minutes'),

('DRIVER', 6, 'SOS Completed',
 'Emergency at Palm Beach Road completed. Patient delivered to MGM Vashi ER. Good work.',
 TRUE, NOW() - INTERVAL '7 days' + INTERVAL '15 minutes'),

('DRIVER', 6, 'SOS Completed',
 'Emergency at Turbhe MIDC completed. Asthma patient stabilized and admitted.',
 TRUE, NOW() - INTERVAL '18 days' + INTERVAL '20 minutes'),

-- Driver 2 (Anil, user_id=7)
('DRIVER', 7, 'SOS Completed',
 'Emergency at Panvel Station Road completed. Patient admitted to MGM Kamothe.',
 TRUE, NOW() - INTERVAL '5 days' + INTERVAL '32 minutes'),

('DRIVER', 7, 'Shift Reminder',
 'Your next shift starts at 8:00 AM tomorrow at MGM Kamothe. Ambulance MH-43-CD-2001 assigned.',
 FALSE, NOW() - INTERVAL '12 hours'),

-- Driver 3 (Suresh, user_id=8)
('DRIVER', 8, 'SOS Completed',
 'Emergency at Airoli Bridge completed. Patient transferred to MGM Vashi.',
 TRUE, NOW() - INTERVAL '1 day' + INTERVAL '25 minutes'),

-- Driver 4 (Ravi, user_id=9)
('DRIVER', 9, 'SOS Completed',
 'Emergency at CBD Belapur Sector 15 completed. Cardiac patient stabilized.',
 TRUE, NOW() - INTERVAL '3 days' + INTERVAL '20 minutes'),

('DRIVER', 9, 'License Renewal Reminder',
 'Your license MH43-2022-11111 expires in 60 days. Please renew before expiry.',
 FALSE, NOW() - INTERVAL '1 day'),

-- === USER notifications (recipient_id = user_id of patient) ===

-- Rahul (user_id=1) – has active SOS
('USER', 1, 'SOS Received – Help is on the way!',
 'Your emergency has been received. Ambulance MH-43-AB-1001 dispatched from MGM Vashi. Driver Vikram Singh is en route. ETA: 5 minutes.',
 FALSE, NOW() - INTERVAL '7 minutes'),

('USER', 1, 'Emergency Resolved – CBD Belapur',
 'Your emergency on 3 days ago has been resolved. Treated for heart palpitations at MGM CBD Belapur. Follow-up recommended with cardiologist.',
 TRUE, NOW() - INTERVAL '3 days' + INTERVAL '20 minutes'),

('USER', 1, 'Emergency Resolved – Turbhe',
 'Your asthma emergency has been resolved. Please continue prescribed medications and keep inhaler accessible.',
 TRUE, NOW() - INTERVAL '18 days' + INTERVAL '20 minutes'),

-- Priya (user_id=2)
('USER', 2, 'Emergency Resolved – Airoli Bridge',
 'Your emergency has been resolved. Treated for cervical sprain at MGM Vashi. Wear cervical collar for 1 week as advised.',
 TRUE, NOW() - INTERVAL '1 day' + INTERVAL '25 minutes'),

('USER', 2, 'Emergency Resolved – Juinagar',
 'Your emergency has been resolved. Back injury treated at MGM Vashi. Follow up with orthopedic in 1 week.',
 TRUE, NOW() - INTERVAL '12 days' + INTERVAL '18 minutes'),

-- Amit (user_id=3) – has active SOS
('USER', 3, 'SOS Received – Processing',
 'Your emergency has been received. We are locating the nearest available ambulance. Please stay calm.',
 FALSE, NOW() - INTERVAL '2 minutes'),

('USER', 3, 'Emergency Resolved – Nerul',
 'Your seizure emergency has been resolved. Treated at MGM CBD Belapur. Anti-epileptic medication prescribed.',
 TRUE, NOW() - INTERVAL '10 days' + INTERVAL '24 minutes'),

-- Sneha (user_id=4)
('USER', 4, 'Emergency Resolved – Palm Beach Road',
 'Your emergency has been resolved. Wound treated at MGM Vashi. Sutures to be removed in 10 days.',
 TRUE, NOW() - INTERVAL '7 days' + INTERVAL '15 minutes'),

-- Karan (user_id=5)
('USER', 5, 'Emergency Resolved – Panvel',
 'Your emergency has been resolved. Admitted to MGM Kamothe for pneumonia treatment. Discharge expected in 3-5 days.',
 TRUE, NOW() - INTERVAL '5 days' + INTERVAL '32 minutes'),

('USER', 5, 'Medical Profile Reminder',
 'Your medical profile is incomplete. Adding allergies and emergency contacts helps us provide faster, better care.',
 FALSE, NOW() - INTERVAL '10 days');
