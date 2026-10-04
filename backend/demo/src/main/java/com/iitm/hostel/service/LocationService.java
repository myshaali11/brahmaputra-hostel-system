package com.iitm.hostel.service;

import com.iitm.hostel.dto.CreateLocationRequest;
import com.iitm.hostel.dto.LocationDto;
import com.iitm.hostel.enums.ComplaintStatus;
import com.iitm.hostel.enums.LocationType;
import com.iitm.hostel.exception.InvalidRequestException;
import com.iitm.hostel.exception.ResourceNotFoundException;
import com.iitm.hostel.model.Asset;
import com.iitm.hostel.model.AssetTemplate;
import com.iitm.hostel.model.Floor;
import com.iitm.hostel.model.Location;
import com.iitm.hostel.repository.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;

@Service
public class LocationService {

    private static final List<ComplaintStatus> ACTIVE_STATUSES = List.of(ComplaintStatus.OPEN, ComplaintStatus.IN_PROGRESS);

    private final LocationRepository locationRepository;
    private final FloorRepository floorRepository;
    private final ComplaintRepository complaintRepository;
    private final AssetTemplateRepository assetTemplateRepository;
    private final AssetRepository assetRepository;

    public LocationService(LocationRepository locationRepository, FloorRepository floorRepository,
                            ComplaintRepository complaintRepository, AssetTemplateRepository assetTemplateRepository,
                            AssetRepository assetRepository) {
        this.locationRepository = locationRepository;
        this.floorRepository = floorRepository;
        this.complaintRepository = complaintRepository;
        this.assetTemplateRepository = assetTemplateRepository;
        this.assetRepository = assetRepository;
    }

    public List<LocationDto> getLocationsForFloor(Long floorId) {
        return locationRepository.findByFloorIdOrderByNameAsc(floorId).stream().map(this::toDto).toList();
    }

    public LocationDto getLocation(Long locationId) {
        Location location = findLocationOrThrow(locationId);
        return toDto(location);
    }

    /**
     * Adds a new Room / Restroom / Common Area to a floor and auto-provisions
     * its standard physical assets from {@link AssetTemplate}. This is what
     * makes the template tables pull their weight instead of being decorative:
     * add "Room 305" and it walks in with a Cot, Chair, Study Table, Fan,
     * Cupboard and Ethernet Point already created and marked WORKING.
     */
    @Transactional
    public LocationDto createLocation(Long floorId, CreateLocationRequest request) {
        Floor floor = floorRepository.findById(floorId)
                .orElseThrow(() -> new ResourceNotFoundException("Floor " + floorId + " not found"));

        LocationType type;
        try {
            type = LocationType.valueOf(request.type().toUpperCase());
        } catch (IllegalArgumentException ex) {
            throw new InvalidRequestException("Unknown location type: " + request.type());
        }

        Location location = new Location();
        location.setName(request.name());
        location.setType(type);
        location.setFloor(floor);
        location = locationRepository.save(location);

        List<AssetTemplate> templates = assetTemplateRepository.findByLocationTypeOrderBySortOrderAsc(type);
        for (AssetTemplate template : templates) {
            if (template.isOptional()) {
                continue; // optional assets (e.g. Vending Machine) are added manually, not on every location
            }
            Asset asset = new Asset();
            asset.setName(template.getName());
            asset.setAssetTemplate(template);
            asset.setLocation(location);
            assetRepository.save(asset);
        }

        return toDto(location);
    }

    /** Stamps a location as inspected "now" by the given staff name -- called after a routine + asset round is submitted. */
    @Transactional
    public void markInspected(Long locationId, String staffName) {
        Location location = findLocationOrThrow(locationId);
        location.setLastInspectedAt(LocalDateTime.now());
        location.setLastInspectedBy(staffName);
        locationRepository.save(location);
    }

    Location findLocationOrThrow(Long locationId) {
        return locationRepository.findById(locationId)
                .orElseThrow(() -> new ResourceNotFoundException("Location " + locationId + " not found"));
    }

    private LocationDto toDto(Location location) {
        long complaintCount = complaintRepository.countByLocationIdAndStatusIn(location.getId(), ACTIVE_STATUSES);
        String status = complaintCount > 0 ? "ISSUES" : "OK";
        return new LocationDto(
                location.getId(),
                location.getFloor().getId(),
                location.getName(),
                location.getType().name(),
                status,
                (int) complaintCount,
                location.getLastInspectedAt() != null ? location.getLastInspectedAt().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME) : null,
                location.getLastInspectedBy()
        );
    }
}
