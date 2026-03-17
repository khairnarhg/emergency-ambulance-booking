package com.rakshapoorvak.model.dto.patient;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PatientSearchResultDto {

    private Long userId;
    private String fullName;
    private String phone;
    private String email;
    private Instant lastSosDate;
}
