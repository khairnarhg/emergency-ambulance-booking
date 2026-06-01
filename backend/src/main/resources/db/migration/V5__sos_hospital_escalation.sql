-- SOS Hospital Escalation: Track hospital notification/response history and add timestamps

-- Add timestamps for escalation tracking
ALTER TABLE sos_events ADD COLUMN assigned_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE sos_events ADD COLUMN dispatched_at TIMESTAMP WITH TIME ZONE;

-- Backfill existing records: use created_at as assigned_at
UPDATE sos_events SET assigned_at = created_at WHERE assigned_at IS NULL;

-- Track which hospitals have been notified for each SOS and their response
CREATE TABLE sos_hospital_history (
    id BIGSERIAL PRIMARY KEY,
    sos_event_id BIGINT NOT NULL REFERENCES sos_events(id) ON DELETE CASCADE,
    hospital_id BIGINT NOT NULL REFERENCES hospitals(id),
    notified_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    responded_at TIMESTAMP WITH TIME ZONE,
    response VARCHAR(20) CHECK (response IN ('ACCEPTED', 'DECLINED', 'TIMEOUT', 'NO_AMBULANCE', 'DRIVER_TIMEOUT')),
    UNIQUE(sos_event_id, hospital_id)
);

CREATE INDEX idx_sos_hospital_history_sos ON sos_hospital_history(sos_event_id);
CREATE INDEX idx_sos_hospital_history_hospital ON sos_hospital_history(hospital_id);
