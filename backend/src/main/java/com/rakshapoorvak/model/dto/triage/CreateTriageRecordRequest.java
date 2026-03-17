package com.rakshapoorvak.model.dto.triage;

import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateTriageRecordRequest {

    @NotNull(message = "SOS event ID is required")
    private Long sosEventId;

    private Integer heartRate;
    private Integer systolicBp;
    private Integer diastolicBp;
    private Integer spo2;
    private BigDecimal temperature;
    private String notes;
}
