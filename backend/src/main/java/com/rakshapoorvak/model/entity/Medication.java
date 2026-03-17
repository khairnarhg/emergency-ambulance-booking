package com.rakshapoorvak.model.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;

/**
 * Medication administered during an SOS event.
 */
@Entity
@Table(name = "medications")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Medication {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "sos_event_id", nullable = false)
    private SosEvent sosEvent;

    @Column(name = "name", nullable = false, length = 255)
    private String name;

    @Column(name = "dosage", length = 100)
    private String dosage;

    @Column(name = "notes", columnDefinition = "TEXT")
    private String notes;

    @Column(name = "administered_at")
    private Instant administeredAt;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @PrePersist
    void onCreate() {
        if (createdAt == null) createdAt = Instant.now();
        if (administeredAt == null) administeredAt = Instant.now();
    }
}
