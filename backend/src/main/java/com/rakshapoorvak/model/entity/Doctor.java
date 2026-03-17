package com.rakshapoorvak.model.entity;

import com.rakshapoorvak.model.entity.enums.DoctorStatus;
import jakarta.persistence.*;
import lombok.*;

/**
 * Doctor entity linked to user and hospital.
 */
@Entity
@Table(name = "doctors")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Doctor extends BaseAuditEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "hospital_id", nullable = false)
    private Hospital hospital;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    @Builder.Default
    private DoctorStatus status = DoctorStatus.OFFLINE;

    @Column(name = "specialization", length = 100)
    private String specialization;
}
