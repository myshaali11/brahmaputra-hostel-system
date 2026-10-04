package com.iitm.hostel.service;

import com.iitm.hostel.dto.ComplaintDto;
import com.iitm.hostel.dto.CreateComplaintRequest;
import com.iitm.hostel.dto.UpdateComplaintStatusRequest;
import com.iitm.hostel.enums.AssetStatus;
import com.iitm.hostel.enums.ComplaintStatus;
import com.iitm.hostel.enums.Priority;
import com.iitm.hostel.exception.InvalidRequestException;
import com.iitm.hostel.exception.ResourceNotFoundException;
import com.iitm.hostel.model.Asset;
import com.iitm.hostel.model.Complaint;
import com.iitm.hostel.model.Location;
import com.iitm.hostel.repository.AssetRepository;
import com.iitm.hostel.repository.ComplaintRepository;
import com.iitm.hostel.repository.LocationRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;

/**
 * Owns the complaint lifecycle AND the two-way link with asset state:
 * raising a complaint against an asset pushes that asset to
 * COMPLAINT_RAISED, and resolving the complaint reverts it back to WORKING.
 * This is what keeps the "primary dashboard" complaint feed and the
 * per-location checklist toggle state consistent with each other.
 */
@Service
public class ComplaintService {

    private static final DateTimeFormatter TS = DateTimeFormatter.ISO_LOCAL_DATE_TIME;

    private final ComplaintRepository complaintRepository;
    private final LocationRepository locationRepository;
    private final AssetRepository assetRepository;

    public ComplaintService(ComplaintRepository complaintRepository, LocationRepository locationRepository, AssetRepository assetRepository) {
        this.complaintRepository = complaintRepository;
        this.locationRepository = locationRepository;
        this.assetRepository = assetRepository;
    }

    public List<ComplaintDto> getComplaints(Long hostelId, Long floorId, Long locationId, Boolean activeOnly) {
        List<Complaint> complaints;
        if (locationId != null) {
            complaints = complaintRepository.findByLocationIdOrderByCreatedAtDesc(locationId);
        } else if (floorId != null) {
            complaints = complaintRepository.findByLocationFloorIdOrderByCreatedAtDesc(floorId);
        } else if (hostelId != null) {
            complaints = complaintRepository.findByLocationFloorHostelIdOrderByCreatedAtDesc(hostelId);
        } else if (Boolean.TRUE.equals(activeOnly)) {
            complaints = complaintRepository.findByStatusInOrderByCreatedAtDesc(List.of(ComplaintStatus.OPEN, ComplaintStatus.IN_PROGRESS));
        } else {
            complaints = complaintRepository.findAllByOrderByCreatedAtDesc();
        }
        return complaints.stream().map(this::toDto).toList();
    }

    @Transactional
    public ComplaintDto createComplaint(CreateComplaintRequest request) {
        Location location = locationRepository.findById(request.locationId())
                .orElseThrow(() -> new ResourceNotFoundException("Location " + request.locationId() + " not found"));

        Priority priority;
        try {
            priority = request.priority() == null || request.priority().isBlank()
                    ? Priority.MEDIUM
                    : Priority.valueOf(request.priority().toUpperCase());
        } catch (IllegalArgumentException ex) {
            throw new InvalidRequestException("Unknown priority: " + request.priority());
        }

        Complaint complaint = new Complaint();
        complaint.setLocation(location);
        complaint.setTitle(request.title() == null || request.title().isBlank() ? "Asset issue" : request.title());
        complaint.setDescription(request.description() == null || request.description().isBlank()
                ? "No description supplied" : request.description());
        complaint.setPriority(priority);
        complaint.setStatus(ComplaintStatus.OPEN);
        complaint.setReportedBy(request.reportedBy());
        complaint.setIvrsNumber(generateIvrsNumber());

        if (request.assetId() != null) {
            Asset asset = assetRepository.findById(request.assetId())
                    .filter(item -> item.getLocation().getId().equals(request.locationId()))
                    .orElseThrow(() -> new ResourceNotFoundException("Asset " + request.assetId() + " not found in this location"));
            complaint.setAsset(asset);
            // Flipping the checklist toggle off is what raises the complaint, so keep the asset state in sync.
            asset.setStatus(AssetStatus.COMPLAINT_RAISED);
            asset.setComment(complaint.getDescription());
            asset.setLastCheckedAt(LocalDateTime.now());
            assetRepository.save(asset);
        }

        Complaint saved = complaintRepository.save(complaint);
        return toDto(saved);
    }

    @Transactional
    public ComplaintDto updateStatus(Long complaintId, UpdateComplaintStatusRequest request) {
        Complaint complaint = complaintRepository.findById(complaintId)
                .orElseThrow(() -> new ResourceNotFoundException("Complaint " + complaintId + " not found"));

        ComplaintStatus status;
        try {
            status = ComplaintStatus.valueOf(request.status().toUpperCase());
        } catch (IllegalArgumentException ex) {
            throw new InvalidRequestException("Unknown complaint status: " + request.status());
        }

        complaint.setStatus(status);
        if (request.resolutionNotes() != null && !request.resolutionNotes().isBlank()) {
            complaint.setResolutionNotes(request.resolutionNotes());
        }

        if (status == ComplaintStatus.RESOLVED || status == ComplaintStatus.CLOSED) {
            complaint.setResolvedAt(LocalDateTime.now());
            complaint.setResolvedBy(request.resolvedBy());
            // Closing the loop: the asset goes back to WORKING once the fix is confirmed.
            if (complaint.getAsset() != null) {
                Asset asset = complaint.getAsset();
                asset.setStatus(AssetStatus.WORKING);
                asset.setComment(null);
                asset.setLastCheckedAt(LocalDateTime.now());
                assetRepository.save(asset);
            }
        }

        Complaint saved = complaintRepository.save(complaint);
        return toDto(saved);
    }

    private String generateIvrsNumber() {
        long count = complaintRepository.count() + 1;
        return "TT" + String.format("%06d", count);
    }

    private ComplaintDto toDto(Complaint complaint) {
        Location location = complaint.getLocation();
        return new ComplaintDto(
                complaint.getId(),
                complaint.getIvrsNumber(),
                location.getId(),
                location.getName(),
                location.getType().name(),
                location.getFloor().getId(),
                location.getFloor().getFloorNumber(),
                location.getFloor().getHostel().getId(),
                location.getFloor().getHostel().getName(),
                complaint.getAsset() != null ? complaint.getAsset().getId() : null,
                complaint.getAsset() != null ? complaint.getAsset().getName() : null,
                complaint.getTitle(),
                complaint.getDescription(),
                complaint.getStatus().name(),
                complaint.getPriority().name(),
                complaint.getReportedBy(),
                complaint.getCreatedAt() != null ? complaint.getCreatedAt().format(TS) : null,
                complaint.getResolvedAt() != null ? complaint.getResolvedAt().format(TS) : null,
                complaint.getResolvedBy(),
                complaint.getResolutionNotes()
        );
    }
}
