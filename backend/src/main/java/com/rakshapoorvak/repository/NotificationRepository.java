package com.rakshapoorvak.repository;

import com.rakshapoorvak.model.entity.Notification;
import com.rakshapoorvak.model.entity.enums.RecipientType;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface NotificationRepository extends JpaRepository<Notification, Long> {

    List<Notification> findByRecipientTypeAndRecipientIdOrderByCreatedAtDesc(
            RecipientType recipientType, Long recipientId, Pageable pageable);

    long countByRecipientTypeAndRecipientIdAndIsReadFalse(
            RecipientType recipientType, Long recipientId);
}
