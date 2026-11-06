package com.iitm.hostel.dto;

import jakarta.validation.constraints.NotBlank;

public record UpdateComplaintStatusRequest(
        @NotBlank String status,
        String resolutionNotes,
        String resolvedBy,
        String disputeResolutionNotes
) {
    public UpdateComplaintStatusRequest(String status, String resolutionNotes, String resolvedBy) {
        this(status, resolutionNotes, resolvedBy, null);
    }
}
