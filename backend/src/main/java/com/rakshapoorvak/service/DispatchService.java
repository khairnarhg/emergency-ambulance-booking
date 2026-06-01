package com.rakshapoorvak.service;

import com.rakshapoorvak.exception.BadRequestException;
import com.rakshapoorvak.exception.ResourceNotFoundException;
import com.rakshapoorvak.model.dto.sos.SosEventDto;
import com.rakshapoorvak.model.entity.*;
import com.rakshapoorvak.model.entity.enums.*;
import com.rakshapoorvak.repository.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class DispatchService {

    private static final Logger log = LoggerFactory.getLogger(DispatchService.class);

    private final SosEventRepository sosEventRepository;
    private final AmbulanceRepository ambulanceRepository;
    private final DriverRepository driverRepository;
    private final DoctorRepository doctorRepository;
    private final HospitalStaffRepository hospitalStaffRepository;
    private final HospitalRepository hospitalRepository;
    private final UserRepository userRepository;
    private final NotificationRepository notificationRepository;
    private final SosHospitalHistoryRepository sosHospitalHistoryRepository;
    private final SosService sosService;
    private final WebSocketBroadcastService broadcastService;

    public DispatchService(SosEventRepository sosEventRepository, AmbulanceRepository ambulanceRepository,
                           DriverRepository driverRepository, DoctorRepository doctorRepository,
                           HospitalStaffRepository hospitalStaffRepository, HospitalRepository hospitalRepository,
                           UserRepository userRepository, NotificationRepository notificationRepository,
                           SosHospitalHistoryRepository sosHospitalHistoryRepository,
                           SosService sosService, WebSocketBroadcastService broadcastService) {
        this.sosEventRepository = sosEventRepository;
        this.ambulanceRepository = ambulanceRepository;
        this.driverRepository = driverRepository;
        this.doctorRepository = doctorRepository;
        this.hospitalStaffRepository = hospitalStaffRepository;
        this.hospitalRepository = hospitalRepository;
        this.userRepository = userRepository;
        this.notificationRepository = notificationRepository;
        this.sosHospitalHistoryRepository = sosHospitalHistoryRepository;
        this.sosService = sosService;
        this.broadcastService = broadcastService;
    }

    @Transactional
    public SosEventDto findAmbulance(Long sosId) {
        return findAmbulanceExcluding(sosId, Collections.emptySet());
    }

    /**
     * Cascading smart dispatch: nearest hospital auto-assigned, same-branch first, cross-branch fallback.
     */
    @Transactional
    public SosEventDto findAmbulanceExcluding(Long sosId, Set<Long> excludedAmbulanceIds) {
        SosEvent sos = sosEventRepository.findByIdWithAssociations(sosId)
                .orElseThrow(() -> new ResourceNotFoundException("SOS event", sosId));

        if (sos.getStatus() != SosStatus.CREATED && sos.getStatus() != SosStatus.DISPATCHING) {
            throw new BadRequestException("SOS already has ambulance or is completed");
        }

        double patientLat = sos.getLatitude().doubleValue();
        double patientLon = sos.getLongitude().doubleValue();

        if (sos.getHospital() == null) {
            Hospital nearest = findNearestHospital(patientLat, patientLon);
            if (nearest != null) {
                sos.setHospital(nearest);
                sosEventRepository.save(sos);
                log.info("Auto-assigned nearest hospital {} to SOS {}", nearest.getName(), sosId);
            }
        }

        Ambulance selectedAmbulance = null;
        if (sos.getHospital() != null) {
            selectedAmbulance = findNearestAvailableAmbulance(
                    sos.getHospital().getId(), patientLat, patientLon, excludedAmbulanceIds);
        }

        if (selectedAmbulance == null) {
            selectedAmbulance = findNearestAvailableAmbulanceAcrossAll(patientLat, patientLon, excludedAmbulanceIds);
        }

        if (selectedAmbulance == null) {
            sos.setStatus(SosStatus.DISPATCHING);
            sosEventRepository.save(sos);
            throw new BadRequestException("No ambulance available across all MGM branches. Please try again shortly.");
        }

        // Find driver assigned to the selected ambulance first
        Driver driver = driverRepository.findByAmbulanceId(selectedAmbulance.getId())
                .filter(d -> d.getStatus() == DriverStatus.AVAILABLE)
                .orElse(null);

        // Fallback: find nearest available driver by their ambulance location
        if (driver == null) {
            List<Driver> allDrivers = driverRepository.findAll().stream()
                    .filter(d -> d.getStatus() == DriverStatus.AVAILABLE)
                    .filter(d -> d.getAmbulance() != null)
                    .sorted(Comparator.comparingDouble(d -> {
                        Ambulance amb = d.getAmbulance();
                        if (amb.getCurrentLatitude() == null || amb.getCurrentLongitude() == null) {
                            return Double.MAX_VALUE;
                        }
                        return SosService.haversine(patientLat, patientLon,
                                amb.getCurrentLatitude().doubleValue(),
                                amb.getCurrentLongitude().doubleValue());
                    }))
                    .collect(Collectors.toList());
            driver = allDrivers.isEmpty() ? null : allDrivers.get(0);
            if (driver != null && driver.getAmbulance() != null) {
                selectedAmbulance = driver.getAmbulance();
            }
        }

        if (driver == null) {
            sos.setStatus(SosStatus.DISPATCHING);
            sosEventRepository.save(sos);
            throw new BadRequestException("No available driver. Please try again shortly.");
        }

        sos.setAmbulance(selectedAmbulance);
        sos.setDriver(driver);
        if (sos.getHospital() == null) {
            sos.setHospital(selectedAmbulance.getHospital());
        }
        // Status stays DISPATCHING until driver accepts - driver remains AVAILABLE
        sos.setStatus(SosStatus.DISPATCHING);
        sos.setDispatchedAt(Instant.now());
        selectedAmbulance.setStatus(AmbulanceStatus.DISPATCHED);
        // Driver stays AVAILABLE so they can see pending requests
        ambulanceRepository.save(selectedAmbulance);
        sos = sosEventRepository.save(sos);

        Notification driverNotif = notificationRepository.save(Notification.builder()
                .recipientType(RecipientType.DRIVER)
                .recipientId(driver.getId())
                .title("New Emergency Dispatch")
                .body("Patient: " + sos.getUser().getFullName() + " – " +
                        (sos.getCriticality() != null ? sos.getCriticality().name() : "UNKNOWN"))
                .build());
        broadcastService.broadcastNotificationToDriver(driver.getId(), driverNotif);

        Notification userNotif = notificationRepository.save(Notification.builder()
                .recipientType(RecipientType.USER)
                .recipientId(sos.getUser().getId())
                .title("Finding Ambulance")
                .body("Looking for the nearest ambulance. Please wait...")
                .build());
        broadcastService.broadcastNotificationToUser(sos.getUser().getId(), userNotif);

        if (sos.getHospital() != null) {
            Notification hospNotif = notificationRepository.save(Notification.builder()
                    .recipientType(RecipientType.HOSPITAL)
                    .recipientId(sos.getHospital().getId())
                    .title("Ambulance Dispatched")
                    .body("Ambulance " + selectedAmbulance.getRegistrationNumber() +
                            " dispatched for SOS #" + sosId)
                    .build());
            broadcastService.broadcastNotificationToHospital(sos.getHospital().getId(), hospNotif);
            broadcastService.broadcastDashboardRefresh(sos.getHospital().getId());
        }

        log.info("Ambulance {} assigned to SOS {} (driver: {})", selectedAmbulance.getId(), sosId, driver.getId());
        SosEventDto result = sosService.getById(sosId);
        broadcastService.broadcastSosStatusChange(sosId, result);
        broadcastService.broadcastDispatchToDriver(driver.getId(), result);
        return result;
    }

    @Transactional
    public SosEventDto accept(Long sosId, String driverEmail) {
        SosEvent sos = sosEventRepository.findByIdWithAssociations(sosId)
                .orElseThrow(() -> new ResourceNotFoundException("SOS event", sosId));

        Driver driver = driverRepository.findByUserId(
                userRepository.findByEmail(driverEmail).orElseThrow().getId())
                .orElseThrow(() -> new ResourceNotFoundException("Driver", "email", driverEmail));

        if (sos.getDriver() == null || !sos.getDriver().getId().equals(driver.getId())) {
            throw new BadRequestException("This SOS is not assigned to you");
        }

        if (sos.getStatus() != SosStatus.DISPATCHING) {
            throw new BadRequestException("SOS is not in dispatch state");
        }

        // Now driver accepts - set BUSY and move to DRIVER_ENROUTE
        driver.setStatus(DriverStatus.BUSY);
        driverRepository.save(driver);
        sos.setStatus(SosStatus.DRIVER_ENROUTE_TO_PATIENT);
        sos = sosEventRepository.save(sos);

        // Notify user that ambulance is confirmed
        Notification userNotif = notificationRepository.save(Notification.builder()
                .recipientType(RecipientType.USER)
                .recipientId(sos.getUser().getId())
                .title("Ambulance Confirmed!")
                .body("Driver " + driver.getUser().getFullName() + " is on the way!")
                .build());
        broadcastService.broadcastNotificationToUser(sos.getUser().getId(), userNotif);

        // Broadcast status change
        SosEventDto result = sosService.getById(sosId);
        broadcastService.broadcastSosStatusChange(sosId, result);

        log.info("Driver {} accepted SOS {}", driver.getId(), sosId);
        return result;
    }

    @Transactional(readOnly = true)
    public List<SosEventDto> getPendingRequests(String driverEmail) {
        Driver driver = driverRepository.findByUserId(
                userRepository.findByEmail(driverEmail).orElseThrow(
                        () -> new ResourceNotFoundException("Driver", "email", driverEmail)).getId())
                .orElseThrow(() -> new ResourceNotFoundException("Driver", "email", driverEmail));
        // Look for DISPATCHING status - waiting for driver acceptance
        return sosEventRepository.findByDriverIdAndStatusIn(driver.getId(),
                List.of(SosStatus.DISPATCHING)).stream()
                .map(sosService::toDto)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public SosEventDto getRequestDetails(Long sosId) {
        return sosService.getById(sosId);
    }

    @Transactional
    public SosEventDto reject(Long sosId, String driverEmail) {
        SosEvent sos = sosEventRepository.findByIdWithAssociations(sosId)
                .orElseThrow(() -> new ResourceNotFoundException("SOS event", sosId));

        Driver driver = driverRepository.findByUserId(
                userRepository.findByEmail(driverEmail).orElseThrow().getId())
                .orElseThrow(() -> new ResourceNotFoundException("Driver", "email", driverEmail));

        if (sos.getDriver() == null || !sos.getDriver().getId().equals(driver.getId())) {
            throw new BadRequestException("This SOS is not assigned to you");
        }

        Long rejectedAmbulanceId = sos.getAmbulance() != null ? sos.getAmbulance().getId() : null;
        Ambulance ambulance = sos.getAmbulance();

        sos.setDriver(null);
        sos.setAmbulance(null);
        sos.setStatus(SosStatus.DISPATCHING);
        driver.setStatus(DriverStatus.AVAILABLE);
        if (ambulance != null) {
            ambulance.setStatus(AmbulanceStatus.AVAILABLE);
            ambulanceRepository.save(ambulance);
        }
        driverRepository.save(driver);
        sosEventRepository.save(sos);
        log.info("Driver {} rejected SOS {}", driver.getId(), sosId);

        if (sos.getHospital() != null) {
            notificationRepository.save(Notification.builder()
                    .recipientType(RecipientType.HOSPITAL)
                    .recipientId(sos.getHospital().getId())
                    .title("Driver Rejected Dispatch")
                    .body("Driver " + driver.getUser().getFullName() + " rejected SOS #" + sosId + ". Reassigning...")
                    .build());
        }

        Set<Long> excluded = new HashSet<>();
        if (rejectedAmbulanceId != null) excluded.add(rejectedAmbulanceId);

        try {
            return findAmbulanceExcluding(sosId, excluded);
        } catch (BadRequestException e) {
            sos.setStatus(SosStatus.CREATED);
            sosEventRepository.save(sos);
            if (sos.getHospital() != null) {
                notificationRepository.save(Notification.builder()
                        .recipientType(RecipientType.HOSPITAL)
                        .recipientId(sos.getHospital().getId())
                        .title("No Ambulance Available")
                        .body("No ambulance accepted for SOS #" + sosId + ". Manual dispatch required.")
                        .build());
            }
            return sosService.getById(sosId);
        }
    }

    @Transactional
    public SosEventDto assignDoctor(Long sosId) {
        SosEvent sos = sosEventRepository.findByIdWithAssociations(sosId)
                .orElseThrow(() -> new ResourceNotFoundException("SOS event", sosId));

        if (sos.getHospital() == null) {
            throw new BadRequestException("SOS must have hospital before doctor assignment");
        }

        List<Doctor> available = doctorRepository.findAvailableByHospitalId(sos.getHospital().getId());
        if (available.isEmpty()) {
            notificationRepository.save(Notification.builder()
                    .recipientType(RecipientType.USER)
                    .recipientId(sos.getUser().getId())
                    .title("No Doctor Available")
                    .body("No doctor is currently available. You will be notified when one is assigned.")
                    .build());
            throw new BadRequestException("No doctor available. User has been notified.");
        }

        Doctor doctor = available.get(0);
        sos.setDoctor(doctor);
        doctor.setStatus(DoctorStatus.BUSY);
        doctorRepository.save(doctor);
        sos = sosEventRepository.save(sos);

        notificationRepository.save(Notification.builder()
                .recipientType(RecipientType.USER)
                .recipientId(sos.getUser().getId())
                .title("Doctor Assigned")
                .body("Dr. " + doctor.getUser().getFullName() + " has been assigned to your case.")
                .build());

        log.info("Doctor {} assigned to SOS {}", doctor.getId(), sosId);
        return sosService.getById(sosId);
    }

    @Transactional
    public SosEventDto unassignDoctor(Long sosId) {
        SosEvent sos = sosEventRepository.findByIdWithAssociations(sosId)
                .orElseThrow(() -> new ResourceNotFoundException("SOS event", sosId));

        if (sos.getDoctor() == null) {
            return sosService.getById(sosId);
        }

        Doctor doctor = sos.getDoctor();
        sos.setDoctor(null);
        doctor.setStatus(DoctorStatus.AVAILABLE);
        doctorRepository.save(doctor);
        sosEventRepository.save(sos);
        log.info("Doctor unassigned from SOS {}", sosId);
        return sosService.getById(sosId);
    }

    /**
     * Hospital declines the SOS request - escalate to next nearest hospital.
     */
    @Transactional
    public SosEventDto decline(Long sosId) {
        return escalateToNextHospital(sosId, EscalationReason.DECLINED);
    }

    /**
     * Hospital timeout - escalate to next nearest hospital.
     */
    @Transactional
    public SosEventDto escalateTimeout(Long sosId) {
        return escalateToNextHospital(sosId, EscalationReason.TIMEOUT);
    }

    /**
     * Driver timeout - try next ambulance at same hospital, or escalate to next hospital.
     */
    @Transactional
    public SosEventDto escalateDriverTimeout(Long sosId) {
        SosEvent sos = sosEventRepository.findByIdWithAssociations(sosId)
                .orElseThrow(() -> new ResourceNotFoundException("SOS event", sosId));

        if (sos.getStatus() != SosStatus.DISPATCHING) {
            throw new BadRequestException("SOS is not awaiting driver response");
        }

        Long currentAmbulanceId = sos.getAmbulance() != null ? sos.getAmbulance().getId() : null;

        // Release current ambulance/driver
        if (sos.getAmbulance() != null) {
            sos.getAmbulance().setStatus(AmbulanceStatus.AVAILABLE);
            ambulanceRepository.save(sos.getAmbulance());
        }
        sos.setAmbulance(null);
        sos.setDriver(null);
        sos.setDispatchedAt(null);
        sosEventRepository.save(sos);

        // Try to find another ambulance at same hospital
        Set<Long> excluded = new HashSet<>();
        if (currentAmbulanceId != null) excluded.add(currentAmbulanceId);

        try {
            return findAmbulanceExcluding(sosId, excluded);
        } catch (BadRequestException e) {
            // No more ambulances at this hospital - escalate
            return escalateToNextHospital(sosId, EscalationReason.DRIVER_TIMEOUT);
        }
    }

    /**
     * Escalate SOS to the next nearest hospital.
     */
    @Transactional
    public SosEventDto escalateToNextHospital(Long sosId, EscalationReason reason) {
        SosEvent sos = sosEventRepository.findByIdWithAssociations(sosId)
                .orElseThrow(() -> new ResourceNotFoundException("SOS event", sosId));

        if (sos.getStatus() != SosStatus.CREATED && sos.getStatus() != SosStatus.DISPATCHING) {
            throw new BadRequestException("Cannot escalate SOS after driver has accepted");
        }

        Hospital previousHospital = sos.getHospital();

        // Mark current hospital in history with the reason
        if (previousHospital != null) {
            sosHospitalHistoryRepository.findBySosEventIdAndHospitalId(sosId, previousHospital.getId())
                    .ifPresent(history -> {
                        history.setRespondedAt(Instant.now());
                        history.setResponse(reason);
                        sosHospitalHistoryRepository.save(history);
                    });
        }

        // Release any assigned ambulance/driver
        if (sos.getAmbulance() != null) {
            sos.getAmbulance().setStatus(AmbulanceStatus.AVAILABLE);
            ambulanceRepository.save(sos.getAmbulance());
            sos.setAmbulance(null);
        }
        if (sos.getDriver() != null) {
            sos.getDriver().setStatus(DriverStatus.AVAILABLE);
            driverRepository.save(sos.getDriver());
            sos.setDriver(null);
        }

        // Find next nearest hospital excluding all previously notified
        Set<Long> excludedHospitalIds = sosHospitalHistoryRepository.findHospitalIdsBySosEventId(sosId);
        Hospital nextHospital = findNextNearestHospital(
                sos.getLatitude().doubleValue(),
                sos.getLongitude().doubleValue(),
                excludedHospitalIds
        );

        if (nextHospital == null) {
            // No more hospitals available
            sos.setStatus(SosStatus.CREATED);
            sos.setHospital(null);
            sos.setAssignedAt(null);
            sos.setDispatchedAt(null);
            sosEventRepository.save(sos);

            Notification userNotif = notificationRepository.save(Notification.builder()
                    .recipientType(RecipientType.USER)
                    .recipientId(sos.getUser().getId())
                    .title("No Hospital Available")
                    .body("All nearby hospitals are currently unable to respond. Please try again or call emergency services.")
                    .build());
            broadcastService.broadcastNotificationToUser(sos.getUser().getId(), userNotif);

            log.warn("SOS {} has no more hospitals available after escalation", sosId);
            SosEventDto dto = sosService.getById(sosId);
            broadcastService.broadcastSosStatusChange(sosId, dto);
            return dto;
        }

        // Assign to new hospital
        Instant now = Instant.now();
        sos.setHospital(nextHospital);
        sos.setAssignedAt(now);
        sos.setDispatchedAt(null);
        sos.setStatus(SosStatus.CREATED);
        sos = sosEventRepository.save(sos);

        // Record new hospital in history
        sosHospitalHistoryRepository.save(new SosHospitalHistory(sos, nextHospital));

        // Notify new hospital
        Notification hospitalNotif = notificationRepository.save(Notification.builder()
                .recipientType(RecipientType.HOSPITAL)
                .recipientId(nextHospital.getId())
                .title("New SOS Alert (Escalated)")
                .body("Patient: " + sos.getUser().getFullName() + " – " +
                        (sos.getCriticality() != null ? sos.getCriticality().name() : "UNKNOWN") + " severity")
                .build());
        broadcastService.broadcastNotificationToHospital(nextHospital.getId(), hospitalNotif);
        broadcastService.broadcastDashboardRefresh(nextHospital.getId());

        // Notify previous hospital that it was escalated
        if (previousHospital != null) {
            Notification prevNotif = notificationRepository.save(Notification.builder()
                    .recipientType(RecipientType.HOSPITAL)
                    .recipientId(previousHospital.getId())
                    .title("SOS Escalated")
                    .body("SOS #" + sosId + " has been escalated to " + nextHospital.getName())
                    .build());
            broadcastService.broadcastNotificationToHospital(previousHospital.getId(), prevNotif);
            broadcastService.broadcastDashboardRefresh(previousHospital.getId());
        }

        // Notify user
        Notification userNotif = notificationRepository.save(Notification.builder()
                .recipientType(RecipientType.USER)
                .recipientId(sos.getUser().getId())
                .title("Request Transferred")
                .body("Your request is being transferred to " + nextHospital.getName())
                .build());
        broadcastService.broadcastNotificationToUser(sos.getUser().getId(), userNotif);

        log.info("SOS {} escalated from {} to {} due to {}",
                sosId,
                previousHospital != null ? previousHospital.getName() : "none",
                nextHospital.getName(),
                reason);

        SosEventDto dto = sosService.getById(sosId);
        broadcastService.broadcastSosStatusChange(sosId, dto);
        return dto;
    }

    /**
     * Check if hospital has any available ambulances.
     */
    public boolean hasAvailableAmbulance(Long hospitalId) {
        return !ambulanceRepository.findByHospitalIdAndStatus(hospitalId, AmbulanceStatus.AVAILABLE).isEmpty();
    }

    private Hospital findNextNearestHospital(double lat, double lng, Set<Long> excludedIds) {
        return hospitalRepository.findAll().stream()
                .filter(h -> !excludedIds.contains(h.getId()))
                .min(Comparator.comparingDouble(h -> SosService.haversine(lat, lng,
                        h.getLatitude().doubleValue(), h.getLongitude().doubleValue())))
                .orElse(null);
    }

    private Ambulance findNearestAvailableAmbulance(Long hospitalId, double lat, double lng, Set<Long> excluded) {
        return ambulanceRepository.findByHospitalIdAndStatus(hospitalId, AmbulanceStatus.AVAILABLE).stream()
                .filter(a -> !excluded.contains(a.getId()))
                .filter(a -> a.getCurrentLatitude() != null && a.getCurrentLongitude() != null)
                .min(Comparator.comparingDouble(a -> SosService.haversine(lat, lng,
                        a.getCurrentLatitude().doubleValue(), a.getCurrentLongitude().doubleValue())))
                .orElse(null);
    }

    private Ambulance findNearestAvailableAmbulanceAcrossAll(double lat, double lng, Set<Long> excluded) {
        return ambulanceRepository.findAll().stream()
                .filter(a -> a.getStatus() == AmbulanceStatus.AVAILABLE)
                .filter(a -> !excluded.contains(a.getId()))
                .filter(a -> a.getCurrentLatitude() != null && a.getCurrentLongitude() != null)
                .min(Comparator.comparingDouble(a -> SosService.haversine(lat, lng,
                        a.getCurrentLatitude().doubleValue(), a.getCurrentLongitude().doubleValue())))
                .orElse(null);
    }

    private Hospital findNearestHospital(double lat, double lng) {
        return hospitalRepository.findAll().stream()
                .min(Comparator.comparingDouble(h -> SosService.haversine(lat, lng,
                        h.getLatitude().doubleValue(), h.getLongitude().doubleValue())))
                .orElse(null);
    }
}
