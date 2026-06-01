package com.rakshapoorvak.model.entity;

import com.rakshapoorvak.model.entity.enums.EscalationReason;
import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "sos_hospital_history",
       uniqueConstraints = @UniqueConstraint(columnNames = {"sos_event_id", "hospital_id"}))
public class SosHospitalHistory {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "sos_event_id", nullable = false)
    private SosEvent sosEvent;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "hospital_id", nullable = false)
    private Hospital hospital;

    @Column(name = "notified_at", nullable = false)
    private Instant notifiedAt;

    @Column(name = "responded_at")
    private Instant respondedAt;

    @Enumerated(EnumType.STRING)
    @Column(name = "response", length = 20)
    private EscalationReason response;

    public SosHospitalHistory() {
    }

    public SosHospitalHistory(SosEvent sosEvent, Hospital hospital) {
        this.sosEvent = sosEvent;
        this.hospital = hospital;
        this.notifiedAt = Instant.now();
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public SosEvent getSosEvent() {
        return sosEvent;
    }

    public void setSosEvent(SosEvent sosEvent) {
        this.sosEvent = sosEvent;
    }

    public Hospital getHospital() {
        return hospital;
    }

    public void setHospital(Hospital hospital) {
        this.hospital = hospital;
    }

    public Instant getNotifiedAt() {
        return notifiedAt;
    }

    public void setNotifiedAt(Instant notifiedAt) {
        this.notifiedAt = notifiedAt;
    }

    public Instant getRespondedAt() {
        return respondedAt;
    }

    public void setRespondedAt(Instant respondedAt) {
        this.respondedAt = respondedAt;
    }

    public EscalationReason getResponse() {
        return response;
    }

    public void setResponse(EscalationReason response) {
        this.response = response;
    }
}
