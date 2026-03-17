package com.rakshapoorvak.model.dto.patient;

import com.rakshapoorvak.model.dto.sos.SosEventDto;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PatientHistoryDto {

    private Long userId;
    private String fullName;
    private List<SosEventDto> sosEvents;
}
