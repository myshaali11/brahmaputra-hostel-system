package com.iitm.hostel.controller;

import com.iitm.hostel.dto.RoutineTaskDto;
import com.iitm.hostel.dto.RoutineTaskLogRequest;
import com.iitm.hostel.service.RoutineTaskService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/locations/{locationId}/routine-tasks")
public class RoutineTaskController {

    private final RoutineTaskService routineTaskService;

    public RoutineTaskController(RoutineTaskService routineTaskService) {
        this.routineTaskService = routineTaskService;
    }

    /** Today's cleaning/mopping-style checklist for this location. Resets automatically at midnight. */
    @GetMapping
    public List<RoutineTaskDto> getToday(@PathVariable Long locationId) {
        return routineTaskService.getTodayChecklist(locationId);
    }

    @PostMapping
    public RoutineTaskDto logTask(@PathVariable Long locationId, @Valid @RequestBody RoutineTaskLogRequest request) {
        return routineTaskService.logTask(locationId, request);
    }
}
