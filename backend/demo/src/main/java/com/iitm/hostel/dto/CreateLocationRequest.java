package com.iitm.hostel.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

/**
 * Payload for adding a new location to a floor. The backend auto-provisions
 * its default assets and routine tasks from the AssetTemplate /
 * RoutineTaskTemplate tables that match the given type, so a new Room shows
 * up with a Cot, Chair, Fan, Study Table, Cupboard and Ethernet Point
 * already in place, with no manual data entry needed.
 */
public record CreateLocationRequest(
        @NotBlank String name,
        @NotNull String type
) {}
