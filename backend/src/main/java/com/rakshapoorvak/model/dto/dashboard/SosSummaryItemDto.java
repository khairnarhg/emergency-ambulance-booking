package com.rakshapoorvak.model.dto.dashboard;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SosSummaryItemDto {

    private Long id;
    private String userName;
    private String status;
    private String criticality;
    private String address;
    private Instant createdAt;
}
