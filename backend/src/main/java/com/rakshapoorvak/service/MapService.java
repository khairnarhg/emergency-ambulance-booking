package com.rakshapoorvak.service;

import com.rakshapoorvak.model.dto.ambulance.AmbulanceLocationDto;
import com.rakshapoorvak.model.dto.hospital.HospitalDto;
import com.rakshapoorvak.model.dto.map.AmbulanceMapMarkerDto;
import com.rakshapoorvak.model.dto.map.MapOverviewDto;
import com.rakshapoorvak.model.dto.map.SosMapMarkerDto;
import com.rakshapoorvak.model.entity.Hospital;
import com.rakshapoorvak.model.entity.enums.SosStatus;
import com.rakshapoorvak.repository.AmbulanceRepository;
import com.rakshapoorvak.repository.HospitalRepository;
import com.rakshapoorvak.repository.SosEventRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Map data - ambulance locations, map overview.
 */
@Service
public class MapService {

    private static final Logger log = LoggerFactory.getLogger(MapService.class);

    private final AmbulanceRepository ambulanceRepository;
    private final SosEventRepository sosEventRepository;
    private final HospitalRepository hospitalRepository;

    public MapService(AmbulanceRepository ambulanceRepository, SosEventRepository sosEventRepository,
                      HospitalRepository hospitalRepository) {
        this.ambulanceRepository = ambulanceRepository;
        this.sosEventRepository = sosEventRepository;
        this.hospitalRepository = hospitalRepository;
    }

    @Transactional(readOnly = true)
    public List<AmbulanceLocationDto> getAmbulanceLocations(Long hospitalId) {
        var ambulances = hospitalId != null
                ? ambulanceRepository.findByHospitalId(hospitalId)
                : ambulanceRepository.findAll();
        return ambulances.stream()
                .filter(a -> a.getCurrentLatitude() != null && a.getCurrentLongitude() != null)
                .map(a -> AmbulanceLocationDto.builder()
                        .ambulanceId(a.getId())
                        .registrationNumber(a.getRegistrationNumber())
                        .latitude(a.getCurrentLatitude())
                        .longitude(a.getCurrentLongitude())
                        .build())
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public MapOverviewDto getMapOverview(Long hospitalId) {
        List<SosStatus> active = List.of(SosStatus.CREATED, SosStatus.DISPATCHING, SosStatus.AMBULANCE_ASSIGNED,
                SosStatus.DRIVER_ENROUTE_TO_PATIENT, SosStatus.REACHED_PATIENT, SosStatus.PICKED_UP,
                SosStatus.ENROUTE_TO_HOSPITAL, SosStatus.ARRIVED_AT_HOSPITAL);
        var activeSos = hospitalId != null
                ? sosEventRepository.findByHospitalIdAndStatusInOrderByCreatedAtDesc(hospitalId, active)
                : sosEventRepository.findByStatusIn(active, org.springframework.data.domain.PageRequest.of(0, 100));

        var ambulances = hospitalId != null
                ? ambulanceRepository.findByHospitalId(hospitalId)
                : ambulanceRepository.findAll();

        var ambulanceMarkers = ambulances.stream()
                .filter(a -> a.getCurrentLatitude() != null && a.getCurrentLongitude() != null)
                .map(a -> AmbulanceMapMarkerDto.builder()
                        .id(a.getId())
                        .registrationNumber(a.getRegistrationNumber())
                        .latitude(a.getCurrentLatitude())
                        .longitude(a.getCurrentLongitude())
                        .status(a.getStatus().name())
                        .build())
                .collect(Collectors.toList());

        var sosMarkers = activeSos.stream()
                .map(s -> SosMapMarkerDto.builder()
                        .id(s.getId())
                        .status(s.getStatus().name())
                        .criticality(s.getCriticality() != null ? s.getCriticality().name() : null)
                        .userName(s.getUser() != null ? s.getUser().getFullName() : null)
                        .latitude(s.getLatitude())
                        .longitude(s.getLongitude())
                        .build())
                .collect(Collectors.toList());

        List<Hospital> hospitalList = hospitalRepository.findAll();
        List<HospitalDto> hospitalDtos = hospitalList.stream()
                .map(h -> HospitalDto.builder()
                        .id(h.getId())
                        .name(h.getName())
                        .address(h.getAddress())
                        .latitude(h.getLatitude())
                        .longitude(h.getLongitude())
                        .build())
                .collect(Collectors.toList());

        return MapOverviewDto.builder()
                .ambulances(ambulanceMarkers)
                .sosEvents(sosMarkers)
                .hospitals(hospitalDtos)
                .build();
    }
}
