package com.iitm.hostel.dto;

import jakarta.validation.constraints.NotBlank;

public record UpdateComplaintStatusRequest(
        @NotBlank String status,
        String resolutionNotes,
        String resolvedBy
) {}
