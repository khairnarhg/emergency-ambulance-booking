package com.rakshapoorvak.controller;

import com.rakshapoorvak.model.dto.ambulance.AmbulanceLocationDto;
import com.rakshapoorvak.model.dto.map.MapOverviewDto;
import com.rakshapoorvak.service.MapService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Map data - ambulance locations, map overview.
 */
@RestController
@RequestMapping("/api/map")
public class MapController {

    private static final Logger log = LoggerFactory.getLogger(MapController.class);

    private final MapService mapService;

    public MapController(MapService mapService) {
        this.mapService = mapService;
    }

    @GetMapping("/ambulances")
    @PreAuthorize("hasAnyRole('HOSPITAL_STAFF', 'ADMIN', 'DOCTOR')")
    public ResponseEntity<List<AmbulanceLocationDto>> getAmbulanceLocations(
            @RequestParam(required = false) Long hospitalId) {
        return ResponseEntity.ok(mapService.getAmbulanceLocations(hospitalId));
    }

    @GetMapping("/overview")
    @PreAuthorize("hasAnyRole('HOSPITAL_STAFF', 'ADMIN', 'DOCTOR')")
    public ResponseEntity<MapOverviewDto> getMapOverview(@RequestParam(required = false) Long hospitalId) {
        return ResponseEntity.ok(mapService.getMapOverview(hospitalId));
    }
}
