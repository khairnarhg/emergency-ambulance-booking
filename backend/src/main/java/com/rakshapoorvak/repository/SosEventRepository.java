package com.rakshapoorvak.repository;

import com.rakshapoorvak.model.entity.SosEvent;
import com.rakshapoorvak.model.entity.enums.SosStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;

@Repository
public interface SosEventRepository extends JpaRepository<SosEvent, Long> {

    List<SosEvent> findByUserIdOrderByCreatedAtDesc(Long userId);

    @Query("SELECT DISTINCT s.user.id FROM SosEvent s WHERE s.user.id IS NOT NULL")
    List<Long> findDistinctUserIds();

    List<SosEvent> findByUserIdAndStatusIn(Long userId, List<SosStatus> statuses);

    List<SosEvent> findByHospitalIdOrderByCreatedAtDesc(Long hospitalId, Pageable pageable);

    List<SosEvent> findByHospitalIdAndStatusIn(Long hospitalId, List<SosStatus> statuses);

    List<SosEvent> findByDriverIdAndStatusIn(Long driverId, List<SosStatus> statuses);

    List<SosEvent> findByDriverIdOrderByCreatedAtDesc(Long driverId);

    @Query("SELECT s FROM SosEvent s WHERE s.status IN :statuses ORDER BY s.createdAt DESC")
    List<SosEvent> findByStatusIn(@Param("statuses") List<SosStatus> statuses, Pageable pageable);

    @Query("SELECT s FROM SosEvent s WHERE s.hospital.id = :hospitalId AND s.status IN :statuses ORDER BY s.createdAt DESC")
    List<SosEvent> findByHospitalIdAndStatusInOrderByCreatedAtDesc(
            @Param("hospitalId") Long hospitalId,
            @Param("statuses") List<SosStatus> statuses);

    @Query(value = "SELECT s FROM SosEvent s WHERE s.hospital.id = :hospitalId AND s.status IN :statuses ORDER BY s.createdAt DESC",
            countQuery = "SELECT COUNT(s) FROM SosEvent s WHERE s.hospital.id = :hospitalId AND s.status IN :statuses")
    Page<SosEvent> findByHospitalIdAndStatusIn(
            @Param("hospitalId") Long hospitalId,
            @Param("statuses") List<SosStatus> statuses,
            Pageable pageable);

    @Query(value = "SELECT s FROM SosEvent s WHERE s.status IN :statuses ORDER BY s.createdAt DESC",
            countQuery = "SELECT COUNT(s) FROM SosEvent s WHERE s.status IN :statuses")
    Page<SosEvent> findByStatusInPage(
            @Param("statuses") List<SosStatus> statuses,
            Pageable pageable);

    @Query("SELECT s FROM SosEvent s WHERE s.driver.id = :driverId AND s.status NOT IN ('COMPLETED', 'CANCELLED')")
    List<SosEvent> findActiveByDriverId(@Param("driverId") Long driverId);

    @Query("SELECT s FROM SosEvent s WHERE s.status = 'DISPATCHING' AND s.hospital.id = :hospitalId")
    List<SosEvent> findDispatchPendingByHospitalId(@Param("hospitalId") Long hospitalId);

    long countByCreatedAtBetween(Instant start, Instant end);

    long countByHospitalIdAndCreatedAtBetween(Long hospitalId, Instant start, Instant end);

    @Query("SELECT s FROM SosEvent s " +
            "LEFT JOIN FETCH s.user " +
            "LEFT JOIN FETCH s.hospital " +
            "LEFT JOIN FETCH s.ambulance " +
            "LEFT JOIN FETCH s.driver d LEFT JOIN FETCH d.user " +
            "LEFT JOIN FETCH s.doctor doc LEFT JOIN FETCH doc.user " +
            "WHERE s.id = :id")
    java.util.Optional<SosEvent> findByIdWithAssociations(@Param("id") Long id);
}
