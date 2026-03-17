package com.rakshapoorvak.model.dto.sos;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UpdateSosRequest {

    private String symptoms;
    private String criticality; // LOW, MEDIUM, HIGH, CRITICAL
}
