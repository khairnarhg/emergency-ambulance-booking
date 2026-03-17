package com.rakshapoorvak.service;

import com.rakshapoorvak.exception.ResourceNotFoundException;
import com.rakshapoorvak.model.dto.notification.NotificationDto;
import com.rakshapoorvak.model.entity.Notification;
import com.rakshapoorvak.model.entity.enums.RecipientType;
import com.rakshapoorvak.repository.DoctorRepository;
import com.rakshapoorvak.repository.DriverRepository;
import com.rakshapoorvak.repository.HospitalStaffRepository;
import com.rakshapoorvak.repository.NotificationRepository;
import com.rakshapoorvak.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Notifications for user/driver - list, unread count, mark read.
 */
@Service
public class NotificationService {

    private static final Logger log = LoggerFactory.getLogger(NotificationService.class);

    private final NotificationRepository notificationRepository;
    private final UserRepository userRepository;
    private final DriverRepository driverRepository;
    private final HospitalStaffRepository hospitalStaffRepository;
    private final DoctorRepository doctorRepository;

    public NotificationService(NotificationRepository notificationRepository, UserRepository userRepository,
                               DriverRepository driverRepository, HospitalStaffRepository hospitalStaffRepository,
                               DoctorRepository doctorRepository) {
        this.notificationRepository = notificationRepository;
        this.userRepository = userRepository;
        this.driverRepository = driverRepository;
        this.hospitalStaffRepository = hospitalStaffRepository;
        this.doctorRepository = doctorRepository;
    }

    @Transactional(readOnly = true)
    public List<NotificationDto> list(String email, int page, int size) {
        var recipient = resolveRecipient(email);
        return notificationRepository
                .findByRecipientTypeAndRecipientIdOrderByCreatedAtDesc(
                        recipient.type, recipient.id, PageRequest.of(page, size))
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public long getUnreadCount(String email) {
        var recipient = resolveRecipient(email);
        return notificationRepository.countByRecipientTypeAndRecipientIdAndIsReadFalse(recipient.type, recipient.id);
    }

    @Transactional
    public void markRead(Long id, String email) {
        var recipient = resolveRecipient(email);
        Notification n = notificationRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Notification", id));
        if (!n.getRecipientType().equals(recipient.type) || !n.getRecipientId().equals(recipient.id)) {
            throw new ResourceNotFoundException("Notification", id);
        }
        n.setIsRead(true);
        notificationRepository.save(n);
        log.debug("Notification {} marked as read", id);
    }

    @Transactional
    public void markAllRead(String email) {
        var recipient = resolveRecipient(email);
        List<Notification> unread = notificationRepository
                .findByRecipientTypeAndRecipientIdOrderByCreatedAtDesc(recipient.type, recipient.id, PageRequest.of(0, 1000))
                .stream()
                .filter(n -> !n.getIsRead())
                .collect(Collectors.toList());
        unread.forEach(n -> n.setIsRead(true));
        notificationRepository.saveAll(unread);
        log.info("Marked {} notifications as read for {} {}", unread.size(), recipient.type, recipient.id);
    }

    private Recipient resolveRecipient(String email) {
        var user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("User", "email", email));
        var driver = driverRepository.findByUserId(user.getId());
        if (driver.isPresent()) {
            return new Recipient(RecipientType.DRIVER, driver.get().getId());
        }
        var staff = hospitalStaffRepository.findByUserId(user.getId());
        if (staff.isPresent()) {
            return new Recipient(RecipientType.HOSPITAL, staff.get().getHospital().getId());
        }
        var doctor = doctorRepository.findByUserId(user.getId());
        if (doctor.isPresent()) {
            return new Recipient(RecipientType.HOSPITAL, doctor.get().getHospital().getId());
        }
        return new Recipient(RecipientType.USER, user.getId());
    }

    private NotificationDto toDto(Notification n) {
        return NotificationDto.builder()
                .id(n.getId())
                .title(n.getTitle())
                .body(n.getBody())
                .isRead(n.getIsRead())
                .createdAt(n.getCreatedAt())
                .build();
    }

    private record Recipient(RecipientType type, Long id) {}
}
