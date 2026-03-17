package com.rakshapoorvak.repository;

import com.rakshapoorvak.model.entity.LocationUpdate;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface LocationUpdateRepository extends JpaRepository<LocationUpdate, Long> {

    List<LocationUpdate> findBySosEventIdOrderByRecordedAtDesc(Long sosEventId);

    @Query("SELECT lu FROM LocationUpdate lu WHERE lu.sosEvent.id = :sosEventId ORDER BY lu.recordedAt DESC")
    List<LocationUpdate> findLatestBySosEventId(@Param("sosEventId") Long sosEventId);
}
