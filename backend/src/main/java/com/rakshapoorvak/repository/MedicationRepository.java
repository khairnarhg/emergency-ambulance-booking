package com.rakshapoorvak.repository;

import com.rakshapoorvak.model.entity.Medication;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface MedicationRepository extends JpaRepository<Medication, Long> {

    List<Medication> findBySosEventIdOrderByAdministeredAtDesc(Long sosEventId);
}
