package com.iitm.hostel.controller;

import com.iitm.hostel.dto.ComplaintDto;
import com.iitm.hostel.dto.CreateComplaintRequest;
import com.iitm.hostel.dto.UpdateComplaintStatusRequest;
import com.iitm.hostel.service.ComplaintService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/complaints")
public class ComplaintController {

    private final ComplaintService complaintService;

    public ComplaintController(ComplaintService complaintService) {
        this.complaintService = complaintService;
    }

    /**
     * Backs the primary dashboard's complaint feed. Every complaint carries its
     * own hostel/floor/location reference so the feed can be shown un-scoped
     * (all hostels) or filtered down, without a second lookup.
     */
    @GetMapping
    public List<ComplaintDto> getComplaints(
            @RequestParam(required = false) Long hostelId,
            @RequestParam(required = false) Long floorId,
            @RequestParam(required = false) Long locationId,
            @RequestParam(required = false) Boolean activeOnly) {
        return complaintService.getComplaints(hostelId, floorId, locationId, activeOnly);
    }

    @PostMapping
    public ResponseEntity<ComplaintDto> createComplaint(@Valid @RequestBody CreateComplaintRequest request) {
        return ResponseEntity.status(201).body(complaintService.createComplaint(request));
    }

    @PatchMapping("/{complaintId}")
    public ComplaintDto updateStatus(@PathVariable Long complaintId, @Valid @RequestBody UpdateComplaintStatusRequest request) {
        return complaintService.updateStatus(complaintId, request);
    }
}
