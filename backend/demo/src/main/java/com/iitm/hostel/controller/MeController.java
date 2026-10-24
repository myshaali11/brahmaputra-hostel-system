package com.iitm.hostel.controller;

import com.iitm.hostel.dto.*;
import com.iitm.hostel.model.AppUser;
import com.iitm.hostel.service.*;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/me")
public class MeController {

    private final CurrentUser currentUser;
    private final AssetService assetService;
    private final ComplaintService complaintService;

    public MeController(CurrentUser currentUser, AssetService assetService, ComplaintService complaintService) {
        this.currentUser = currentUser;
        this.assetService = assetService;
        this.complaintService = complaintService;
    }

    /** 1. Get student profile & room details */
    @GetMapping
    public UserDto getProfile() {
        return UserDto.from(currentUser.get());
    }

    /** 2. Get all assets in the student's allocated room (Fans, Cots, Chairs) */
    @GetMapping("/assets")
    public List<AssetDto> getMyRoomAssets() {
        AppUser user = currentUser.get();
        if (user.getAllocatedRoom() == null) {
            return List.of();
        }
        return assetService.getAssetsForLocation(user.getAllocatedRoom().getId());
    }

    /** 3. Get all complaints raised by this student */
    @GetMapping("/complaints")
    public List<ComplaintDto> getMyComplaints() {
        AppUser user = currentUser.get();
        return complaintService.getComplaints(null, null, 
                user.getAllocatedRoom() != null ? user.getAllocatedRoom().getId() : null, 
                false);
    }
}