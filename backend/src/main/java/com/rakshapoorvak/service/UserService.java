package com.rakshapoorvak.service;

import com.rakshapoorvak.exception.ForbiddenException;
import com.rakshapoorvak.exception.ResourceNotFoundException;
import com.rakshapoorvak.model.dto.user.*;
import com.rakshapoorvak.model.entity.EmergencyContact;
import com.rakshapoorvak.model.entity.MedicalProfile;
import com.rakshapoorvak.model.entity.User;
import com.rakshapoorvak.repository.EmergencyContactRepository;
import com.rakshapoorvak.repository.MedicalProfileRepository;
import com.rakshapoorvak.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

/**
 * User profile, medical profile, and emergency contacts.
 */
@Service
public class UserService {

    private static final Logger log = LoggerFactory.getLogger(UserService.class);

    private final UserRepository userRepository;
    private final MedicalProfileRepository medicalProfileRepository;
    private final EmergencyContactRepository emergencyContactRepository;

    public UserService(UserRepository userRepository, MedicalProfileRepository medicalProfileRepository,
                       EmergencyContactRepository emergencyContactRepository) {
        this.userRepository = userRepository;
        this.medicalProfileRepository = medicalProfileRepository;
        this.emergencyContactRepository = emergencyContactRepository;
    }

    @Transactional(readOnly = true)
    public UserProfileDto getProfile(String email) {
        User user = userRepository.findByEmailWithRoles(email)
                .orElseThrow(() -> new ResourceNotFoundException("User", "email", email));
        return toProfileDto(user);
    }

    @Transactional
    public UserProfileDto updateProfile(String email, UpdateProfileRequest request) {
        User user = userRepository.findByEmailWithRoles(email)
                .orElseThrow(() -> new ResourceNotFoundException("User", "email", email));
        if (request.getFullName() != null) user.setFullName(request.getFullName());
        if (request.getPhone() != null) user.setPhone(request.getPhone());
        user = userRepository.save(user);
        log.info("Profile updated for user {}", user.getId());
        return toProfileDto(user);
    }

    @Transactional(readOnly = true)
    public MedicalProfileDto getMedicalProfile(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("User", "email", email));
        MedicalProfile mp = medicalProfileRepository.findByUserId(user.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Medical profile for user", user.getId()));
        return toMedicalProfileDto(mp);
    }

    @Transactional
    public MedicalProfileDto updateMedicalProfile(String email, UpdateMedicalProfileRequest request) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("User", "email", email));
        MedicalProfile mp = medicalProfileRepository.findByUserId(user.getId())
                .orElse(MedicalProfile.builder().user(user).build());
        if (request.getBloodGroup() != null) mp.setBloodGroup(request.getBloodGroup());
        if (request.getAllergies() != null) mp.setAllergies(request.getAllergies());
        if (request.getConditions() != null) mp.setConditions(request.getConditions());
        if (request.getNotes() != null) mp.setNotes(request.getNotes());
        mp = medicalProfileRepository.save(mp);
        log.info("Medical profile updated for user {}", user.getId());
        return toMedicalProfileDto(mp);
    }

    @Transactional(readOnly = true)
    public List<EmergencyContactDto> getEmergencyContacts(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("User", "email", email));
        return emergencyContactRepository.findByUser_IdOrderByCreatedAtDesc(user.getId()).stream()
                .map(this::toEmergencyContactDto)
                .collect(Collectors.toList());
    }

    @Transactional
    public EmergencyContactDto createEmergencyContact(String email, EmergencyContactRequest request) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("User", "email", email));
        EmergencyContact ec = EmergencyContact.builder()
                .user(user)
                .name(request.getName())
                .phone(request.getPhone())
                .relationship(request.getRelationship())
                .build();
        ec = emergencyContactRepository.save(ec);
        log.info("Emergency contact created for user {}, id={}", user.getId(), ec.getId());
        return toEmergencyContactDto(ec);
    }

    @Transactional
    public EmergencyContactDto updateEmergencyContact(String email, Long contactId, EmergencyContactRequest request) {
        EmergencyContact ec = getContactAndCheckUser(contactId, email);
        ec.setName(request.getName());
        ec.setPhone(request.getPhone());
        ec.setRelationship(request.getRelationship());
        ec = emergencyContactRepository.save(ec);
        log.info("Emergency contact {} updated", contactId);
        return toEmergencyContactDto(ec);
    }

    @Transactional
    public void deleteEmergencyContact(String email, Long contactId) {
        EmergencyContact ec = getContactAndCheckUser(contactId, email);
        emergencyContactRepository.delete(ec);
        log.info("Emergency contact {} deleted", contactId);
    }

    private EmergencyContact getContactAndCheckUser(Long contactId, String email) {
        EmergencyContact ec = emergencyContactRepository.findById(contactId)
                .orElseThrow(() -> new ResourceNotFoundException("Emergency contact", contactId));
        if (!ec.getUser().getEmail().equals(email)) {
            throw new ForbiddenException("Not authorized to modify this contact");
        }
        return ec;
    }

    private UserProfileDto toProfileDto(User user) {
        return UserProfileDto.builder()
                .id(user.getId())
                .email(user.getEmail())
                .fullName(user.getFullName())
                .phone(user.getPhone())
                .roles(user.getRoles().stream().map(r -> r.getName().name()).collect(Collectors.toSet()))
                .build();
    }

    private MedicalProfileDto toMedicalProfileDto(MedicalProfile mp) {
        return MedicalProfileDto.builder()
                .id(mp.getId())
                .userId(mp.getUser().getId())
                .bloodGroup(mp.getBloodGroup())
                .allergies(mp.getAllergies())
                .conditions(mp.getConditions())
                .notes(mp.getNotes())
                .build();
    }

    private EmergencyContactDto toEmergencyContactDto(EmergencyContact ec) {
        return EmergencyContactDto.builder()
                .id(ec.getId())
                .userId(ec.getUser().getId())
                .name(ec.getName())
                .phone(ec.getPhone())
                .relationship(ec.getRelationship())
                .build();
    }
}
