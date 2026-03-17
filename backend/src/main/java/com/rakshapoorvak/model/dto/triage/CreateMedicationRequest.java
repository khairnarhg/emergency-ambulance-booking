package com.rakshapoorvak.model.dto.triage;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateMedicationRequest {

    @NotNull(message = "SOS event ID is required")
    private Long sosEventId;

    @NotBlank(message = "Medication name is required")
    @Size(max = 255)
    private String name;

    @Size(max = 100)
    private String dosage;

    private String notes;
}
