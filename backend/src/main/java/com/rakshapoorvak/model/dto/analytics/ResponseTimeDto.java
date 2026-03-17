package com.rakshapoorvak.model.dto.analytics;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ResponseTimeDto {

    private Double averageMinutes;
    private Double medianMinutes;
    private Double minMinutes;
    private Double maxMinutes;
    private long totalCompleted;
}
