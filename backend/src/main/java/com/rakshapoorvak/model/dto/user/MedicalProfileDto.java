package com.rakshapoorvak.model.dto.user;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MedicalProfileDto {

    private Long id;
    private Long userId;
    private String bloodGroup;
    private String allergies;
    private String conditions;
    private String notes;
}
