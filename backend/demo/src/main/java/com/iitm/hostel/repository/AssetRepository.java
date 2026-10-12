package com.iitm.hostel.repository;

import com.iitm.hostel.model.Asset;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface AssetRepository extends JpaRepository<Asset, Long> {
    List<Asset> findByLocationIdOrderByNameAsc(Long locationId);
    long countByLocationFloorHostelId(Long hostelId);
    long countByLocationFloorHostelIdAndStatus(Long hostelId, com.iitm.hostel.enums.AssetStatus status);
    long countByLocationFloorHostelIdAndStatusNot(Long hostelId, com.iitm.hostel.enums.AssetStatus status);
}
