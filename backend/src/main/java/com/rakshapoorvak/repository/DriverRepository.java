package com.rakshapoorvak.repository;

import com.rakshapoorvak.model.entity.Driver;
import com.rakshapoorvak.model.entity.enums.DriverStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface DriverRepository extends JpaRepository<Driver, Long> {

    Optional<Driver> findByUserId(Long userId);

    List<Driver> findByHospitalId(Long hospitalId);

    List<Driver> findByHospitalIdAndStatus(Long hospitalId, DriverStatus status);

    @Query("SELECT d FROM Driver d WHERE d.hospital.id = :hospitalId AND d.status = 'AVAILABLE'")
    List<Driver> findAvailableByHospitalId(@Param("hospitalId") Long hospitalId);

    Optional<Driver> findByAmbulanceId(Long ambulanceId);
}
