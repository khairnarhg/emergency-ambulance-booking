package com.rakshapoorvak.repository;

import com.rakshapoorvak.model.entity.SosHospitalHistory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.Set;

@Repository
public interface SosHospitalHistoryRepository extends JpaRepository<SosHospitalHistory, Long> {

    List<SosHospitalHistory> findBySosEventId(Long sosEventId);

    Optional<SosHospitalHistory> findBySosEventIdAndHospitalId(Long sosEventId, Long hospitalId);

    @Query("SELECT h.hospital.id FROM SosHospitalHistory h WHERE h.sosEvent.id = :sosEventId")
    Set<Long> findHospitalIdsBySosEventId(Long sosEventId);
}
