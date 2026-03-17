package com.rakshapoorvak.repository;

import com.rakshapoorvak.model.entity.Doctor;
import com.rakshapoorvak.model.entity.enums.DoctorStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface DoctorRepository extends JpaRepository<Doctor, Long> {

    Optional<Doctor> findByUserId(Long userId);

    List<Doctor> findByHospitalId(Long hospitalId);

    List<Doctor> findByHospitalIdAndStatus(Long hospitalId, DoctorStatus status);

    @Query("SELECT d FROM Doctor d WHERE d.hospital.id = :hospitalId AND d.status = 'AVAILABLE'")
    List<Doctor> findAvailableByHospitalId(@Param("hospitalId") Long hospitalId);
}
