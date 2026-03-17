package com.rakshapoorvak.controller;

import com.rakshapoorvak.model.dto.patient.PatientHistoryDto;
import com.rakshapoorvak.model.dto.patient.PatientSearchResultDto;
import com.rakshapoorvak.security.SecurityUtils;
import com.rakshapoorvak.service.PatientService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Patient search and history.
 */
@RestController
@RequestMapping("/api/patients")
public class PatientController {

    private static final Logger log = LoggerFactory.getLogger(PatientController.class);

    private final PatientService patientService;

    public PatientController(PatientService patientService) {
        this.patientService = patientService;
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('HOSPITAL_STAFF', 'ADMIN', 'DOCTOR')")
    public ResponseEntity<List<PatientSearchResultDto>> list() {
        String email = SecurityUtils.getCurrentUserEmailOrThrow();
        return ResponseEntity.ok(patientService.list(email));
    }

    @GetMapping("/search")
    @PreAuthorize("hasAnyRole('HOSPITAL_STAFF', 'ADMIN', 'DOCTOR')")
    public ResponseEntity<List<PatientSearchResultDto>> search(@RequestParam String q) {
        String email = SecurityUtils.getCurrentUserEmailOrThrow();
        log.debug("GET /api/patients/search q={}", q);
        return ResponseEntity.ok(patientService.search(email, q));
    }

    @GetMapping("/{userId}/history")
    @PreAuthorize("hasAnyRole('HOSPITAL_STAFF', 'ADMIN', 'DOCTOR')")
    public ResponseEntity<PatientHistoryDto> getHistoryByUserId(@PathVariable Long userId) {
        String email = SecurityUtils.getCurrentUserEmailOrThrow();
        return ResponseEntity.ok(patientService.getHistoryByUserId(email, userId));
    }
}
