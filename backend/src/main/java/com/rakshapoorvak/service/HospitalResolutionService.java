package com.rakshapoorvak.service;

import com.rakshapoorvak.exception.ResourceNotFoundException;
import com.rakshapoorvak.repository.DoctorRepository;
import com.rakshapoorvak.repository.HospitalStaffRepository;
import com.rakshapoorvak.repository.UserRepository;
import org.springframework.stereotype.Service;

/**
 * Resolves the effective hospital ID for the current user when not explicitly provided.
 * Used so dashboard, ambulances, doctors, and drivers lists show consistent hospital-scoped data.
 */
@Service
public class HospitalResolutionService {

    private final UserRepository userRepository;
    private final HospitalStaffRepository hospitalStaffRepository;
    private final DoctorRepository doctorRepository;

    public HospitalResolutionService(UserRepository userRepository,
                                     HospitalStaffRepository hospitalStaffRepository,
                                     DoctorRepository doctorRepository) {
        this.userRepository = userRepository;
        this.hospitalStaffRepository = hospitalStaffRepository;
        this.doctorRepository = doctorRepository;
    }

    /**
     * Returns hospitalId if non-null; otherwise resolves from the current user (staff or doctor).
     * Returns null for admin when hospitalId is null (global view).
     */
    public Long resolveHospitalId(String email, Long hospitalId) {
        if (hospitalId != null) return hospitalId;
        var user = userRepository.findByEmailWithRoles(email)
                .orElseThrow(() -> new ResourceNotFoundException("User", "email", email));
        var staff = hospitalStaffRepository.findByUserId(user.getId());
        if (staff.isPresent()) return staff.get().getHospital().getId();
        if (user.getRoles().stream().anyMatch(r -> "ADMIN".equals(r.getName().name()))) return null;
        var doctor = doctorRepository.findByUserId(user.getId());
        if (doctor.isPresent()) return doctor.get().getHospital().getId();
        return null;
    }
}
