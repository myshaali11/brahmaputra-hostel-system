package com.iitm.hostel.dto;

import jakarta.validation.constraints.NotBlank;

public record RoutineTaskLogRequest(
        @NotBlank String taskName,
        boolean completed,
        String comment,
        String loggedBy
) {}
