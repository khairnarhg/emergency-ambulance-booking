package com.rakshapoorvak.model.dto.triage;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MedicationDto {

    private Long id;
    private Long sosEventId;
    private String name;
    private String dosage;
    private String notes;
    private Instant administeredAt;
}
