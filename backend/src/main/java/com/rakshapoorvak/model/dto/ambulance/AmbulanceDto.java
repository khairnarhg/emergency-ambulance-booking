package com.rakshapoorvak.model.dto.ambulance;

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
public class AmbulanceDto {

    private Long id;
    private Long hospitalId;
    private String hospitalName;
    private String registrationNumber;
    private String status;
    private BigDecimal currentLatitude;
    private BigDecimal currentLongitude;
    private Instant updatedAt;
}
