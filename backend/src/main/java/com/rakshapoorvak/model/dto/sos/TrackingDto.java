package com.rakshapoorvak.model.dto.sos;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TrackingDto {

    private Long sosEventId;
    private String status;
    private BigDecimal ambulanceLatitude;
    private BigDecimal ambulanceLongitude;
    private String driverName;
    private String driverPhone;
    private String ambulanceRegistrationNumber;
    private String hospitalName;
    private String hospitalAddress;
    private Integer estimatedMinutesArrival;
    private List<LocationPointDto> locationHistory;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class LocationPointDto {
        private BigDecimal latitude;
        private BigDecimal longitude;
        private String recordedAt;
    }
}
