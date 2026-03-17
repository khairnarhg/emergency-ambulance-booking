package com.rakshapoorvak.model.dto.ambulance;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AmbulanceLocationDto {

    private Long ambulanceId;
    private String registrationNumber;
    private BigDecimal latitude;
    private BigDecimal longitude;
}
