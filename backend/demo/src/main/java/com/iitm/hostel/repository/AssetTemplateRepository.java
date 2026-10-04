package com.iitm.hostel.repository;

import com.iitm.hostel.enums.LocationType;
import com.iitm.hostel.model.AssetTemplate;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface AssetTemplateRepository extends JpaRepository<AssetTemplate, Long> {
    List<AssetTemplate> findByLocationTypeOrderBySortOrderAsc(LocationType locationType);
}
