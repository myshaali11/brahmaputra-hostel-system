package com.iitm.hostel.dto;

import jakarta.validation.constraints.NotBlank;

public record CreateDisputeRequest(
        @NotBlank String reason,
        String studentName
) {}
