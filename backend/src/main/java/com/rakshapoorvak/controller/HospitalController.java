package com.rakshapoorvak.controller;

import com.rakshapoorvak.model.dto.hospital.HospitalDto;
import com.rakshapoorvak.security.SecurityUtils;
import com.rakshapoorvak.service.HospitalService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Hospital listing and lookup.
 */
@RestController
@RequestMapping("/api/hospitals")
public class HospitalController {

    private static final Logger log = LoggerFactory.getLogger(HospitalController.class);

    private final HospitalService hospitalService;

    public HospitalController(HospitalService hospitalService) {
        this.hospitalService = hospitalService;
    }

    @GetMapping
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<List<HospitalDto>> list() {
        log.debug("GET /api/hospitals");
        return ResponseEntity.ok(hospitalService.listHospitals());
    }

    @GetMapping("/{id}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<HospitalDto> getById(@PathVariable Long id) {
        return ResponseEntity.ok(hospitalService.getById(id));
    }

    @GetMapping("/my-hospital")
    @PreAuthorize("hasAnyRole('HOSPITAL_STAFF', 'ADMIN', 'DOCTOR')")
    public ResponseEntity<HospitalDto> getMyHospital() {
        String email = SecurityUtils.getCurrentUserEmailOrThrow();
        log.debug("GET /api/hospitals/my-hospital");
        return ResponseEntity.ok(hospitalService.getByStaffHospital(email));
    }
}
