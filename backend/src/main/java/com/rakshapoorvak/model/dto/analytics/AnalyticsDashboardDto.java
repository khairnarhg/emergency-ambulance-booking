package com.rakshapoorvak.model.dto.analytics;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AnalyticsDashboardDto {

    private ResponseTimeDto responseTimes;
    private EmergencyVolumeDto emergencyVolume;
    private java.util.List<com.rakshapoorvak.model.dto.analytics.VolumeBucketDto> volume;
    private long totalSosCount;
    private java.util.Map<String, Long> bySeverity;
    private java.util.Map<String, Long> ambulanceUtilization;
}
