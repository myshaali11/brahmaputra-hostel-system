package com.iitm.hostel.dto;

public record ComplaintDto(
        Long id,
        String ivrsNumber,
        Long locationId,
        String locationName,
        String locationType,
        Long floorId,
        int floorNumber,
        Long hostelId,
        String hostelName,
        Long assetId,
        String assetName,
        String title,
        String description,
        String status,
        String priority,
        String reportedBy,
        String createdAt,
        String resolvedAt,
        String resolvedBy,
        String resolutionNotes
) {}
