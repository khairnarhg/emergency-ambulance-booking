package com.rakshapoorvak.controller;

import com.rakshapoorvak.model.dto.location.LocationUpdateRequest;
import com.rakshapoorvak.security.SecurityUtils;
import com.rakshapoorvak.service.LocationService;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

/**
 * Location update posting.
 */
@RestController
@RequestMapping("/api/locations")
public class LocationController {

    private static final Logger log = LoggerFactory.getLogger(LocationController.class);

    private final LocationService locationService;

    public LocationController(LocationService locationService) {
        this.locationService = locationService;
    }

    @PostMapping
    @PreAuthorize("hasRole('DRIVER')")
    public ResponseEntity<Void> postLocationUpdate(@Valid @RequestBody LocationUpdateRequest request) {
        String email = SecurityUtils.getCurrentUserEmailOrThrow();
        log.debug("POST /api/locations");
        locationService.postLocationUpdate(request, email);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }
}
