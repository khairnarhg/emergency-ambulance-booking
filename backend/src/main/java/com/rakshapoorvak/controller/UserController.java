package com.rakshapoorvak.controller;

import com.rakshapoorvak.model.dto.user.*;
import com.rakshapoorvak.security.SecurityUtils;
import com.rakshapoorvak.service.UserService;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * User profile, medical profile, and emergency contacts.
 */
@RestController
@RequestMapping("/api/users")
public class UserController {

    private static final Logger log = LoggerFactory.getLogger(UserController.class);

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping({"/profile", "/me"})
    @PreAuthorize("hasRole('USER')")
    public ResponseEntity<UserProfileDto> getProfile() {
        String email = SecurityUtils.getCurrentUserEmailOrThrow();
        log.debug("GET /api/users/profile");
        return ResponseEntity.ok(userService.getProfile(email));
    }

    @PatchMapping({"/profile", "/me"})
    @PreAuthorize("hasRole('USER')")
    public ResponseEntity<UserProfileDto> updateProfile(@Valid @RequestBody UpdateProfileRequest request) {
        String email = SecurityUtils.getCurrentUserEmailOrThrow();
        log.info("PATCH /api/users/profile");
        return ResponseEntity.ok(userService.updateProfile(email, request));
    }

    @GetMapping({"/medical-profile", "/me/medical-profile"})
    @PreAuthorize("hasRole('USER')")
    public ResponseEntity<MedicalProfileDto> getMedicalProfile() {
        String email = SecurityUtils.getCurrentUserEmailOrThrow();
        return ResponseEntity.ok(userService.getMedicalProfile(email));
    }

    @PatchMapping({"/medical-profile", "/me/medical-profile"})
    @PreAuthorize("hasRole('USER')")
    public ResponseEntity<MedicalProfileDto> updateMedicalProfile(@Valid @RequestBody UpdateMedicalProfileRequest request) {
        String email = SecurityUtils.getCurrentUserEmailOrThrow();
        return ResponseEntity.ok(userService.updateMedicalProfile(email, request));
    }

    @GetMapping({"/emergency-contacts", "/me/emergency-contacts"})
    @PreAuthorize("hasRole('USER')")
    public ResponseEntity<List<EmergencyContactDto>> getEmergencyContacts() {
        String email = SecurityUtils.getCurrentUserEmailOrThrow();
        return ResponseEntity.ok(userService.getEmergencyContacts(email));
    }

    @PostMapping({"/emergency-contacts", "/me/emergency-contacts"})
    @PreAuthorize("hasRole('USER')")
    public ResponseEntity<EmergencyContactDto> createEmergencyContact(@Valid @RequestBody EmergencyContactRequest request) {
        String email = SecurityUtils.getCurrentUserEmailOrThrow();
        log.info("POST /api/users/emergency-contacts");
        EmergencyContactDto created = userService.createEmergencyContact(email, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    @PutMapping({"/emergency-contacts/{id}", "/me/emergency-contacts/{id}"})
    @PreAuthorize("hasRole('USER')")
    public ResponseEntity<EmergencyContactDto> updateEmergencyContact(@PathVariable Long id,
                                                                      @Valid @RequestBody EmergencyContactRequest request) {
        String email = SecurityUtils.getCurrentUserEmailOrThrow();
        return ResponseEntity.ok(userService.updateEmergencyContact(email, id, request));
    }

    @DeleteMapping({"/emergency-contacts/{id}", "/me/emergency-contacts/{id}"})
    @PreAuthorize("hasRole('USER')")
    public ResponseEntity<Void> deleteEmergencyContact(@PathVariable Long id) {
        String email = SecurityUtils.getCurrentUserEmailOrThrow();
        userService.deleteEmergencyContact(email, id);
        return ResponseEntity.noContent().build();
    }
}
