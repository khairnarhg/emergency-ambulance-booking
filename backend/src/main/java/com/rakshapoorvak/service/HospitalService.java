package com.rakshapoorvak.service;

import com.rakshapoorvak.exception.ResourceNotFoundException;
import com.rakshapoorvak.model.dto.hospital.HospitalDto;
import com.rakshapoorvak.model.entity.Hospital;
import com.rakshapoorvak.model.entity.HospitalStaff;
import com.rakshapoorvak.repository.DoctorRepository;
import com.rakshapoorvak.repository.HospitalRepository;
import com.rakshapoorvak.repository.HospitalStaffRepository;
import com.rakshapoorvak.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Hospital listing and lookup.
 */
@Service
public class HospitalService {

    private static final Logger log = LoggerFactory.getLogger(HospitalService.class);

    private final HospitalRepository hospitalRepository;
    private final HospitalStaffRepository hospitalStaffRepository;
    private final DoctorRepository doctorRepository;
    private final UserRepository userRepository;

    public HospitalService(HospitalRepository hospitalRepository, HospitalStaffRepository hospitalStaffRepository,
                           DoctorRepository doctorRepository, UserRepository userRepository) {
        this.hospitalRepository = hospitalRepository;
        this.hospitalStaffRepository = hospitalStaffRepository;
        this.doctorRepository = doctorRepository;
        this.userRepository = userRepository;
    }

    @Transactional(readOnly = true)
    public List<HospitalDto> listHospitals() {
        return hospitalRepository.findAll().stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public HospitalDto getById(Long id) {
        Hospital hospital = hospitalRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Hospital", id));
        return toDto(hospital);
    }

    @Transactional(readOnly = true)
    public HospitalDto getByStaffHospital(String email) {
        var user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("User", "email", email));
        var staff = hospitalStaffRepository.findByUserId(user.getId());
        if (staff.isPresent()) return toDto(staff.get().getHospital());
        var doctor = doctorRepository.findByUserId(user.getId());
        if (doctor.isPresent()) return toDto(doctor.get().getHospital());
        throw new ResourceNotFoundException("Hospital staff or doctor for user", user.getId());
    }

    private HospitalDto toDto(Hospital h) {
        return HospitalDto.builder()
                .id(h.getId())
                .name(h.getName())
                .address(h.getAddress())
                .latitude(h.getLatitude())
                .longitude(h.getLongitude())
                .build();
    }
}
