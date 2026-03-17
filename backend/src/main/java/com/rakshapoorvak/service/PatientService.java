package com.rakshapoorvak.service;

import com.rakshapoorvak.exception.ForbiddenException;
import com.rakshapoorvak.exception.ResourceNotFoundException;
import com.rakshapoorvak.model.dto.patient.PatientHistoryDto;
import com.rakshapoorvak.model.dto.patient.PatientSearchResultDto;
import com.rakshapoorvak.model.dto.sos.SosEventDto;
import com.rakshapoorvak.model.entity.SosEvent;
import com.rakshapoorvak.model.entity.User;
import com.rakshapoorvak.repository.HospitalStaffRepository;
import com.rakshapoorvak.repository.SosEventRepository;
import com.rakshapoorvak.repository.UserRepository;
import com.rakshapoorvak.service.SosService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Comparator;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Patient search and history for hospital staff.
 */
@Service
public class PatientService {

    private static final Logger log = LoggerFactory.getLogger(PatientService.class);

    private final UserRepository userRepository;
    private final SosEventRepository sosEventRepository;
    private final HospitalStaffRepository hospitalStaffRepository;
    private final SosService sosService;

    public PatientService(UserRepository userRepository, SosEventRepository sosEventRepository,
                          HospitalStaffRepository hospitalStaffRepository, SosService sosService) {
        this.userRepository = userRepository;
        this.sosEventRepository = sosEventRepository;
        this.hospitalStaffRepository = hospitalStaffRepository;
        this.sosService = sosService;
    }

    @Transactional(readOnly = true)
    public List<PatientSearchResultDto> list(String email) {
        ensureHospitalStaffOrDoctor(email);
        List<Long> userIds = sosEventRepository.findDistinctUserIds();
        if (userIds.isEmpty()) return List.of();
        List<User> users = userRepository.findAllById(userIds);
        return users.stream()
                .map(this::toPatientSearchResult)
                .sorted(Comparator.comparing(PatientSearchResultDto::getLastSosDate,
                        Comparator.nullsLast(Comparator.reverseOrder())))
                .limit(200)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<PatientSearchResultDto> search(String email, String query) {
        ensureHospitalStaffOrDoctor(email);
        if (query == null || query.isBlank() || query.length() < 2) {
            return List.of();
        }
        return userRepository.search(query).stream()
                .limit(50)
                .map(this::toPatientSearchResult)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public PatientHistoryDto getHistoryByUserId(String email, Long userId) {
        ensureHospitalStaffOrDoctor(email);
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User", userId));
        List<SosEventDto> events = sosEventRepository.findByUserIdOrderByCreatedAtDesc(user.getId()).stream()
                .map(sosService::toDto)
                .collect(Collectors.toList());
        return PatientHistoryDto.builder()
                .userId(user.getId())
                .fullName(user.getFullName())
                .sosEvents(events)
                .build();
    }

    private void ensureHospitalStaffOrDoctor(String email) {
        var user = userRepository.findByEmailWithRoles(email)
                .orElseThrow(() -> new ResourceNotFoundException("User", "email", email));
        if (hospitalStaffRepository.findByUserId(user.getId()).isPresent()) return;
        boolean isAdmin = user.getRoles().stream().anyMatch(r -> "ADMIN".equals(r.getName().name()));
        if (isAdmin) return;
        boolean isDoctor = user.getRoles().stream().anyMatch(r -> "DOCTOR".equals(r.getName().name()));
        if (isDoctor) return;
        throw new ForbiddenException("Hospital staff, doctor, or admin access required");
    }

    private PatientSearchResultDto toPatientSearchResult(User u) {
        java.util.Optional<SosEvent> lastSos = sosEventRepository.findByUserIdOrderByCreatedAtDesc(u.getId())
                .stream().findFirst();
        return PatientSearchResultDto.builder()
                .userId(u.getId())
                .fullName(u.getFullName())
                .email(u.getEmail())
                .phone(u.getPhone())
                .lastSosDate(lastSos.map(SosEvent::getCreatedAt).orElse(null))
                .build();
    }
}
