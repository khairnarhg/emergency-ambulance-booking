package com.rakshapoorvak.service;

import com.rakshapoorvak.exception.ForbiddenException;
import com.rakshapoorvak.exception.ResourceNotFoundException;
import com.rakshapoorvak.model.dto.location.LocationUpdateRequest;
import com.rakshapoorvak.model.entity.Ambulance;
import com.rakshapoorvak.model.entity.LocationUpdate;
import com.rakshapoorvak.repository.AmbulanceRepository;
import com.rakshapoorvak.repository.DriverRepository;
import com.rakshapoorvak.repository.LocationUpdateRepository;
import com.rakshapoorvak.repository.SosEventRepository;
import com.rakshapoorvak.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;

/**
 * Location update posting for ambulances/drivers.
 */
@Service
public class LocationService {

    private static final Logger log = LoggerFactory.getLogger(LocationService.class);

    private final LocationUpdateRepository locationUpdateRepository;
    private final AmbulanceRepository ambulanceRepository;
    private final DriverRepository driverRepository;
    private final SosEventRepository sosEventRepository;
    private final UserRepository userRepository;

    public LocationService(LocationUpdateRepository locationUpdateRepository, AmbulanceRepository ambulanceRepository,
                           DriverRepository driverRepository, SosEventRepository sosEventRepository,
                           UserRepository userRepository) {
        this.locationUpdateRepository = locationUpdateRepository;
        this.ambulanceRepository = ambulanceRepository;
        this.driverRepository = driverRepository;
        this.sosEventRepository = sosEventRepository;
        this.userRepository = userRepository;
    }

    @Transactional
    public void postLocationUpdate(LocationUpdateRequest request, String driverEmail) {
        var user = userRepository.findByEmail(driverEmail)
                .orElseThrow(() -> new ResourceNotFoundException("User", "email", driverEmail));
        var driver = driverRepository.findByUserId(user.getId())
                .orElseThrow(() -> new ForbiddenException("Driver not found"));

        Ambulance ambulance = null;
        if (request.getAmbulanceId() != null) {
            ambulance = ambulanceRepository.findById(request.getAmbulanceId())
                    .orElseThrow(() -> new ResourceNotFoundException("Ambulance", request.getAmbulanceId()));
            if (!ambulance.getHospital().getId().equals(driver.getHospital().getId())) {
                throw new ForbiddenException("Ambulance does not belong to your hospital");
            }
            ambulance.setCurrentLatitude(request.getLatitude());
            ambulance.setCurrentLongitude(request.getLongitude());
            ambulanceRepository.save(ambulance);
        }

        LocationUpdate lu = LocationUpdate.builder()
                .sosEvent(request.getSosEventId() != null
                        ? sosEventRepository.findById(request.getSosEventId()).orElse(null)
                        : null)
                .ambulance(ambulance)
                .latitude(request.getLatitude())
                .longitude(request.getLongitude())
                .recordedAt(Instant.now())
                .build();
        locationUpdateRepository.save(lu);
        log.debug("Location update posted for ambulance {} sos {} by driver {}",
                request.getAmbulanceId(), request.getSosEventId(), driver.getId());
    }
}
