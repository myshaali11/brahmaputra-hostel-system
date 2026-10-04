package com.iitm.hostel.dto;

/** One row of today's routine checklist for a location (e.g. "Mopping" -> not yet done). */
public record RoutineTaskDto(
        String taskName,
        boolean completed,
        String comment,
        String loggedBy,
        String loggedAt
) {}
