package com.iitm.hostel.service;

import com.iitm.hostel.dto.FloorDto;
import com.iitm.hostel.enums.ComplaintStatus;
import com.iitm.hostel.enums.LocationType;
import com.iitm.hostel.model.Floor;
import com.iitm.hostel.model.Location;
import com.iitm.hostel.repository.ComplaintRepository;
import com.iitm.hostel.repository.FloorRepository;
import com.iitm.hostel.repository.LocationRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class FloorService {

    private static final List<ComplaintStatus> ACTIVE_STATUSES = List.of(ComplaintStatus.OPEN, ComplaintStatus.IN_PROGRESS);

    private final FloorRepository floorRepository;
    private final LocationRepository locationRepository;
    private final ComplaintRepository complaintRepository;

    public FloorService(FloorRepository floorRepository, LocationRepository locationRepository, ComplaintRepository complaintRepository) {
        this.floorRepository = floorRepository;
        this.locationRepository = locationRepository;
        this.complaintRepository = complaintRepository;
    }

    public List<FloorDto> getFloorsForHostel(Long hostelId) {
        return floorRepository.findByHostelIdOrderByFloorNumberAsc(hostelId).stream().map(this::toDto).toList();
    }

    private FloorDto toDto(Floor floor) {
        List<Location> locations = locationRepository.findByFloorIdOrderByNameAsc(floor.getId());
        long activeComplaints = complaintRepository.countByLocationFloorIdAndStatusIn(floor.getId(), ACTIVE_STATUSES);

        int roomCount = (int) locations.stream().filter(l -> l.getType() == LocationType.ROOM).count();
        int restroomCount = (int) locations.stream().filter(l -> l.getType() == LocationType.RESTROOM).count();
        int commonAreaCount = (int) locations.stream().filter(l -> l.getType() == LocationType.COMMON_AREA).count();

        return new FloorDto(
                floor.getId(),
                floor.getHostel().getId(),
                floor.getFloorNumber(),
                roomCount,
                restroomCount,
                commonAreaCount,
                (int) activeComplaints
        );
    }
}
