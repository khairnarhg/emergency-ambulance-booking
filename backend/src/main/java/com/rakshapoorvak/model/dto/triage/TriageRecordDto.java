package com.rakshapoorvak.model.dto.triage;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.Instant;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TriageRecordDto {

    private Long id;
    private Long sosEventId;
    private Integer heartRate;
    private Integer systolicBp;
    private Integer diastolicBp;
    private Integer spo2;
    private BigDecimal temperature;
    private String notes;
    private Instant recordedAt;
    private Instant createdAt;
}
