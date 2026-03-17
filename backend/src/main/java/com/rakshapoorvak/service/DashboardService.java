package com.rakshapoorvak.service;

import com.rakshapoorvak.exception.ResourceNotFoundException;
import com.rakshapoorvak.model.dto.dashboard.DashboardSummaryDto;
import com.rakshapoorvak.model.dto.dashboard.SosSummaryItemDto;
import com.rakshapoorvak.model.entity.SosEvent;
import com.rakshapoorvak.model.entity.Ambulance;
import com.rakshapoorvak.model.entity.Doctor;
import com.rakshapoorvak.model.entity.enums.AmbulanceStatus;
import com.rakshapoorvak.model.entity.enums.DoctorStatus;
import com.rakshapoorvak.model.entity.enums.DriverStatus;
import com.rakshapoorvak.model.entity.enums.SosStatus;
import com.rakshapoorvak.repository.AmbulanceRepository;
import com.rakshapoorvak.repository.DoctorRepository;
import com.rakshapoorvak.repository.DriverRepository;
import com.rakshapoorvak.repository.HospitalRepository;
import com.rakshapoorvak.repository.HospitalStaffRepository;
import com.rakshapoorvak.repository.SosEventRepository;
import com.rakshapoorvak.repository.UserRepository;
import com.rakshapoorvak.service.HospitalResolutionService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Dashboard summary and active SOS.
 */
@Service
public class DashboardService {

    private static final Logger log = LoggerFactory.getLogger(DashboardService.class);

    private final SosEventRepository sosEventRepository;
    private final AmbulanceRepository ambulanceRepository;
    private final DoctorRepository doctorRepository;
    private final DriverRepository driverRepository;
    private final HospitalRepository hospitalRepository;
    private final HospitalStaffRepository hospitalStaffRepository;
    private final UserRepository userRepository;
    private final HospitalResolutionService hospitalResolutionService;

    public DashboardService(SosEventRepository sosEventRepository, AmbulanceRepository ambulanceRepository,
                            DoctorRepository doctorRepository, DriverRepository driverRepository,
                            HospitalRepository hospitalRepository, HospitalStaffRepository hospitalStaffRepository,
                            UserRepository userRepository, HospitalResolutionService hospitalResolutionService) {
        this.sosEventRepository = sosEventRepository;
        this.ambulanceRepository = ambulanceRepository;
        this.doctorRepository = doctorRepository;
        this.driverRepository = driverRepository;
        this.hospitalRepository = hospitalRepository;
        this.hospitalStaffRepository = hospitalStaffRepository;
        this.userRepository = userRepository;
        this.hospitalResolutionService = hospitalResolutionService;
    }

    @Transactional(readOnly = true)
    public DashboardSummaryDto getSummary(String email, Long hospitalId) {
        Long targetHospitalId = hospitalResolutionService.resolveHospitalId(email, hospitalId);

        Instant startOfDay = LocalDate.now().atStartOfDay().toInstant(ZoneOffset.UTC);
        Instant endOfDay = startOfDay.plusSeconds(24 * 60 * 60);
        long totalSosToday = targetHospitalId != null
                ? sosEventRepository.countByHospitalIdAndCreatedAtBetween(targetHospitalId, startOfDay, endOfDay)
                : sosEventRepository.countByCreatedAtBetween(startOfDay, endOfDay);

        List<SosStatus> activeStatuses = List.of(SosStatus.CREATED, SosStatus.DISPATCHING, SosStatus.AMBULANCE_ASSIGNED,
                SosStatus.DRIVER_ENROUTE_TO_PATIENT, SosStatus.REACHED_PATIENT, SosStatus.PICKED_UP,
                SosStatus.ENROUTE_TO_HOSPITAL, SosStatus.ARRIVED_AT_HOSPITAL);
        List<com.rakshapoorvak.model.entity.SosEvent> activeSosList = targetHospitalId != null
                ? sosEventRepository.findByHospitalIdAndStatusInOrderByCreatedAtDesc(targetHospitalId, activeStatuses)
                : sosEventRepository.findByStatusIn(activeStatuses, org.springframework.data.domain.PageRequest.of(0, 50));

        long ambulancesAvailable = targetHospitalId != null
                ? ambulanceRepository.findAvailableByHospitalId(targetHospitalId).size()
                : ambulanceRepository.findAll().stream().filter(a -> a.getStatus() == AmbulanceStatus.AVAILABLE).count();

        long driversAvailable = targetHospitalId != null
                ? driverRepository.findAvailableByHospitalId(targetHospitalId).size()
                : driverRepository.findAll().stream().filter(d -> d.getStatus() == DriverStatus.AVAILABLE).count();

        List<Ambulance> allAmbulances = targetHospitalId != null
                ? ambulanceRepository.findByHospitalId(targetHospitalId)
                : ambulanceRepository.findAll();
        long totalAmbulances = allAmbulances.size();

        List<Doctor> allDoctors = targetHospitalId != null
                ? doctorRepository.findByHospitalId(targetHospitalId)
                : doctorRepository.findAll();
        long totalDoctors = allDoctors.size();
        long doctorsAvailable = targetHospitalId != null
                ? doctorRepository.findAvailableByHospitalId(targetHospitalId).size()
                : allDoctors.stream().filter(d -> d.getStatus() == DoctorStatus.AVAILABLE).count();

        double avgResponseMinutes = 0;
        List<SosEvent> completedList = targetHospitalId != null
                ? sosEventRepository.findByHospitalIdAndStatusInOrderByCreatedAtDesc(targetHospitalId, List.of(SosStatus.COMPLETED))
                : sosEventRepository.findByStatusIn(List.of(SosStatus.COMPLETED), org.springframework.data.domain.PageRequest.of(0, 100));
        if (!completedList.isEmpty()) {
            long totalMin = completedList.stream()
                    .filter(s -> s.getCompletedAt() != null)
                    .mapToLong(s -> java.time.temporal.ChronoUnit.MINUTES.between(s.getCreatedAt(), s.getCompletedAt()))
                    .filter(m -> m >= 0)
                    .sum();
            long count = completedList.stream().filter(s -> s.getCompletedAt() != null).count();
            if (count > 0) avgResponseMinutes = (double) totalMin / count;
        }

        List<SosSummaryItemDto> items = activeSosList.stream()
                .map(s -> SosSummaryItemDto.builder()
                        .id(s.getId())
                        .userName(s.getUser() != null ? s.getUser().getFullName() : null)
                        .status(s.getStatus().name())
                        .criticality(s.getCriticality() != null ? s.getCriticality().name() : null)
                        .address(s.getAddress())
                        .createdAt(s.getCreatedAt())
                        .build())
                .collect(Collectors.toList());

        return DashboardSummaryDto.builder()
                .totalSosToday(totalSosToday)
                .activeSosCount((long) activeSosList.size())
                .availableAmbulances(ambulancesAvailable)
                .totalAmbulances(totalAmbulances)
                .availableDoctors(doctorsAvailable)
                .totalDoctors(totalDoctors)
                .avgResponseTimeMinutes(avgResponseMinutes)
                .activeSosList(items)
                .build();
    }

    @Transactional(readOnly = true)
    public List<SosSummaryItemDto> getActiveSos(String email, Long hospitalId) {
        Long targetHospitalId = hospitalResolutionService.resolveHospitalId(email, hospitalId);
        List<SosStatus> active = List.of(SosStatus.CREATED, SosStatus.DISPATCHING, SosStatus.AMBULANCE_ASSIGNED,
                SosStatus.DRIVER_ENROUTE_TO_PATIENT, SosStatus.REACHED_PATIENT, SosStatus.PICKED_UP,
                SosStatus.ENROUTE_TO_HOSPITAL, SosStatus.ARRIVED_AT_HOSPITAL);
        var list = targetHospitalId != null
                ? sosEventRepository.findByHospitalIdAndStatusInOrderByCreatedAtDesc(targetHospitalId, active)
                : sosEventRepository.findByStatusIn(active, org.springframework.data.domain.PageRequest.of(0, 100));
        return list.stream()
                .map(s -> SosSummaryItemDto.builder()
                        .id(s.getId())
                        .userName(s.getUser() != null ? s.getUser().getFullName() : null)
                        .status(s.getStatus().name())
                        .criticality(s.getCriticality() != null ? s.getCriticality().name() : null)
                        .address(s.getAddress())
                        .createdAt(s.getCreatedAt())
                        .build())
                .collect(Collectors.toList());
    }

}
