-- Link drivers to their assigned ambulances
ALTER TABLE drivers ADD COLUMN IF NOT EXISTS ambulance_id BIGINT REFERENCES ambulances(id);
CREATE INDEX IF NOT EXISTS idx_drivers_ambulance ON drivers(ambulance_id);
