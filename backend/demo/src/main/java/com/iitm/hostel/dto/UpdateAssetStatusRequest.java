package com.iitm.hostel.dto;

import jakarta.validation.constraints.NotBlank;

public record UpdateAssetStatusRequest(
        @NotBlank String status,
        String comment
) {}
