package com.rakshapoorvak.controller;

import com.rakshapoorvak.model.dto.sos.CreateSosRequest;
import com.rakshapoorvak.model.dto.sos.SosEventDto;
import com.rakshapoorvak.model.dto.sos.TrackingDto;
import com.rakshapoorvak.model.dto.sos.UpdateSosRequest;
import com.rakshapoorvak.model.dto.sos.UpdateStatusRequest;
import com.rakshapoorvak.service.DispatchService;
import com.rakshapoorvak.service.SosService;
import com.rakshapoorvak.security.SecurityUtils;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * SOS event endpoints - create, get, list, update, tracking.
 */
@RestController
@RequestMapping("/api/sos-events")
public class SosController {

    private static final Logger log = LoggerFactory.getLogger(SosController.class);

    private final SosService sosService;
    private final DispatchService dispatchService;

    public SosController(SosService sosService, DispatchService dispatchService) {
        this.sosService = sosService;
        this.dispatchService = dispatchService;
    }

    @PostMapping
    @PreAuthorize("hasRole('USER')")
    public ResponseEntity<SosEventDto> create(@Valid @RequestBody CreateSosRequest request) {
        String email = SecurityUtils.getCurrentUserEmailOrThrow();
        log.info("POST /api/sos-events by user {}", email);
        SosEventDto created = sosService.create(email, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    @PatchMapping("/{id}")
    @PreAuthorize("hasRole('USER')")
    public ResponseEntity<SosEventDto> update(@PathVariable Long id,
                                              @Valid @RequestBody UpdateSosRequest request) {
        String email = SecurityUtils.getCurrentUserEmailOrThrow();
        SosEventDto updated = sosService.update(email, id, request);
        return ResponseEntity.ok(updated);
    }

    @GetMapping("/{id}")
    public ResponseEntity<SosEventDto> getById(@PathVariable Long id) {
        SosEventDto dto = sosService.getById(id);
        return ResponseEntity.ok(dto);
    }

    @GetMapping("/my")
    @PreAuthorize("hasRole('USER')")
    public ResponseEntity<List<SosEventDto>> getMy() {
        String email = SecurityUtils.getCurrentUserEmailOrThrow();
        List<SosEventDto> list = sosService.getMy(email);
        return ResponseEntity.ok(list);
    }

    @GetMapping("/my/active")
    @PreAuthorize("hasRole('USER')")
    public ResponseEntity<List<SosEventDto>> getMyActive() {
        String email = SecurityUtils.getCurrentUserEmailOrThrow();
        List<SosEventDto> list = sosService.getMyActive(email);
        return ResponseEntity.ok(list);
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('HOSPITAL_STAFF', 'ADMIN', 'DOCTOR')")
    public ResponseEntity<Page<SosEventDto>> list(
            @RequestParam(required = false) Long hospitalId,
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(sosService.listForHospital(hospitalId, status, page, size));
    }

    @GetMapping("/active")
    @PreAuthorize("hasAnyRole('HOSPITAL_STAFF', 'ADMIN', 'DOCTOR')")
    public ResponseEntity<List<SosEventDto>> getActive(@RequestParam Long hospitalId) {
        List<SosEventDto> list = sosService.getActiveForHospital(hospitalId);
        return ResponseEntity.ok(list);
    }

    @PatchMapping("/{id}/status")
    @PreAuthorize("hasRole('DRIVER')")
    public ResponseEntity<SosEventDto> updateStatus(@PathVariable Long id,
                                                    @Valid @RequestBody UpdateStatusRequest request) {
        String email = SecurityUtils.getCurrentUserEmailOrThrow();
        SosEventDto updated = sosService.updateStatus(id, request, email);
        return ResponseEntity.ok(updated);
    }

    @PostMapping("/{id}/complete")
    @PreAuthorize("hasRole('DRIVER')")
    public ResponseEntity<SosEventDto> complete(@PathVariable Long id) {
        String email = SecurityUtils.getCurrentUserEmailOrThrow();
        SosEventDto updated = sosService.complete(id, email);
        return ResponseEntity.ok(updated);
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('USER')")
    public ResponseEntity<Void> cancel(@PathVariable Long id) {
        String email = SecurityUtils.getCurrentUserEmailOrThrow();
        sosService.cancel(id, email);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/{id}/tracking")
    public ResponseEntity<TrackingDto> getTracking(@PathVariable Long id) {
        TrackingDto dto = sosService.getTracking(id);
        return ResponseEntity.ok(dto);
    }

    @GetMapping("/driver/history")
    @PreAuthorize("hasRole('DRIVER')")
    public ResponseEntity<List<SosEventDto>> getDriverHistory() {
        String email = SecurityUtils.getCurrentUserEmailOrThrow();
        return ResponseEntity.ok(sosService.getDriverHistory(email));
    }

    @GetMapping("/driver/active")
    @PreAuthorize("hasRole('DRIVER')")
    public ResponseEntity<List<SosEventDto>> getDriverActive() {
        String email = SecurityUtils.getCurrentUserEmailOrThrow();
        return ResponseEntity.ok(sosService.getDriverActive(email));
    }

    @PostMapping("/{sosId}/assign-doctor")
    @PreAuthorize("hasAnyRole('HOSPITAL_STAFF', 'ADMIN')")
    public ResponseEntity<SosEventDto> assignDoctor(@PathVariable Long sosId) {
        SosEventDto updated = dispatchService.assignDoctor(sosId);
        return ResponseEntity.ok(updated);
    }

    @DeleteMapping("/{sosId}/doctor")
    @PreAuthorize("hasAnyRole('HOSPITAL_STAFF', 'ADMIN')")
    public ResponseEntity<SosEventDto> unassignDoctor(@PathVariable Long sosId) {
        SosEventDto updated = dispatchService.unassignDoctor(sosId);
        return ResponseEntity.ok(updated);
    }
}
