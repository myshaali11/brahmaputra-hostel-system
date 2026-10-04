package com.iitm.hostel.controller;

import com.iitm.hostel.dto.DashboardSummaryDto;
import com.iitm.hostel.service.DashboardService;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/dashboard")
public class DashboardController {

    private final DashboardService dashboardService;

    public DashboardController(DashboardService dashboardService) {
        this.dashboardService = dashboardService;
    }

    @GetMapping("/summary")
    public DashboardSummaryDto getSummary(@RequestParam Long hostelId) {
        return dashboardService.getSummary(hostelId);
    }
}
