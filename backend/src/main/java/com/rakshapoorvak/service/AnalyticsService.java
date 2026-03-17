package com.rakshapoorvak.service;

import com.rakshapoorvak.exception.ResourceNotFoundException;
import com.rakshapoorvak.model.dto.analytics.*;
import com.rakshapoorvak.model.entity.SosEvent;
import com.rakshapoorvak.model.entity.enums.SosStatus;
import com.rakshapoorvak.model.entity.enums.Criticality;
import com.rakshapoorvak.repository.AmbulanceRepository;
import com.rakshapoorvak.repository.DoctorRepository;
import com.rakshapoorvak.repository.HospitalStaffRepository;
import com.rakshapoorvak.repository.SosEventRepository;
import com.rakshapoorvak.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Analytics - response times, emergency volume, dashboard.
 */
@Service
public class AnalyticsService {

    private static final Logger log = LoggerFactory.getLogger(AnalyticsService.class);

    private final SosEventRepository sosEventRepository;
    private final AmbulanceRepository ambulanceRepository;
    private final UserRepository userRepository;
    private final HospitalStaffRepository hospitalStaffRepository;
    private final DoctorRepository doctorRepository;

    public AnalyticsService(SosEventRepository sosEventRepository, AmbulanceRepository ambulanceRepository,
                            UserRepository userRepository, HospitalStaffRepository hospitalStaffRepository,
                            DoctorRepository doctorRepository) {
        this.sosEventRepository = sosEventRepository;
        this.ambulanceRepository = ambulanceRepository;
        this.userRepository = userRepository;
        this.hospitalStaffRepository = hospitalStaffRepository;
        this.doctorRepository = doctorRepository;
    }

    @Transactional(readOnly = true)
    public ResponseTimeDto getResponseTimes(Long hospitalId, int days) {
        Instant start = LocalDate.now().minusDays(days).atStartOfDay().toInstant(ZoneOffset.UTC);
        List<SosEvent> completed = getCompletedSos(start, hospitalId);

        List<Long> durationsMinutes = completed.stream()
                .map(s -> ChronoUnit.MINUTES.between(s.getCreatedAt(), s.getCompletedAt()))
                .filter(m -> m >= 0)
                .collect(Collectors.toList());

        double avg = durationsMinutes.isEmpty() ? 0
                : durationsMinutes.stream().mapToLong(Long::longValue).average().orElse(0);
        double median = durationsMinutes.isEmpty() ? 0 : median(durationsMinutes);

        long minM = durationsMinutes.isEmpty() ? 0 : durationsMinutes.stream().mapToLong(Long::longValue).min().orElse(0);
        long maxM = durationsMinutes.isEmpty() ? 0 : durationsMinutes.stream().mapToLong(Long::longValue).max().orElse(0);
        return ResponseTimeDto.builder()
                .averageMinutes(avg)
                .medianMinutes(median)
                .minMinutes(durationsMinutes.isEmpty() ? null : (double) minM)
                .maxMinutes(durationsMinutes.isEmpty() ? null : (double) maxM)
                .totalCompleted(durationsMinutes.size())
                .build();
    }

    @Transactional(readOnly = true)
    public EmergencyVolumeDto getEmergencyVolume(Long hospitalId, int days) {
        Instant start = LocalDate.now().minusDays(days).atStartOfDay().toInstant(ZoneOffset.UTC);
        List<SosEvent> completed = getCompletedSos(start, hospitalId);

        List<VolumeBucketDto> byDay = new ArrayList<>();
        for (int i = days - 1; i >= 0; i--) {
            LocalDate d = LocalDate.now().minusDays(i);
            Instant dayStart = d.atStartOfDay().toInstant(ZoneOffset.UTC);
            Instant dayEnd = d.plusDays(1).atStartOfDay().toInstant(ZoneOffset.UTC);
            long count = completed.stream()
                    .filter(s -> !s.getCreatedAt().isBefore(dayStart) && s.getCreatedAt().isBefore(dayEnd))
                    .count();
            byDay.add(VolumeBucketDto.builder()
                    .label(d.toString())
                    .date(d.toString())
                    .count(count)
                    .startTime(dayStart)
                    .build());
        }

        List<VolumeBucketDto> byHour = new ArrayList<>();
        for (int h = 0; h < 24; h++) {
            final int hour = h;
            long count = completed.stream()
                    .filter(s -> s.getCreatedAt().atZone(ZoneOffset.UTC).getHour() == hour)
                    .count();
            byHour.add(VolumeBucketDto.builder()
                    .label(String.valueOf(h))
                    .count(count)
                    .startTime(null)
                    .build());
        }

        return EmergencyVolumeDto.builder()
                .byDay(byDay)
                .byHour(byHour)
                .build();
    }

    @Transactional(readOnly = true)
    public AnalyticsDashboardDto getAnalyticsDashboard(String email, Long hospitalId, int days) {
        Long targetHospitalId = resolveHospitalId(email, hospitalId);
        ResponseTimeDto responseTimes = getResponseTimes(targetHospitalId, days);
        EmergencyVolumeDto volume = getEmergencyVolume(targetHospitalId, days);
        Instant start = LocalDate.now().minusDays(days).atStartOfDay().toInstant(ZoneOffset.UTC);
        List<SosEvent> completed = getCompletedSos(start, targetHospitalId);

        long total = completed.size();

        Map<String, Long> bySeverity = new HashMap<>();
        for (SosEvent s : completed) {
            String key = s.getCriticality() != null ? s.getCriticality().name() : "UNKNOWN";
            bySeverity.merge(key, 1L, Long::sum);
        }

        Map<String, Long> ambulanceUtil = new HashMap<>();
        var ambulances = targetHospitalId != null ? ambulanceRepository.findByHospitalId(targetHospitalId)
                : ambulanceRepository.findAll();
        for (var a : ambulances) {
            long count = completed.stream().filter(s -> s.getAmbulance() != null
                    && s.getAmbulance().getId().equals(a.getId())).count();
            if (count > 0) {
                ambulanceUtil.put(a.getRegistrationNumber(), count);
            }
        }

        return AnalyticsDashboardDto.builder()
                .responseTimes(responseTimes)
                .emergencyVolume(volume)
                .volume(volume.getByDay())
                .totalSosCount(total)
                .bySeverity(bySeverity)
                .ambulanceUtilization(ambulanceUtil)
                .build();
    }

    @Transactional(readOnly = true)
    public List<Map<String, Object>> getHotspots(int days) {
        Instant start = LocalDate.now().minusDays(days).atStartOfDay().toInstant(ZoneOffset.UTC);
        List<SosEvent> allSos = sosEventRepository.findAll().stream()
                .filter(s -> !s.getCreatedAt().isBefore(start))
                .collect(Collectors.toList());

        Map<String, List<SosEvent>> grid = new HashMap<>();
        for (SosEvent s : allSos) {
            double roundedLat = Math.round(s.getLatitude().doubleValue() * 100.0) / 100.0;
            double roundedLng = Math.round(s.getLongitude().doubleValue() * 100.0) / 100.0;
            String key = roundedLat + "," + roundedLng;
            grid.computeIfAbsent(key, k -> new ArrayList<>()).add(s);
        }

        return grid.entrySet().stream()
                .sorted((a, b) -> Integer.compare(b.getValue().size(), a.getValue().size()))
                .limit(10)
                .map(e -> {
                    String[] parts = e.getKey().split(",");
                    Map<String, Object> m = new HashMap<>();
                    m.put("latitude", Double.parseDouble(parts[0]));
                    m.put("longitude", Double.parseDouble(parts[1]));
                    m.put("count", e.getValue().size());
                    m.put("suggestedLabel", "Area " + parts[0] + ", " + parts[1]);
                    return m;
                })
                .collect(Collectors.toList());
    }

    private List<SosEvent> getCompletedSos(Instant start, Long hospitalId) {
        List<SosEvent> completed = hospitalId != null
                ? sosEventRepository.findByHospitalIdAndStatusInOrderByCreatedAtDesc(
                        hospitalId, List.of(SosStatus.COMPLETED))
                : sosEventRepository.findByStatusIn(List.of(SosStatus.COMPLETED),
                        org.springframework.data.domain.PageRequest.of(0, 10000));
        return completed.stream()
                .filter(s -> !s.getCreatedAt().isBefore(start) && s.getCompletedAt() != null)
                .collect(Collectors.toList());
    }

    private double median(List<Long> list) {
        if (list.isEmpty()) return 0;
        List<Long> sorted = list.stream().sorted().collect(Collectors.toList());
        int mid = sorted.size() / 2;
        return sorted.size() % 2 == 0
                ? (sorted.get(mid - 1) + sorted.get(mid)) / 2.0
                : sorted.get(mid);
    }

    private Long resolveHospitalId(String email, Long hospitalId) {
        if (hospitalId != null) return hospitalId;
        var user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("User", "email", email));
        var staff = hospitalStaffRepository.findByUserId(user.getId());
        if (staff.isPresent()) return staff.get().getHospital().getId();
        var doctor = doctorRepository.findByUserId(user.getId());
        if (doctor.isPresent()) return doctor.get().getHospital().getId();
        return null;
    }
}
