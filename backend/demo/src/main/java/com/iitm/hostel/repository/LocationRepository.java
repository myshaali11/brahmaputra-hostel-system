
package com.iitm.hostel.repository;

import com.iitm.hostel.enums.LocationType;
import com.iitm.hostel.model.Location;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface LocationRepository extends JpaRepository<Location, Long> {

    List<Location> findByFloorIdOrderByNameAsc(Long floorId);

    Optional<Location> findByNameAndFloorId(String name, Long floorId);

    List<Location> findByFloorIdAndTypeOrderByNameAsc(
            Long floorId, LocationType type);
}
