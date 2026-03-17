package com.rakshapoorvak.model.dto.ambulance;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UpdateAmbulanceStatusRequest {

    @NotBlank(message = "Status is required")
    private String status;
}
