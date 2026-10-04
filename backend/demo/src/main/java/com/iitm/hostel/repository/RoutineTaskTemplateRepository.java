package com.iitm.hostel.repository;

import com.iitm.hostel.enums.LocationType;
import com.iitm.hostel.model.RoutineTaskTemplate;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface RoutineTaskTemplateRepository extends JpaRepository<RoutineTaskTemplate, Long> {
    List<RoutineTaskTemplate> findByLocationTypeOrderBySortOrderAsc(LocationType locationType);
}
