package com.iitm.hostel.dto;

public record LocationDto(
        Long id,
        Long floorId,
        String name,
        String type,
        String status,
        int activeComplaintCount,
        String lastInspectedAt,
        String lastInspectedBy
) {}
