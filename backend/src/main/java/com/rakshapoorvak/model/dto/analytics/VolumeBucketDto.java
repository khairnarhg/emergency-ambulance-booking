package com.rakshapoorvak.model.dto.analytics;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class VolumeBucketDto {

    private String label;
    private String date;
    private long count;
    private Instant startTime;
}
