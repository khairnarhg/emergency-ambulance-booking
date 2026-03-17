package com.rakshapoorvak.service;

import com.rakshapoorvak.exception.ResourceNotFoundException;
import com.rakshapoorvak.model.dto.doctor.DoctorDto;
import com.rakshapoorvak.model.entity.Doctor;
import com.rakshapoorvak.repository.DoctorRepository;
import com.rakshapoorvak.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Doctor listing and profile.
 */
@Service
public class DoctorService {

    private static final Logger log = LoggerFactory.getLogger(DoctorService.class);

    private final DoctorRepository doctorRepository;
    private final UserRepository userRepository;

    public DoctorService(DoctorRepository doctorRepository, UserRepository userRepository) {
        this.doctorRepository = doctorRepository;
        this.userRepository = userRepository;
    }

    @Transactional(readOnly = true)
    public DoctorDto getMe(String email) {
        var user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("User", "email", email));
        Doctor d = doctorRepository.findByUserId(user.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Doctor for user", user.getId()));
        return toDto(d);
    }

    @Transactional(readOnly = true)
    public List<DoctorDto> list(Long hospitalId) {
        List<Doctor> list = hospitalId != null
                ? doctorRepository.findByHospitalId(hospitalId)
                : doctorRepository.findAll();
        return list.stream().map(this::toDto).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public DoctorDto getById(Long id) {
        Doctor d = doctorRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Doctor", id));
        return toDto(d);
    }

    private DoctorDto toDto(Doctor d) {
        return DoctorDto.builder()
                .id(d.getId())
                .userId(d.getUser().getId())
                .fullName(d.getUser().getFullName())
                .email(d.getUser().getEmail())
                .phone(d.getUser().getPhone())
                .specialization(d.getSpecialization())
                .hospitalId(d.getHospital().getId())
                .hospitalName(d.getHospital().getName())
                .status(d.getStatus().name())
                .build();
    }
}
