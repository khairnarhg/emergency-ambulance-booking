-- Add specialization to doctors and license_number to drivers
ALTER TABLE doctors ADD COLUMN IF NOT EXISTS specialization VARCHAR(100);
ALTER TABLE drivers ADD COLUMN IF NOT EXISTS license_number VARCHAR(50);
