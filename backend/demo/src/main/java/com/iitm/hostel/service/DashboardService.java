package com.iitm.hostel.service;

import com.iitm.hostel.dto.DashboardSummaryDto;
import com.iitm.hostel.enums.AssetStatus;
import com.iitm.hostel.enums.ComplaintStatus;
import com.iitm.hostel.exception.ResourceNotFoundException;
import com.iitm.hostel.model.Complaint;
import com.iitm.hostel.model.Hostel;
import com.iitm.hostel.repository.AssetRepository;
import com.iitm.hostel.repository.ComplaintRepository;
import com.iitm.hostel.repository.HostelRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class DashboardService {

    private final HostelRepository hostelRepository;
    private final ComplaintRepository complaintRepository;
    private final AssetRepository assetRepository;

    public DashboardService(HostelRepository hostelRepository, ComplaintRepository complaintRepository, AssetRepository assetRepository) {
        this.hostelRepository = hostelRepository;
        this.complaintRepository = complaintRepository;
        this.assetRepository = assetRepository;
    }

    public DashboardSummaryDto getSummary(Long hostelId) {
        Hostel hostel = hostelRepository.findById(hostelId)
                .orElseThrow(() -> new ResourceNotFoundException("Hostel " + hostelId + " not found"));

        List<Complaint> allComplaints = complaintRepository.findByLocationFloorHostelIdOrderByCreatedAtDesc(hostelId);
        long total = allComplaints.size();
        long open = complaintRepository.countByLocationFloorHostelIdAndStatus(hostelId, ComplaintStatus.OPEN);
        long inProgress = complaintRepository.countByLocationFloorHostelIdAndStatus(hostelId, ComplaintStatus.IN_PROGRESS);
        long resolved = complaintRepository.countByLocationFloorHostelIdAndStatus(hostelId, ComplaintStatus.RESOLVED);
        long disputed = complaintRepository.countByLocationFloorHostelIdAndStatus(hostelId, ComplaintStatus.DISPUTED);
        long hazards = allComplaints.stream().filter(c -> Boolean.TRUE.equals(c.getIsHazard())).count();

        long totalAssets = assetRepository.countByLocationFloorHostelId(hostelId);
        long assetsWithIssues = assetRepository.countByLocationFloorHostelIdAndStatus(hostelId, AssetStatus.COMPLAINT_RAISED);

        double inspectionRate = totalAssets == 0 ? 0 : (double) (totalAssets - assetsWithIssues) / totalAssets * 100;

        return new DashboardSummaryDto(
                hostel.getId(),
                hostel.getName(),
                (int) total,
                (int) open,
                (int) inProgress,
                (int) resolved,
                (int) totalAssets,
                (int) assetsWithIssues,
                Math.max(0, inspectionRate),
                (int) disputed,
                (int) hazards
        );
    }
}
