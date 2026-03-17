package com.rakshapoorvak.model.dto.user;

import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UpdateMedicalProfileRequest {

    @Size(max = 10)
    private String bloodGroup;

    private String allergies;
    private String conditions;
    private String notes;
}
