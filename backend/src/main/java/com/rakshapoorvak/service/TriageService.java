package com.rakshapoorvak.service;

import com.rakshapoorvak.exception.ForbiddenException;
import com.rakshapoorvak.exception.ResourceNotFoundException;
import com.rakshapoorvak.model.dto.triage.*;
import com.rakshapoorvak.model.entity.Medication;
import com.rakshapoorvak.model.entity.SosEvent;
import com.rakshapoorvak.model.entity.TriageRecord;
import com.rakshapoorvak.repository.MedicationRepository;
import com.rakshapoorvak.repository.SosEventRepository;
import com.rakshapoorvak.repository.TriageRecordRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Triage records and medications for SOS events.
 */
@Service
public class TriageService {

    private static final Logger log = LoggerFactory.getLogger(TriageService.class);

    private final TriageRecordRepository triageRecordRepository;
    private final MedicationRepository medicationRepository;
    private final SosEventRepository sosEventRepository;

    public TriageService(TriageRecordRepository triageRecordRepository, MedicationRepository medicationRepository,
                         SosEventRepository sosEventRepository) {
        this.triageRecordRepository = triageRecordRepository;
        this.medicationRepository = medicationRepository;
        this.sosEventRepository = sosEventRepository;
    }

    @Transactional
    public TriageRecordDto addTriageRecord(CreateTriageRecordRequest request) {
        SosEvent sos = sosEventRepository.findById(request.getSosEventId())
                .orElseThrow(() -> new ResourceNotFoundException("SOS event", request.getSosEventId()));
        TriageRecord tr = TriageRecord.builder()
                .sosEvent(sos)
                .heartRate(request.getHeartRate())
                .systolicBp(request.getSystolicBp())
                .diastolicBp(request.getDiastolicBp())
                .spo2(request.getSpo2())
                .temperature(request.getTemperature())
                .notes(request.getNotes())
                .recordedAt(Instant.now())
                .build();
        tr = triageRecordRepository.save(tr);
        log.info("Triage record added for SOS {}", sos.getId());
        return toTriageDto(tr);
    }

    @Transactional(readOnly = true)
    public List<TriageRecordDto> listTriageRecords(Long sosEventId) {
        return triageRecordRepository.findBySosEventIdOrderByRecordedAtDesc(sosEventId).stream()
                .map(this::toTriageDto)
                .collect(Collectors.toList());
    }

    @Transactional
    public MedicationDto addMedication(CreateMedicationRequest request) {
        SosEvent sos = sosEventRepository.findById(request.getSosEventId())
                .orElseThrow(() -> new ResourceNotFoundException("SOS event", request.getSosEventId()));
        Medication m = Medication.builder()
                .sosEvent(sos)
                .name(request.getName())
                .dosage(request.getDosage())
                .notes(request.getNotes())
                .administeredAt(Instant.now())
                .build();
        m = medicationRepository.save(m);
        log.info("Medication added for SOS {}", sos.getId());
        return toMedicationDto(m);
    }

    @Transactional(readOnly = true)
    public List<MedicationDto> listMedications(Long sosEventId) {
        return medicationRepository.findBySosEventIdOrderByAdministeredAtDesc(sosEventId).stream()
                .map(this::toMedicationDto)
                .collect(Collectors.toList());
    }

    private TriageRecordDto toTriageDto(TriageRecord tr) {
        return TriageRecordDto.builder()
                .id(tr.getId())
                .sosEventId(tr.getSosEvent().getId())
                .heartRate(tr.getHeartRate())
                .systolicBp(tr.getSystolicBp())
                .diastolicBp(tr.getDiastolicBp())
                .spo2(tr.getSpo2())
                .temperature(tr.getTemperature())
                .notes(tr.getNotes())
                .recordedAt(tr.getRecordedAt())
                .createdAt(tr.getCreatedAt())
                .build();
    }

    private MedicationDto toMedicationDto(Medication m) {
        return MedicationDto.builder()
                .id(m.getId())
                .sosEventId(m.getSosEvent().getId())
                .name(m.getName())
                .dosage(m.getDosage())
                .notes(m.getNotes())
                .administeredAt(m.getAdministeredAt())
                .build();
    }
}
