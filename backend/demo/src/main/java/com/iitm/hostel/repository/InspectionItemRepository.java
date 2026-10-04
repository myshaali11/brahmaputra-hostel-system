package com.iitm.hostel.repository;

import com.iitm.hostel.model.InspectionItem;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface InspectionItemRepository extends JpaRepository<InspectionItem, Long> {
    List<InspectionItem> findByAssetIdOrderByInspectionCreatedAtDesc(Long assetId);
}
