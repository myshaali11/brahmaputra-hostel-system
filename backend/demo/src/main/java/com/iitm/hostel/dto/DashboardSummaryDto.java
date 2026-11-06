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
        double inspectionRate,
        int disputedComplaints,
        int hazardComplaints
) {
    public DashboardSummaryDto(
            Long hostelId,
            String hostelName,
            int totalComplaints,
            int openComplaints,
            int inProgressComplaints,
            int resolvedComplaints,
            int totalAssets,
            int assetsWithIssues,
            double inspectionRate
    ) {
        this(hostelId, hostelName, totalComplaints, openComplaints, inProgressComplaints, resolvedComplaints, totalAssets, assetsWithIssues, inspectionRate, 0, 0);
    }
}
