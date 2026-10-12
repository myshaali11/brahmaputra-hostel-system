package com.iitm.hostel.dto;

public record DashboardSummaryDto(
        Long hostelId,
        String hostelName,
        int totalComplaints,
        int openComplaints,
        int inProgressComplaints,
        int resolvedComplaints,
        int totalAssets,
        int assetsWithIssues,
        double inspectionRate
) {}
