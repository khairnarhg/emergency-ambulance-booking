package com.rakshapoorvak.service;

import com.rakshapoorvak.exception.ForbiddenException;
import com.rakshapoorvak.exception.ResourceNotFoundException;
import com.rakshapoorvak.model.dto.ambulance.*;
import com.rakshapoorvak.model.entity.Ambulance;
import com.rakshapoorvak.model.entity.Driver;
import com.rakshapoorvak.model.entity.enums.AmbulanceStatus;
import com.rakshapoorvak.repository.AmbulanceRepository;
import com.rakshapoorvak.repository.DriverRepository;
import com.rakshapoorvak.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Ambulance listing, location, status.
 */
@Service
public class AmbulanceService {

    private static final Logger log = LoggerFactory.getLogger(AmbulanceService.class);

    private final AmbulanceRepository ambulanceRepository;
    private final DriverRepository driverRepository;
    private final UserRepository userRepository;

    public AmbulanceService(AmbulanceRepository ambulanceRepository, DriverRepository driverRepository,
                            UserRepository userRepository) {
        this.ambulanceRepository = ambulanceRepository;
        this.driverRepository = driverRepository;
        this.userRepository = userRepository;
    }

    @Transactional(readOnly = true)
    public List<AmbulanceDto> list(Long hospitalId) {
        List<Ambulance> list = hospitalId != null
                ? ambulanceRepository.findByHospitalId(hospitalId)
                : ambulanceRepository.findAll();
        return list.stream().map(this::toDto).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public AmbulanceDto getById(Long id) {
        Ambulance a = ambulanceRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Ambulance", id));
        return toDto(a);
    }

    @Transactional(readOnly = true)
    public AmbulanceLocationDto getLocation(Long id) {
        Ambulance a = ambulanceRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Ambulance", id));
        if (a.getCurrentLatitude() == null || a.getCurrentLongitude() == null) {
            throw new ResourceNotFoundException("Ambulance location not available for id: " + id);
        }
        return AmbulanceLocationDto.builder()
                .ambulanceId(a.getId())
                .registrationNumber(a.getRegistrationNumber())
                .latitude(a.getCurrentLatitude())
                .longitude(a.getCurrentLongitude())
                .build();
    }

    @Transactional
    public AmbulanceDto updateLocation(Long ambulanceId, UpdateAmbulanceLocationRequest request, String driverEmail) {
        Ambulance a = ambulanceRepository.findById(ambulanceId)
                .orElseThrow(() -> new ResourceNotFoundException("Ambulance", ambulanceId));

        Driver driver = driverRepository.findByUserId(
                userRepository.findByEmail(driverEmail).orElseThrow().getId())
                .orElseThrow(() -> new ForbiddenException("Driver not found"));

        if (!a.getHospital().getId().equals(driver.getHospital().getId())) {
            throw new ForbiddenException("Ambulance does not belong to your hospital");
        }

        a.setCurrentLatitude(request.getLatitude());
        a.setCurrentLongitude(request.getLongitude());
        a = ambulanceRepository.save(a);
        log.info("Ambulance {} location updated by driver {}", ambulanceId, driver.getId());
        return toDto(a);
    }

    @Transactional
    public AmbulanceDto updateStatus(Long ambulanceId, UpdateAmbulanceStatusRequest request, String driverEmail) {
        Ambulance a = ambulanceRepository.findById(ambulanceId)
                .orElseThrow(() -> new ResourceNotFoundException("Ambulance", ambulanceId));

        Driver driver = driverRepository.findByUserId(
                userRepository.findByEmail(driverEmail).orElseThrow().getId())
                .orElseThrow(() -> new ForbiddenException("Driver not found"));

        if (!a.getHospital().getId().equals(driver.getHospital().getId())) {
            throw new ForbiddenException("Ambulance does not belong to your hospital");
        }

        a.setStatus(AmbulanceStatus.valueOf(request.getStatus()));
        a = ambulanceRepository.save(a);
        log.info("Ambulance {} status updated to {} by driver {}", ambulanceId, request.getStatus(), driver.getId());
        return toDto(a);
    }

    private AmbulanceDto toDto(Ambulance a) {
        return AmbulanceDto.builder()
                .id(a.getId())
                .hospitalId(a.getHospital() != null ? a.getHospital().getId() : null)
                .hospitalName(a.getHospital() != null ? a.getHospital().getName() : null)
                .registrationNumber(a.getRegistrationNumber())
                .status(a.getStatus().name())
                .currentLatitude(a.getCurrentLatitude())
                .currentLongitude(a.getCurrentLongitude())
                .updatedAt(a.getUpdatedAt())
                .build();
    }
}
