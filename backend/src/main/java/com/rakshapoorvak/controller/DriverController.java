package com.rakshapoorvak.controller;

import com.rakshapoorvak.model.dto.driver.DriverDto;
import com.rakshapoorvak.model.dto.driver.UpdateDriverRequest;
import com.rakshapoorvak.security.SecurityUtils;
import com.rakshapoorvak.service.DriverService;
import com.rakshapoorvak.service.HospitalResolutionService;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Driver profile and listing.
 */
@RestController
@RequestMapping("/api/drivers")
public class DriverController {

    private static final Logger log = LoggerFactory.getLogger(DriverController.class);

    private final DriverService driverService;
    private final HospitalResolutionService hospitalResolutionService;

    public DriverController(DriverService driverService,
                            HospitalResolutionService hospitalResolutionService) {
        this.driverService = driverService;
        this.hospitalResolutionService = hospitalResolutionService;
    }

    @GetMapping("/me")
    @PreAuthorize("hasRole('DRIVER')")
    public ResponseEntity<DriverDto> getMe() {
        String email = SecurityUtils.getCurrentUserEmailOrThrow();
        return ResponseEntity.ok(driverService.getMe(email));
    }

    @PatchMapping("/me")
    @PreAuthorize("hasRole('DRIVER')")
    public ResponseEntity<DriverDto> updateMe(@Valid @RequestBody UpdateDriverRequest request) {
        String email = SecurityUtils.getCurrentUserEmailOrThrow();
        log.info("PATCH /api/drivers/me");
        return ResponseEntity.ok(driverService.updateMe(email, request));
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('HOSPITAL_STAFF', 'ADMIN')")
    public ResponseEntity<List<DriverDto>> list(@RequestParam(required = false) Long hospitalId) {
        String email = SecurityUtils.getCurrentUserEmailOrThrow();
        Long resolvedHospitalId = hospitalResolutionService.resolveHospitalId(email, hospitalId);
        return ResponseEntity.ok(driverService.list(resolvedHospitalId));
    }
}
