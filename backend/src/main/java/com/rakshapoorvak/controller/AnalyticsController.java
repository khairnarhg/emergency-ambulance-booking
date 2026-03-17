package com.rakshapoorvak.controller;

import com.rakshapoorvak.model.dto.analytics.*;
import com.rakshapoorvak.security.SecurityUtils;
import com.rakshapoorvak.service.AnalyticsService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * Analytics - response times, emergency volume, dashboard.
 */
@RestController
@RequestMapping("/api/analytics")
public class AnalyticsController {

    private static final Logger log = LoggerFactory.getLogger(AnalyticsController.class);

    private final AnalyticsService analyticsService;

    public AnalyticsController(AnalyticsService analyticsService) {
        this.analyticsService = analyticsService;
    }

    @GetMapping("/response-times")
    @PreAuthorize("hasAnyRole('HOSPITAL_STAFF', 'ADMIN', 'DOCTOR')")
    public ResponseEntity<ResponseTimeDto> getResponseTimes(
            @RequestParam(required = false) Long hospitalId,
            @RequestParam(defaultValue = "30") int days) {
        return ResponseEntity.ok(analyticsService.getResponseTimes(hospitalId, days));
    }

    @GetMapping("/emergency-volume")
    @PreAuthorize("hasAnyRole('HOSPITAL_STAFF', 'ADMIN', 'DOCTOR')")
    public ResponseEntity<EmergencyVolumeDto> getEmergencyVolume(
            @RequestParam(required = false) Long hospitalId,
            @RequestParam(defaultValue = "30") int days) {
        return ResponseEntity.ok(analyticsService.getEmergencyVolume(hospitalId, days));
    }

    @GetMapping("/dashboard")
    @PreAuthorize("hasAnyRole('HOSPITAL_STAFF', 'ADMIN', 'DOCTOR')")
    public ResponseEntity<AnalyticsDashboardDto> getDashboard(
            @RequestParam(required = false) Long hospitalId,
            @RequestParam(defaultValue = "30") int days) {
        String email = SecurityUtils.getCurrentUserEmailOrThrow();
        return ResponseEntity.ok(analyticsService.getAnalyticsDashboard(email, hospitalId, days));
    }

    @GetMapping("/hotspots")
    @PreAuthorize("hasAnyRole('HOSPITAL_STAFF', 'ADMIN', 'DOCTOR')")
    public ResponseEntity<List<Map<String, Object>>> getHotspots(
            @RequestParam(defaultValue = "30") int days) {
        return ResponseEntity.ok(analyticsService.getHotspots(days));
    }
}
