package com.rakshapoorvak.controller;

import com.rakshapoorvak.model.dto.dashboard.DashboardSummaryDto;
import com.rakshapoorvak.model.dto.dashboard.SosSummaryItemDto;
import com.rakshapoorvak.security.SecurityUtils;
import com.rakshapoorvak.service.DashboardService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Dashboard summary and active SOS.
 */
@RestController
@RequestMapping("/api/dashboard")
public class DashboardController {

    private static final Logger log = LoggerFactory.getLogger(DashboardController.class);

    private final DashboardService dashboardService;

    public DashboardController(DashboardService dashboardService) {
        this.dashboardService = dashboardService;
    }

    @GetMapping("/summary")
    @PreAuthorize("hasAnyRole('HOSPITAL_STAFF', 'ADMIN', 'DOCTOR')")
    public ResponseEntity<DashboardSummaryDto> getSummary(@RequestParam(required = false) Long hospitalId) {
        String email = SecurityUtils.getCurrentUserEmailOrThrow();
        log.debug("GET /api/dashboard/summary");
        return ResponseEntity.ok(dashboardService.getSummary(email, hospitalId));
    }

    @GetMapping("/active-sos")
    @PreAuthorize("hasAnyRole('HOSPITAL_STAFF', 'ADMIN', 'DOCTOR')")
    public ResponseEntity<List<SosSummaryItemDto>> getActiveSos(@RequestParam(required = false) Long hospitalId) {
        String email = SecurityUtils.getCurrentUserEmailOrThrow();
        return ResponseEntity.ok(dashboardService.getActiveSos(email, hospitalId));
    }
}
