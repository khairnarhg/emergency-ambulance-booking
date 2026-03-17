package com.rakshapoorvak.model.dto.map;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MapOverviewDto {

    private List<AmbulanceMapMarkerDto> ambulances;
    private List<SosMapMarkerDto> sosEvents;
    private List<com.rakshapoorvak.model.dto.hospital.HospitalDto> hospitals;
}
