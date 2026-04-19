package com.rakshapoorvak.service;

import com.rakshapoorvak.model.dto.notification.NotificationDto;
import com.rakshapoorvak.model.dto.sos.SosEventDto;
import com.rakshapoorvak.model.entity.Notification;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.Map;

@Service
public class WebSocketBroadcastService {

    private static final Logger log = LoggerFactory.getLogger(WebSocketBroadcastService.class);

    private final SimpMessagingTemplate messagingTemplate;

    public WebSocketBroadcastService(SimpMessagingTemplate messagingTemplate) {
        this.messagingTemplate = messagingTemplate;
    }

    public void broadcastSosStatusChange(Long sosId, SosEventDto sosDto) {
        messagingTemplate.convertAndSend("/topic/sos/" + sosId + "/status", sosDto);
        log.debug("Broadcast SOS #{} status: {}", sosId, sosDto.getStatus());
    }

    public void broadcastAmbulanceLocation(Long sosId, BigDecimal latitude, BigDecimal longitude, Long ambulanceId) {
        Map<String, Object> payload = Map.of(
                "sosEventId", sosId,
                "ambulanceId", ambulanceId,
                "latitude", latitude,
                "longitude", longitude,
                "timestamp", java.time.Instant.now().toString()
        );
        messagingTemplate.convertAndSend("/topic/sos/" + sosId + "/location", payload);
    }

    public void broadcastDispatchToDriver(Long driverId, SosEventDto sosDto) {
        messagingTemplate.convertAndSend("/topic/dispatch/driver/" + driverId, sosDto);
        log.debug("Broadcast dispatch to driver #{} for SOS #{}", driverId, sosDto.getId());
    }

    public void broadcastNotificationToUser(Long userId, Notification notification) {
        NotificationDto dto = toDto(notification);
        messagingTemplate.convertAndSend("/topic/notifications/user/" + userId, dto);
    }

    public void broadcastNotificationToDriver(Long driverId, Notification notification) {
        NotificationDto dto = toDto(notification);
        messagingTemplate.convertAndSend("/topic/notifications/driver/" + driverId, dto);
    }

    public void broadcastNotificationToHospital(Long hospitalId, Notification notification) {
        NotificationDto dto = toDto(notification);
        messagingTemplate.convertAndSend("/topic/notifications/hospital/" + hospitalId, dto);
    }

    public void broadcastDashboardRefresh(Long hospitalId) {
        messagingTemplate.convertAndSend("/topic/dashboard/" + hospitalId, Map.of("refresh", true));
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
}
