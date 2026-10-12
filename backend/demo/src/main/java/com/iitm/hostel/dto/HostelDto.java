package com.iitm.hostel.dto;

public record HostelDto(
        Long id,
        String name,
        String description,
        int displayOrder,
        int activeComplaints,
        int floorCount
) {}
