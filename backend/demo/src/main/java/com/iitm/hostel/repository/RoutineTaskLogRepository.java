package com.iitm.hostel.repository;

import com.iitm.hostel.model.RoutineTaskLog;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface RoutineTaskLogRepository extends JpaRepository<RoutineTaskLog, Long> {
    List<RoutineTaskLog> findByLocationIdAndLogDate(Long locationId, LocalDate logDate);
    Optional<RoutineTaskLog> findByLocationIdAndTaskNameAndLogDate(Long locationId, String taskName, LocalDate logDate);
    List<RoutineTaskLog> findByLocationIdOrderByLogDateDesc(Long locationId);
}
