package com.rakshapoorvak.model.dto.sos;

import com.rakshapoorvak.model.dto.user.EmergencyContactDto;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SosEventDto {

    private Long id;
    private Long userId;
    private String userName;
    private String userPhone;
    private Long hospitalId;
    private String hospitalName;
    private String hospitalAddress;
    private BigDecimal hospitalLatitude;
    private BigDecimal hospitalLongitude;
    private Long ambulanceId;
    private String ambulanceRegistrationNumber;
    private Long driverId;
    private String driverName;
    private Long doctorId;
    private String doctorName;
    private BigDecimal latitude;
    private BigDecimal longitude;
    private String address;
    private String status;
    private String symptoms;
    private String criticality;
    private String bloodGroup;
    private String allergies;
    private String medicalConditions;
    private List<EmergencyContactDto> emergencyContacts;
    private Instant completedAt;
    private Instant createdAt;
    private Instant updatedAt;
}
