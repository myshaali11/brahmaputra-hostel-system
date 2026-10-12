package com.iitm.hostel.dto;

public record FloorDto(
        Long id,
        Long hostelId,
        int floorNumber,
        int roomCount,
        int restroomCount,
        int commonAreaCount,
        int activeComplaints
) {}
