package com.rakshapoorvak.model.dto.user;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class EmergencyContactDto {

    private Long id;
    private Long userId;
    private String name;
    private String phone;
    private String relationship;
}
