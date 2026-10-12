package com.iitm.hostel.controller;

import com.iitm.hostel.dto.CreateLocationRequest;
import com.iitm.hostel.dto.LocationDto;
import com.iitm.hostel.service.LocationService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class LocationController {

    private final LocationService locationService;

    public LocationController(LocationService locationService) {
        this.locationService = locationService;
    }

    @GetMapping("/floors/{floorId}/locations")
    public List<LocationDto> getLocations(@PathVariable Long floorId) {
        return locationService.getLocationsForFloor(floorId);
    }

    @GetMapping("/locations/{locationId}")
    public LocationDto getLocation(@PathVariable Long locationId) {
        return locationService.getLocation(locationId);
    }

    @PostMapping("/floors/{floorId}/locations")
    public ResponseEntity<LocationDto> createLocation(@PathVariable Long floorId, @Valid @RequestBody CreateLocationRequest request) {
        return ResponseEntity.status(201).body(locationService.createLocation(floorId, request));
    }

    @PostMapping("/locations/{locationId}/inspections")
    public ResponseEntity<Void> markInspected(@PathVariable Long locationId, @RequestBody Map<String, String> payload) {
        locationService.markInspected(locationId, payload.get("staffName"));
        return ResponseEntity.ok().build();
    }
}
