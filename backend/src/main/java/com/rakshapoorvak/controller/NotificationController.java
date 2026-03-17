package com.rakshapoorvak.controller;

import com.rakshapoorvak.model.dto.notification.NotificationDto;
import com.rakshapoorvak.security.SecurityUtils;
import com.rakshapoorvak.service.NotificationService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * Notifications - list, unread count, mark read.
 */
@RestController
@RequestMapping("/api/notifications")
public class NotificationController {

    private static final Logger log = LoggerFactory.getLogger(NotificationController.class);

    private final NotificationService notificationService;

    public NotificationController(NotificationService notificationService) {
        this.notificationService = notificationService;
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('HOSPITAL_STAFF', 'ADMIN', 'DOCTOR', 'DRIVER', 'USER')")
    public ResponseEntity<List<NotificationDto>> list(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        String email = SecurityUtils.getCurrentUserEmailOrThrow();
        return ResponseEntity.ok(notificationService.list(email, page, size));
    }

    @GetMapping("/unread-count")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<Map<String, Long>> getUnreadCount() {
        String email = SecurityUtils.getCurrentUserEmailOrThrow();
        long count = notificationService.getUnreadCount(email);
        return ResponseEntity.ok(Map.of("count", count));
    }

    @PatchMapping("/{id}/read")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<Void> markRead(@PathVariable Long id) {
        String email = SecurityUtils.getCurrentUserEmailOrThrow();
        notificationService.markRead(id, email);
        return ResponseEntity.ok().build();
    }

    @PostMapping("/read-all")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<Void> markAllRead() {
        String email = SecurityUtils.getCurrentUserEmailOrThrow();
        notificationService.markAllRead(email);
        return ResponseEntity.ok().build();
    }
}
