package com.rakshapoorvak.repository;

import com.rakshapoorvak.model.entity.Ambulance;
import com.rakshapoorvak.model.entity.enums.AmbulanceStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface AmbulanceRepository extends JpaRepository<Ambulance, Long> {

    List<Ambulance> findByHospitalId(Long hospitalId);

    List<Ambulance> findByHospitalIdAndStatus(Long hospitalId, AmbulanceStatus status);

    Optional<Ambulance> findByRegistrationNumber(String registrationNumber);

    @Query("SELECT a FROM Ambulance a WHERE a.hospital.id = :hospitalId AND a.status = 'AVAILABLE'")
    List<Ambulance> findAvailableByHospitalId(@Param("hospitalId") Long hospitalId);
}
