package com.iitm.hostel.dto;

import jakarta.validation.constraints.NotNull;

public record CreateComplaintRequest(
        @NotNull Long locationId,
        Long assetId,
        String title,
        String description,
        String priority,
        String reportedBy
) {}
