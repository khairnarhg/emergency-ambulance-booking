# RakshaPoorvak Seed Data

Run these scripts **after** the backend has created the schema (via Flyway on first run).

## Order

1. `01_hospitals.sql` - Hospitals
2. `02_users_and_roles.sql` - Users and role assignments
3. `03_hospital_staff_doctors_drivers.sql` - Staff, doctors, drivers
4. `04_ambulances.sql` - Ambulances
5. `05_medical_profiles_emergency_contacts.sql` - Patient medical data
6. `06_sample_sos_events.sql` - Sample SOS events

## Running

From project root:

```bash
./scripts/seed-all.sh
```

Or manually with psql:

```bash
export DB_NAME=rakshapoorvak_dev
export DB_USER=rakshapoorvak
export DB_PASSWORD=dev_password

for f in seed/*.sql; do
  psql -h localhost -U $DB_USER -d $DB_NAME -f "$f"
done
```

## Test Credentials

| Role    | Email              | Password    |
|---------|--------------------|-------------|
| Patient | patient1@test.com  | password123 |
| Patient | patient2@test.com  | password123 |
| Driver  | driver1@test.com   | password123 |
| Driver  | driver2@test.com   | password123 |
| Staff   | staff@hospital.com | password123 |
| Doctor  | doctor1@test.com   | password123 |
| Doctor  | doctor2@test.com   | password123 |
