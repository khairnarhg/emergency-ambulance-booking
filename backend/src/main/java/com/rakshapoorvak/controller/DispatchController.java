package com.rakshapoorvak.controller;

import com.rakshapoorvak.model.dto.sos.SosEventDto;
import com.rakshapoorvak.service.DispatchService;
import com.rakshapoorvak.security.SecurityUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/dispatch")
public class DispatchController {

    private static final Logger log = LoggerFactory.getLogger(DispatchController.class);

    private final DispatchService dispatchService;

    public DispatchController(DispatchService dispatchService) {
        this.dispatchService = dispatchService;
    }

    @PostMapping("/{sosId}/find-ambulance")
    @PreAuthorize("hasAnyRole('HOSPITAL_STAFF', 'ADMIN')")
    public ResponseEntity<SosEventDto> findAmbulance(@PathVariable Long sosId) {
        log.info("POST /api/dispatch/{}/find-ambulance", sosId);
        SosEventDto dto = dispatchService.findAmbulance(sosId);
        return ResponseEntity.ok(dto);
    }

    @GetMapping("/pending-requests")
    @PreAuthorize("hasRole('DRIVER')")
    public ResponseEntity<List<SosEventDto>> getPendingRequests() {
        String email = SecurityUtils.getCurrentUserEmailOrThrow();
        List<SosEventDto> list = dispatchService.getPendingRequests(email);
        return ResponseEntity.ok(list);
    }

    @GetMapping("/{sosId}/request-details")
    @PreAuthorize("hasRole('DRIVER')")
    public ResponseEntity<SosEventDto> getRequestDetails(@PathVariable Long sosId) {
        SosEventDto dto = dispatchService.getRequestDetails(sosId);
        return ResponseEntity.ok(dto);
    }

    @PostMapping("/{sosId}/accept")
    @PreAuthorize("hasRole('DRIVER')")
    public ResponseEntity<SosEventDto> accept(@PathVariable Long sosId) {
        String email = SecurityUtils.getCurrentUserEmailOrThrow();
        SosEventDto dto = dispatchService.accept(sosId, email);
        return ResponseEntity.ok(dto);
    }

    @PostMapping("/{sosId}/reject")
    @PreAuthorize("hasRole('DRIVER')")
    public ResponseEntity<SosEventDto> reject(@PathVariable Long sosId) {
        String email = SecurityUtils.getCurrentUserEmailOrThrow();
        SosEventDto dto = dispatchService.reject(sosId, email);
        return ResponseEntity.ok(dto);
    }
}
