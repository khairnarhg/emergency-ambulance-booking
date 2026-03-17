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
    private final SosService sosService;

    public DispatchService(SosEventRepository sosEventRepository, AmbulanceRepository ambulanceRepository,
                           DriverRepository driverRepository, DoctorRepository doctorRepository,
                           HospitalStaffRepository hospitalStaffRepository, HospitalRepository hospitalRepository,
                           UserRepository userRepository, NotificationRepository notificationRepository,
                           SosService sosService) {
        this.sosEventRepository = sosEventRepository;
        this.ambulanceRepository = ambulanceRepository;
        this.driverRepository = driverRepository;
        this.doctorRepository = doctorRepository;
        this.hospitalStaffRepository = hospitalStaffRepository;
        this.hospitalRepository = hospitalRepository;
        this.userRepository = userRepository;
        this.notificationRepository = notificationRepository;
        this.sosService = sosService;
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

        List<Driver> drivers = driverRepository.findByHospitalIdAndStatus(
                selectedAmbulance.getHospital().getId(), DriverStatus.AVAILABLE);
        Driver driver = drivers.isEmpty() ? null : drivers.get(0);

        if (driver == null) {
            List<Driver> allDrivers = driverRepository.findAll().stream()
                    .filter(d -> d.getStatus() == DriverStatus.AVAILABLE)
                    .sorted(Comparator.comparingDouble(d -> {
                        if (d.getHospital() == null) return Double.MAX_VALUE;
                        return SosService.haversine(patientLat, patientLon,
                                d.getHospital().getLatitude().doubleValue(),
                                d.getHospital().getLongitude().doubleValue());
                    }))
                    .collect(Collectors.toList());
            driver = allDrivers.isEmpty() ? null : allDrivers.get(0);
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
        sos.setStatus(SosStatus.AMBULANCE_ASSIGNED);
        selectedAmbulance.setStatus(AmbulanceStatus.DISPATCHED);
        driver.setStatus(DriverStatus.BUSY);
        ambulanceRepository.save(selectedAmbulance);
        driverRepository.save(driver);
        sos = sosEventRepository.save(sos);

        notificationRepository.save(Notification.builder()
                .recipientType(RecipientType.DRIVER)
                .recipientId(driver.getId())
                .title("New Emergency Dispatch")
                .body("Patient: " + sos.getUser().getFullName() + " – " +
                        (sos.getCriticality() != null ? sos.getCriticality().name() : "UNKNOWN"))
                .build());

        notificationRepository.save(Notification.builder()
                .recipientType(RecipientType.USER)
                .recipientId(sos.getUser().getId())
                .title("Ambulance Assigned!")
                .body("An MGM ambulance is on the way. Driver: " + driver.getUser().getFullName())
                .build());

        if (sos.getHospital() != null) {
            notificationRepository.save(Notification.builder()
                    .recipientType(RecipientType.HOSPITAL)
                    .recipientId(sos.getHospital().getId())
                    .title("Ambulance Dispatched")
                    .body("Ambulance " + selectedAmbulance.getRegistrationNumber() +
                            " dispatched for SOS #" + sosId)
                    .build());
        }

        log.info("Ambulance {} assigned to SOS {} (driver: {})", selectedAmbulance.getId(), sosId, driver.getId());
        return sosService.getById(sosId);
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

        if (sos.getStatus() != SosStatus.AMBULANCE_ASSIGNED) {
            throw new BadRequestException("SOS is not in dispatch state");
        }

        sos.setStatus(SosStatus.DRIVER_ENROUTE_TO_PATIENT);
        sos = sosEventRepository.save(sos);
        log.info("Driver {} accepted SOS {}", driver.getId(), sosId);
        return sosService.getById(sosId);
    }

    @Transactional(readOnly = true)
    public List<SosEventDto> getPendingRequests(String driverEmail) {
        Driver driver = driverRepository.findByUserId(
                userRepository.findByEmail(driverEmail).orElseThrow(
                        () -> new ResourceNotFoundException("Driver", "email", driverEmail)).getId())
                .orElseThrow(() -> new ResourceNotFoundException("Driver", "email", driverEmail));
        return sosEventRepository.findByDriverIdAndStatusIn(driver.getId(),
                List.of(SosStatus.AMBULANCE_ASSIGNED)).stream()
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
