package com.iitm.hostel.controller;

import com.iitm.hostel.dto.HostelDto;
import com.iitm.hostel.service.HostelService;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/hostels")
public class HostelController {

    private final HostelService hostelService;

    public HostelController(HostelService hostelService) {
        this.hostelService = hostelService;
    }

    @GetMapping
    public List<HostelDto> getAll() {
        return hostelService.getAllHostels();
    }

    @GetMapping("/{hostelId}")
    public HostelDto getOne(@PathVariable Long hostelId) {
        return hostelService.getHostel(hostelId);
    }
}
