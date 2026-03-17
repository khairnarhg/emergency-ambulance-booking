package com.rakshapoorvak.controller;

import com.rakshapoorvak.model.dto.doctor.DoctorDto;
import com.rakshapoorvak.security.SecurityUtils;
import com.rakshapoorvak.service.DoctorService;
import com.rakshapoorvak.service.HospitalResolutionService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Doctor endpoints.
 */
@RestController
@RequestMapping("/api/doctors")
public class DoctorController {

    private static final Logger log = LoggerFactory.getLogger(DoctorController.class);

    private final DoctorService doctorService;
    private final HospitalResolutionService hospitalResolutionService;

    public DoctorController(DoctorService doctorService,
                            HospitalResolutionService hospitalResolutionService) {
        this.doctorService = doctorService;
        this.hospitalResolutionService = hospitalResolutionService;
    }

    @GetMapping("/me")
    @PreAuthorize("hasRole('DOCTOR')")
    public ResponseEntity<DoctorDto> getMe() {
        String email = SecurityUtils.getCurrentUserEmailOrThrow();
        return ResponseEntity.ok(doctorService.getMe(email));
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('HOSPITAL_STAFF', 'ADMIN', 'DOCTOR')")
    public ResponseEntity<List<DoctorDto>> list(@RequestParam(required = false) Long hospitalId) {
        String email = SecurityUtils.getCurrentUserEmailOrThrow();
        Long resolvedHospitalId = hospitalResolutionService.resolveHospitalId(email, hospitalId);
        return ResponseEntity.ok(doctorService.list(resolvedHospitalId));
    }

    @GetMapping("/{id}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<DoctorDto> getById(@PathVariable Long id) {
        return ResponseEntity.ok(doctorService.getById(id));
    }
}
