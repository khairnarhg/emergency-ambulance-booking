package com.rakshapoorvak.model.entity;

import jakarta.persistence.*;
import lombok.*;

/**
 * User medical profile - blood group, allergies, conditions.
 */
@Entity
@Table(name = "medical_profiles")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MedicalProfile extends BaseAuditEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;

    @Column(name = "blood_group", length = 10)
    private String bloodGroup;

    @Column(name = "allergies", columnDefinition = "TEXT")
    private String allergies;

    @Column(name = "conditions", columnDefinition = "TEXT")
    private String conditions;

    @Column(name = "notes", columnDefinition = "TEXT")
    private String notes;
}
