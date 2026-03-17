package com.rakshapoorvak.model.dto.driver;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DriverDto {

    private Long id;
    private Long userId;
    private String fullName;
    private String email;
    private String phone;
    private String licenseNumber;
    private Long hospitalId;
    private String hospitalName;
    private String status;
}
