package com.rakshapoorvak.controller;

import com.rakshapoorvak.model.dto.ambulance.*;
import com.rakshapoorvak.security.SecurityUtils;
import com.rakshapoorvak.service.AmbulanceService;
import com.rakshapoorvak.service.HospitalResolutionService;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Ambulance listing, location, status.
 */
@RestController
@RequestMapping("/api/ambulances")
public class AmbulanceController {

    private static final Logger log = LoggerFactory.getLogger(AmbulanceController.class);

    private final AmbulanceService ambulanceService;
    private final HospitalResolutionService hospitalResolutionService;

    public AmbulanceController(AmbulanceService ambulanceService,
                              HospitalResolutionService hospitalResolutionService) {
        this.ambulanceService = ambulanceService;
        this.hospitalResolutionService = hospitalResolutionService;
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('HOSPITAL_STAFF', 'ADMIN', 'DOCTOR')")
    public ResponseEntity<List<AmbulanceDto>> list(@RequestParam(required = false) Long hospitalId) {
        String email = SecurityUtils.getCurrentUserEmailOrThrow();
        Long resolvedHospitalId = hospitalResolutionService.resolveHospitalId(email, hospitalId);
        log.debug("GET /api/ambulances hospitalId={}", resolvedHospitalId);
        return ResponseEntity.ok(ambulanceService.list(resolvedHospitalId));
    }

    @GetMapping("/{id}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<AmbulanceDto> getById(@PathVariable Long id) {
        return ResponseEntity.ok(ambulanceService.getById(id));
    }

    @GetMapping("/{id}/location")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<AmbulanceLocationDto> getLocation(@PathVariable Long id) {
        return ResponseEntity.ok(ambulanceService.getLocation(id));
    }

    @PatchMapping("/{id}/location")
    @PreAuthorize("hasRole('DRIVER')")
    public ResponseEntity<AmbulanceDto> updateLocation(@PathVariable Long id,
                                                       @Valid @RequestBody UpdateAmbulanceLocationRequest request) {
        String email = SecurityUtils.getCurrentUserEmailOrThrow();
        return ResponseEntity.ok(ambulanceService.updateLocation(id, request, email));
    }

    @PatchMapping("/{id}/status")
    @PreAuthorize("hasRole('DRIVER')")
    public ResponseEntity<AmbulanceDto> updateStatus(@PathVariable Long id,
                                                     @Valid @RequestBody UpdateAmbulanceStatusRequest request) {
        String email = SecurityUtils.getCurrentUserEmailOrThrow();
        return ResponseEntity.ok(ambulanceService.updateStatus(id, request, email));
    }
}
