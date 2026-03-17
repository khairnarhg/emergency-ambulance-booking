package com.rakshapoorvak.model.dto.analytics;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class EmergencyVolumeDto {

    private List<VolumeBucketDto> byDay;
    private List<VolumeBucketDto> byHour;
}
