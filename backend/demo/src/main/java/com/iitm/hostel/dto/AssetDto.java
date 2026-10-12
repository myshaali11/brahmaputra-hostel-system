package com.iitm.hostel.dto;

public record AssetDto(
        Long id,
        Long locationId,
        String name,
        String status,
        String comment,
        String lastCheckedAt
) {}
