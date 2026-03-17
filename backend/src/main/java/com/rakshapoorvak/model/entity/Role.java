package com.rakshapoorvak.model.entity;

import com.rakshapoorvak.model.entity.enums.RoleName;
import jakarta.persistence.*;
import lombok.*;

/**
 * Role entity for RBAC.
 */
@Entity
@Table(name = "roles")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Role {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Enumerated(EnumType.STRING)
    @Column(name = "name", nullable = false, unique = true, length = 50)
    private RoleName name;
}
