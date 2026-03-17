package com.rakshapoorvak.controller;

import com.rakshapoorvak.model.dto.triage.*;
import com.rakshapoorvak.service.TriageService;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Triage records and medications.
 */
@RestController
@RequestMapping("/api/triage")
public class TriageController {

    private static final Logger log = LoggerFactory.getLogger(TriageController.class);

    private final TriageService triageService;

    public TriageController(TriageService triageService) {
        this.triageService = triageService;
    }

    @PostMapping("/records")
    @PreAuthorize("hasRole('DRIVER')")
    public ResponseEntity<TriageRecordDto> addTriageRecord(@Valid @RequestBody CreateTriageRecordRequest request) {
        log.info("POST /api/triage/records for SOS {}", request.getSosEventId());
        TriageRecordDto dto = triageService.addTriageRecord(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(dto);
    }

    @GetMapping("/records")
    @PreAuthorize("hasAnyRole('DRIVER', 'HOSPITAL_STAFF', 'ADMIN', 'DOCTOR')")
    public ResponseEntity<List<TriageRecordDto>> listTriageRecords(@RequestParam Long sosEventId) {
        return ResponseEntity.ok(triageService.listTriageRecords(sosEventId));
    }

    @PostMapping("/medications")
    @PreAuthorize("hasRole('DRIVER')")
    public ResponseEntity<MedicationDto> addMedication(@Valid @RequestBody CreateMedicationRequest request) {
        log.info("POST /api/triage/medications for SOS {}", request.getSosEventId());
        MedicationDto dto = triageService.addMedication(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(dto);
    }

    @GetMapping("/medications")
    @PreAuthorize("hasAnyRole('DRIVER', 'HOSPITAL_STAFF', 'ADMIN', 'DOCTOR')")
    public ResponseEntity<List<MedicationDto>> listMedications(@RequestParam Long sosEventId) {
        return ResponseEntity.ok(triageService.listMedications(sosEventId));
    }
}
