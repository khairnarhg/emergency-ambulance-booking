package com.rakshapoorvak.service;

import com.rakshapoorvak.exception.BadRequestException;
import com.rakshapoorvak.exception.ForbiddenException;
import com.rakshapoorvak.exception.ResourceNotFoundException;
import com.rakshapoorvak.model.dto.sos.CreateSosRequest;
import com.rakshapoorvak.model.dto.sos.SosEventDto;
import com.rakshapoorvak.model.dto.sos.TrackingDto;
import com.rakshapoorvak.model.dto.sos.UpdateSosRequest;
import com.rakshapoorvak.model.dto.sos.UpdateStatusRequest;
import com.rakshapoorvak.model.dto.user.EmergencyContactDto;
import com.rakshapoorvak.model.entity.*;
import com.rakshapoorvak.model.entity.enums.*;
import com.rakshapoorvak.repository.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Comparator;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class SosService {

    private static final Logger log = LoggerFactory.getLogger(SosService.class);
    private static final double AVG_SPEED_KMH = 40.0;

    private final SosEventRepository sosEventRepository;
    private final UserRepository userRepository;
    private final HospitalRepository hospitalRepository;
    private final MedicalProfileRepository medicalProfileRepository;
    private final EmergencyContactRepository emergencyContactRepository;
    private final NotificationRepository notificationRepository;
    private final AmbulanceRepository ambulanceRepository;
    private final DriverRepository driverRepository;
    private final LocationUpdateRepository locationUpdateRepository;
    private final WebSocketBroadcastService broadcastService;

    public SosService(SosEventRepository sosEventRepository, UserRepository userRepository,
                      HospitalRepository hospitalRepository, MedicalProfileRepository medicalProfileRepository,
                      EmergencyContactRepository emergencyContactRepository,
                      NotificationRepository notificationRepository,
                      AmbulanceRepository ambulanceRepository, DriverRepository driverRepository,
                      LocationUpdateRepository locationUpdateRepository,
                      WebSocketBroadcastService broadcastService) {
        this.sosEventRepository = sosEventRepository;
        this.userRepository = userRepository;
        this.hospitalRepository = hospitalRepository;
        this.medicalProfileRepository = medicalProfileRepository;
        this.emergencyContactRepository = emergencyContactRepository;
        this.notificationRepository = notificationRepository;
        this.ambulanceRepository = ambulanceRepository;
        this.driverRepository = driverRepository;
        this.locationUpdateRepository = locationUpdateRepository;
        this.broadcastService = broadcastService;
    }

    @Transactional
    public SosEventDto create(String userEmail, CreateSosRequest request) {
        User user = userRepository.findByEmailWithRoles(userEmail)
                .orElseThrow(() -> new ResourceNotFoundException("User", "email", userEmail));

        Criticality criticality = parseCriticality(request.getCriticality());

        Hospital nearestHospital = findNearestHospital(
                request.getLatitude().doubleValue(), request.getLongitude().doubleValue());

        SosEvent sos = SosEvent.builder()
                .user(user)
                .latitude(request.getLatitude())
                .longitude(request.getLongitude())
                .address(request.getAddress())
                .status(SosStatus.CREATED)
                .symptoms(request.getSymptoms())
                .criticality(criticality)
                .hospital(nearestHospital)
                .build();

        sos = sosEventRepository.save(sos);
        log.info("SOS created: id={}, user={}, hospital={}", sos.getId(), user.getId(),
                nearestHospital != null ? nearestHospital.getName() : "none");

        if (nearestHospital != null) {
            Notification hospitalNotif = notificationRepository.save(Notification.builder()
                    .recipientType(RecipientType.HOSPITAL)
                    .recipientId(nearestHospital.getId())
                    .title("New SOS Alert!")
                    .body("Patient: " + user.getFullName() + " – " +
                            (criticality != null ? criticality.name() : "UNKNOWN") + " severity")
                    .build());
            broadcastService.broadcastNotificationToHospital(nearestHospital.getId(), hospitalNotif);
            broadcastService.broadcastDashboardRefresh(nearestHospital.getId());
        }

        SosEventDto dto = toDto(sos);
        broadcastService.broadcastSosStatusChange(sos.getId(), dto);
        return dto;
    }

    @Transactional
    public SosEventDto update(String userEmail, Long id, UpdateSosRequest request) {
        SosEvent sos = getSosAndCheckUser(id, userEmail);
        if (sos.getStatus() != SosStatus.CREATED && sos.getStatus() != SosStatus.DISPATCHING) {
            throw new BadRequestException("Cannot update SOS after dispatch");
        }

        if (request.getSymptoms() != null) sos.setSymptoms(request.getSymptoms());
        if (request.getCriticality() != null) {
            Criticality c = parseCriticality(request.getCriticality());
            if (c != null) sos.setCriticality(c);
        }

        sos = sosEventRepository.save(sos);
        return toDto(sos);
    }

    @Transactional(readOnly = true)
    public SosEventDto getById(Long id) {
        SosEvent sos = sosEventRepository.findByIdWithAssociations(id)
                .orElseThrow(() -> new ResourceNotFoundException("SOS event", id));
        return toDto(sos);
    }

    @Transactional(readOnly = true)
    public List<SosEventDto> getMy(String userEmail) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new ResourceNotFoundException("User", "email", userEmail));
        return sosEventRepository.findByUserIdOrderByCreatedAtDesc(user.getId()).stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<SosEventDto> getMyActive(String userEmail) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new ResourceNotFoundException("User", "email", userEmail));
        List<SosStatus> active = List.of(SosStatus.CREATED, SosStatus.DISPATCHING, SosStatus.AMBULANCE_ASSIGNED,
                SosStatus.DRIVER_ENROUTE_TO_PATIENT, SosStatus.REACHED_PATIENT, SosStatus.PICKED_UP,
                SosStatus.ENROUTE_TO_HOSPITAL, SosStatus.ARRIVED_AT_HOSPITAL);
        return sosEventRepository.findByUserIdAndStatusIn(user.getId(), active).stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<SosEventDto> getDriverHistory(String driverEmail) {
        Driver driver = getDriverByEmail(driverEmail);
        return sosEventRepository.findByDriverIdOrderByCreatedAtDesc(driver.getId()).stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<SosEventDto> getDriverActive(String driverEmail) {
        Driver driver = getDriverByEmail(driverEmail);
        List<SosStatus> active = List.of(SosStatus.AMBULANCE_ASSIGNED,
                SosStatus.DRIVER_ENROUTE_TO_PATIENT, SosStatus.REACHED_PATIENT,
                SosStatus.PICKED_UP, SosStatus.ENROUTE_TO_HOSPITAL, SosStatus.ARRIVED_AT_HOSPITAL);
        return sosEventRepository.findByDriverIdAndStatusIn(driver.getId(), active).stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public Page<SosEventDto> listForHospital(Long hospitalId, String status, int page, int size) {
        List<SosStatus> statuses = status != null && !status.isBlank()
                ? List.of(SosStatus.valueOf(status))
                : List.of(SosStatus.values());
        Pageable pageable = PageRequest.of(page, size);
        if (hospitalId != null) {
            var pageResult = sosEventRepository.findByHospitalIdAndStatusIn(hospitalId, statuses, pageable);
            return pageResult.map(this::toDto);
        }
        return sosEventRepository.findByStatusInPage(statuses, pageable).map(this::toDto);
    }

    @Transactional(readOnly = true)
    public List<SosEventDto> getActiveForHospital(Long hospitalId) {
        List<SosStatus> active = List.of(SosStatus.CREATED, SosStatus.DISPATCHING, SosStatus.AMBULANCE_ASSIGNED,
                SosStatus.DRIVER_ENROUTE_TO_PATIENT, SosStatus.REACHED_PATIENT, SosStatus.PICKED_UP,
                SosStatus.ENROUTE_TO_HOSPITAL, SosStatus.ARRIVED_AT_HOSPITAL);
        return sosEventRepository.findByHospitalIdAndStatusInOrderByCreatedAtDesc(hospitalId, active).stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    @Transactional
    public SosEventDto updateStatus(Long sosId, UpdateStatusRequest request, String driverEmail) {
        SosEvent sos = sosEventRepository.findByIdWithAssociations(sosId)
                .orElseThrow(() -> new ResourceNotFoundException("SOS event", sosId));

        if (sos.getDriver() == null) {
            throw new BadRequestException("No driver assigned to this SOS");
        }
        if (!sos.getDriver().getUser().getEmail().equals(driverEmail)) {
            throw new ForbiddenException("Only assigned driver can update status");
        }

        SosStatus newStatus = SosStatus.valueOf(request.getStatus());
        sos.setStatus(newStatus);
        if (newStatus == SosStatus.COMPLETED) {
            sos.setCompletedAt(Instant.now());
        }
        sos = sosEventRepository.save(sos);
        log.info("SOS {} status updated to {}", sosId, newStatus);

        createStatusNotifications(sos, newStatus);

        SosEventDto dto = toDto(sos);
        broadcastService.broadcastSosStatusChange(sosId, dto);
        if (sos.getHospital() != null) {
            broadcastService.broadcastDashboardRefresh(sos.getHospital().getId());
        }
        return dto;
    }

    @Transactional
    public SosEventDto complete(Long sosId, String driverEmail) {
        SosEvent sos = sosEventRepository.findByIdWithAssociations(sosId)
                .orElseThrow(() -> new ResourceNotFoundException("SOS event", sosId));

        if (sos.getDriver() == null) {
            throw new BadRequestException("No driver assigned to this SOS");
        }
        if (!sos.getDriver().getUser().getEmail().equals(driverEmail)) {
            throw new ForbiddenException("Only assigned driver can complete this SOS");
        }

        sos.setStatus(SosStatus.COMPLETED);
        sos.setCompletedAt(Instant.now());

        Ambulance ambulance = sos.getAmbulance();
        if (ambulance != null) {
            ambulance.setStatus(AmbulanceStatus.AVAILABLE);
            ambulanceRepository.save(ambulance);
        }

        Driver driver = sos.getDriver();
        driver.setStatus(DriverStatus.AVAILABLE);
        driverRepository.save(driver);

        sos = sosEventRepository.save(sos);
        log.info("SOS {} completed, ambulance and driver released", sosId);

        Notification userNotif = notificationRepository.save(Notification.builder()
                .recipientType(RecipientType.USER)
                .recipientId(sos.getUser().getId())
                .title("Case Completed")
                .body("Your emergency case #" + sosId + " has been completed. Stay safe!")
                .build());
        broadcastService.broadcastNotificationToUser(sos.getUser().getId(), userNotif);

        if (sos.getHospital() != null) {
            String ambReg = ambulance != null ? ambulance.getRegistrationNumber() : "N/A";
            Notification hospNotif = notificationRepository.save(Notification.builder()
                    .recipientType(RecipientType.HOSPITAL)
                    .recipientId(sos.getHospital().getId())
                    .title("SOS Completed")
                    .body("SOS #" + sosId + " completed. Ambulance " + ambReg + " is now available.")
                    .build());
            broadcastService.broadcastNotificationToHospital(sos.getHospital().getId(), hospNotif);
            broadcastService.broadcastDashboardRefresh(sos.getHospital().getId());
        }

        SosEventDto dto = toDto(sos);
        broadcastService.broadcastSosStatusChange(sosId, dto);
        return dto;
    }

    @Transactional
    public void cancel(Long sosId, String userEmail) {
        SosEvent sos = getSosAndCheckUser(sosId, userEmail);
        if (sos.getStatus() != SosStatus.CREATED && sos.getStatus() != SosStatus.DISPATCHING) {
            throw new BadRequestException("Cannot cancel SOS after ambulance is assigned");
        }
        sos.setStatus(SosStatus.CANCELLED);
        sosEventRepository.save(sos);
        log.info("SOS {} cancelled by user", sosId);
    }

    @Transactional(readOnly = true)
    public TrackingDto getTracking(Long sosId) {
        SosEvent sos = sosEventRepository.findByIdWithAssociations(sosId)
                .orElseThrow(() -> new ResourceNotFoundException("SOS event", sosId));

        TrackingDto.TrackingDtoBuilder builder = TrackingDto.builder()
                .sosEventId(sos.getId())
                .status(sos.getStatus().name());

        if (sos.getAmbulance() != null) {
            builder.ambulanceLatitude(sos.getAmbulance().getCurrentLatitude())
                    .ambulanceLongitude(sos.getAmbulance().getCurrentLongitude())
                    .ambulanceRegistrationNumber(sos.getAmbulance().getRegistrationNumber());
            if (sos.getDriver() != null) {
                builder.driverName(sos.getDriver().getUser().getFullName())
                        .driverPhone(sos.getDriver().getUser().getPhone());
            }

            Integer eta = calculateEta(sos);
            builder.estimatedMinutesArrival(eta);
        }

        if (sos.getHospital() != null) {
            builder.hospitalName(sos.getHospital().getName())
                    .hospitalAddress(sos.getHospital().getAddress());
        }

        List<TrackingDto.LocationPointDto> history = locationUpdateRepository
                .findBySosEventIdOrderByRecordedAtDesc(sosId).stream()
                .map(lu -> TrackingDto.LocationPointDto.builder()
                        .latitude(lu.getLatitude())
                        .longitude(lu.getLongitude())
                        .recordedAt(lu.getRecordedAt() != null ? lu.getRecordedAt().toString() : null)
                        .build())
                .collect(Collectors.toList());
        builder.locationHistory(history);

        return builder.build();
    }

    private void createStatusNotifications(SosEvent sos, SosStatus newStatus) {
        String driverName = sos.getDriver() != null ? sos.getDriver().getUser().getFullName() : "Driver";
        String ambReg = sos.getAmbulance() != null ? sos.getAmbulance().getRegistrationNumber() : "N/A";
        String hospitalName = sos.getHospital() != null ? sos.getHospital().getName() : "Hospital";
        Long userId = sos.getUser().getId();
        Long hospitalId = sos.getHospital() != null ? sos.getHospital().getId() : null;

        switch (newStatus) {
            case DRIVER_ENROUTE_TO_PATIENT -> {
                Notification un = notificationRepository.save(Notification.builder()
                        .recipientType(RecipientType.USER).recipientId(userId)
                        .title("Ambulance On The Way!")
                        .body("Your MGM ambulance is en route.")
                        .build());
                broadcastService.broadcastNotificationToUser(userId, un);
                if (hospitalId != null) {
                    Notification hn = notificationRepository.save(Notification.builder()
                            .recipientType(RecipientType.HOSPITAL).recipientId(hospitalId)
                            .title("Driver En Route")
                            .body("Driver " + driverName + " is heading to patient for SOS #" + sos.getId())
                            .build());
                    broadcastService.broadcastNotificationToHospital(hospitalId, hn);
                }
            }
            case REACHED_PATIENT -> {
                Notification un = notificationRepository.save(Notification.builder()
                        .recipientType(RecipientType.USER).recipientId(userId)
                        .title("Ambulance Arrived")
                        .body("The ambulance has reached your location")
                        .build());
                broadcastService.broadcastNotificationToUser(userId, un);
                if (hospitalId != null) {
                    Notification hn = notificationRepository.save(Notification.builder()
                            .recipientType(RecipientType.HOSPITAL).recipientId(hospitalId)
                            .title("Patient Reached")
                            .body("Driver reached patient for SOS #" + sos.getId())
                            .build());
                    broadcastService.broadcastNotificationToHospital(hospitalId, hn);
                }
            }
            case PICKED_UP -> {
                if (hospitalId != null) {
                    Notification hn = notificationRepository.save(Notification.builder()
                            .recipientType(RecipientType.HOSPITAL).recipientId(hospitalId)
                            .title("Patient Picked Up")
                            .body("Patient picked up, heading to " + hospitalName)
                            .build());
                    broadcastService.broadcastNotificationToHospital(hospitalId, hn);
                }
            }
            case ENROUTE_TO_HOSPITAL -> {
                if (hospitalId != null) {
                    Notification hn = notificationRepository.save(Notification.builder()
                            .recipientType(RecipientType.HOSPITAL).recipientId(hospitalId)
                            .title("En Route to Hospital")
                            .body("Ambulance " + ambReg + " heading to " + hospitalName + ". Prepare for arrival.")
                            .build());
                    broadcastService.broadcastNotificationToHospital(hospitalId, hn);
                }
            }
            case ARRIVED_AT_HOSPITAL -> {
                Notification un = notificationRepository.save(Notification.builder()
                        .recipientType(RecipientType.USER).recipientId(userId)
                        .title("Arrived at Hospital")
                        .body("You have arrived at " + hospitalName)
                        .build());
                broadcastService.broadcastNotificationToUser(userId, un);
                if (hospitalId != null) {
                    Notification hn = notificationRepository.save(Notification.builder()
                            .recipientType(RecipientType.HOSPITAL).recipientId(hospitalId)
                            .title("Ambulance Arrived")
                            .body("Ambulance " + ambReg + " arrived at hospital with patient")
                            .build());
                    broadcastService.broadcastNotificationToHospital(hospitalId, hn);
                }
            }
            default -> { }
        }
    }

    private Integer calculateEta(SosEvent sos) {
        if (sos.getAmbulance() == null) return null;
        BigDecimal ambLat = sos.getAmbulance().getCurrentLatitude();
        BigDecimal ambLng = sos.getAmbulance().getCurrentLongitude();
        if (ambLat == null || ambLng == null) return null;

        double destLat, destLng;
        SosStatus status = sos.getStatus();
        if (status == SosStatus.ENROUTE_TO_HOSPITAL || status == SosStatus.PICKED_UP) {
            if (sos.getHospital() == null) return null;
            destLat = sos.getHospital().getLatitude().doubleValue();
            destLng = sos.getHospital().getLongitude().doubleValue();
        } else {
            destLat = sos.getLatitude().doubleValue();
            destLng = sos.getLongitude().doubleValue();
        }

        double distKm = haversine(ambLat.doubleValue(), ambLng.doubleValue(), destLat, destLng);
        int minutes = (int) Math.ceil((distKm / AVG_SPEED_KMH) * 60);
        return Math.max(1, minutes);
    }

    private Hospital findNearestHospital(double lat, double lng) {
        List<Hospital> hospitals = hospitalRepository.findAll();
        if (hospitals.isEmpty()) return null;
        return hospitals.stream()
                .min(Comparator.comparingDouble(h -> haversine(lat, lng,
                        h.getLatitude().doubleValue(), h.getLongitude().doubleValue())))
                .orElse(null);
    }

    private Driver getDriverByEmail(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("User", "email", email));
        return driverRepository.findByUserId(user.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Driver", "email", email));
    }

    private SosEvent getSosAndCheckUser(Long sosId, String userEmail) {
        SosEvent sos = sosEventRepository.findByIdWithAssociations(sosId)
                .orElseThrow(() -> new ResourceNotFoundException("SOS event", sosId));
        if (!sos.getUser().getEmail().equals(userEmail)) {
            throw new ForbiddenException("Not authorized to modify this SOS");
        }
        return sos;
    }

    private Criticality parseCriticality(String s) {
        if (s == null || s.isBlank()) return null;
        try {
            return Criticality.valueOf(s.toUpperCase());
        } catch (IllegalArgumentException e) {
            return null;
        }
    }

    public SosEventDto toDto(SosEvent sos) {
        SosEventDto.SosEventDtoBuilder builder = SosEventDto.builder()
                .id(sos.getId())
                .userId(sos.getUser() != null ? sos.getUser().getId() : null)
                .userName(sos.getUser() != null ? sos.getUser().getFullName() : null)
                .userPhone(sos.getUser() != null ? sos.getUser().getPhone() : null)
                .hospitalId(sos.getHospital() != null ? sos.getHospital().getId() : null)
                .hospitalName(sos.getHospital() != null ? sos.getHospital().getName() : null)
                .hospitalAddress(sos.getHospital() != null ? sos.getHospital().getAddress() : null)
                .hospitalLatitude(sos.getHospital() != null ? sos.getHospital().getLatitude() : null)
                .hospitalLongitude(sos.getHospital() != null ? sos.getHospital().getLongitude() : null)
                .ambulanceId(sos.getAmbulance() != null ? sos.getAmbulance().getId() : null)
                .ambulanceRegistrationNumber(sos.getAmbulance() != null ? sos.getAmbulance().getRegistrationNumber() : null)
                .driverId(sos.getDriver() != null ? sos.getDriver().getId() : null)
                .driverName(sos.getDriver() != null ? sos.getDriver().getUser().getFullName() : null)
                .doctorId(sos.getDoctor() != null ? sos.getDoctor().getId() : null)
                .doctorName(sos.getDoctor() != null ? sos.getDoctor().getUser().getFullName() : null)
                .latitude(sos.getLatitude())
                .longitude(sos.getLongitude())
                .address(sos.getAddress())
                .status(sos.getStatus().name())
                .symptoms(sos.getSymptoms())
                .criticality(sos.getCriticality() != null ? sos.getCriticality().name() : null)
                .completedAt(sos.getCompletedAt())
                .createdAt(sos.getCreatedAt())
                .updatedAt(sos.getUpdatedAt());

        if (sos.getUser() != null) {
            medicalProfileRepository.findByUserId(sos.getUser().getId()).ifPresent(mp -> {
                builder.bloodGroup(mp.getBloodGroup());
                builder.allergies(mp.getAllergies());
                builder.medicalConditions(mp.getConditions());
            });

            List<EmergencyContactDto> contacts = emergencyContactRepository
                    .findByUser_IdOrderByCreatedAtDesc(sos.getUser().getId()).stream()
                    .map(ec -> EmergencyContactDto.builder()
                            .id(ec.getId())
                            .userId(ec.getUser().getId())
                            .name(ec.getName())
                            .phone(ec.getPhone())
                            .relationship(ec.getRelationship())
                            .build())
                    .collect(Collectors.toList());
            if (!contacts.isEmpty()) {
                builder.emergencyContacts(contacts);
            }
        }

        return builder.build();
    }

    static double haversine(double lat1, double lon1, double lat2, double lon2) {
        double R = 6371;
        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
                Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2)) *
                        Math.sin(dLon / 2) * Math.sin(dLon / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return R * c;
    }
}
