package com.rakshapoorvak.repository;

import com.rakshapoorvak.model.entity.EmergencyContact;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface EmergencyContactRepository extends JpaRepository<EmergencyContact, Long> {

    @Query("SELECT e FROM EmergencyContact e WHERE e.user.id = :userId ORDER BY e.createdAt DESC")
    List<EmergencyContact> findByUser_IdOrderByCreatedAtDesc(@Param("userId") Long userId);
}
