package com.rakshapoorvak.service;

import com.rakshapoorvak.exception.ResourceNotFoundException;
import com.rakshapoorvak.model.dto.driver.DriverDto;
import com.rakshapoorvak.model.dto.driver.UpdateDriverRequest;
import com.rakshapoorvak.model.entity.Driver;
import com.rakshapoorvak.model.entity.enums.DriverStatus;
import com.rakshapoorvak.repository.DriverRepository;
import com.rakshapoorvak.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Driver profile and listing.
 */
@Service
public class DriverService {

    private static final Logger log = LoggerFactory.getLogger(DriverService.class);

    private final DriverRepository driverRepository;
    private final UserRepository userRepository;

    public DriverService(DriverRepository driverRepository, UserRepository userRepository) {
        this.driverRepository = driverRepository;
        this.userRepository = userRepository;
    }

    @Transactional(readOnly = true)
    public DriverDto getMe(String email) {
        var user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("User", "email", email));
        Driver d = driverRepository.findByUserId(user.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Driver for user", user.getId()));
        return toDto(d);
    }

    @Transactional
    public DriverDto updateMe(String email, UpdateDriverRequest request) {
        var user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("User", "email", email));
        Driver d = driverRepository.findByUserId(user.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Driver for user", user.getId()));
        d.setStatus(DriverStatus.valueOf(request.getStatus()));
        d = driverRepository.save(d);
        log.info("Driver {} status updated to {}", d.getId(), request.getStatus());
        return toDto(d);
    }

    @Transactional(readOnly = true)
    public List<DriverDto> list(Long hospitalId) {
        List<Driver> list = hospitalId != null
                ? driverRepository.findByHospitalId(hospitalId)
                : driverRepository.findAll();
        return list.stream().map(this::toDto).collect(Collectors.toList());
    }

    private DriverDto toDto(Driver d) {
        return DriverDto.builder()
                .id(d.getId())
                .userId(d.getUser().getId())
                .fullName(d.getUser().getFullName())
                .email(d.getUser().getEmail())
                .phone(d.getUser().getPhone())
                .licenseNumber(d.getLicenseNumber())
                .hospitalId(d.getHospital().getId())
                .hospitalName(d.getHospital().getName())
                .status(d.getStatus().name())
                .build();
    }
}
