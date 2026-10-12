package com.iitm.hostel.repository;

import com.iitm.hostel.model.Floor;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface FloorRepository extends JpaRepository<Floor, Long> {
    List<Floor> findByHostelIdOrderByFloorNumberAsc(Long hostelId);
}
