package com.rakshapoorvak.model.dto.dashboard;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DashboardSummaryDto {

    private long totalSosToday;
    private long activeSosCount;
    private long availableAmbulances;
    private long totalAmbulances;
    private long availableDoctors;
    private long totalDoctors;
    private double avgResponseTimeMinutes;
    private List<SosSummaryItemDto> activeSosList;
}
