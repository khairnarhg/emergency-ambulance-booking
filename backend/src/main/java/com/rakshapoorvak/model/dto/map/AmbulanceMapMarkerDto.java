package com.rakshapoorvak.model.dto.map;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AmbulanceMapMarkerDto {

    private Long id;
    private String registrationNumber;
    private BigDecimal latitude;
    private BigDecimal longitude;
    private String status;
}
