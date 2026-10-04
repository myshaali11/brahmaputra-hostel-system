package com.iitm.hostel.controller;

import com.iitm.hostel.dto.FloorDto;
import com.iitm.hostel.service.FloorService;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api")
public class FloorController {

    private final FloorService floorService;

    public FloorController(FloorService floorService) {
        this.floorService = floorService;
    }

    @GetMapping("/hostels/{hostelId}/floors")
    public List<FloorDto> getFloors(@PathVariable Long hostelId) {
        return floorService.getFloorsForHostel(hostelId);
    }
}
