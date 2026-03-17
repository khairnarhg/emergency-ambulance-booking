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
public class SosMapMarkerDto {

    private Long id;
    private String status;
    private String criticality;
    private String userName;
    private BigDecimal latitude;
    private BigDecimal longitude;
}
