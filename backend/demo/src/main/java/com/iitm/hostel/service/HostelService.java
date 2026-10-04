package com.iitm.hostel.service;

import com.iitm.hostel.dto.HostelDto;
import com.iitm.hostel.enums.ComplaintStatus;
import com.iitm.hostel.exception.ResourceNotFoundException;
import com.iitm.hostel.model.Hostel;
import com.iitm.hostel.repository.ComplaintRepository;
import com.iitm.hostel.repository.FloorRepository;
import com.iitm.hostel.repository.HostelRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class HostelService {

    private static final List<ComplaintStatus> ACTIVE_STATUSES = List.of(ComplaintStatus.OPEN, ComplaintStatus.IN_PROGRESS);

    private final HostelRepository hostelRepository;
    private final ComplaintRepository complaintRepository;
    private final FloorRepository floorRepository;

    public HostelService(HostelRepository hostelRepository, ComplaintRepository complaintRepository, FloorRepository floorRepository) {
        this.hostelRepository = hostelRepository;
        this.complaintRepository = complaintRepository;
        this.floorRepository = floorRepository;
    }

    public List<HostelDto> getAllHostels() {
        return hostelRepository.findAllByOrderByDisplayOrderAscNameAsc().stream().map(this::toDto).toList();
    }

    public HostelDto getHostel(Long id) {
        Hostel hostel = hostelRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Hostel " + id + " not found"));
        return toDto(hostel);
    }

    private HostelDto toDto(Hostel hostel) {
        long activeComplaints = complaintRepository.countByLocationFloorHostelIdAndStatusIn(hostel.getId(), ACTIVE_STATUSES);
        int floorCount = floorRepository.findByHostelIdOrderByFloorNumberAsc(hostel.getId()).size();
        return new HostelDto(
                hostel.getId(),
                hostel.getName(),
                hostel.getDescription(),
                hostel.getDisplayOrder(),
                (int) activeComplaints,
                floorCount
        );
    }
}
