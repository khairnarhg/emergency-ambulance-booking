-- Add location_updated_at column to track when ambulance location was last updated
ALTER TABLE ambulances ADD COLUMN location_updated_at TIMESTAMP WITH TIME ZONE;
