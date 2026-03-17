package com.rakshapoorvak.repository;

import com.rakshapoorvak.model.entity.TriageRecord;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TriageRecordRepository extends JpaRepository<TriageRecord, Long> {

    List<TriageRecord> findBySosEventIdOrderByRecordedAtDesc(Long sosEventId);
}
