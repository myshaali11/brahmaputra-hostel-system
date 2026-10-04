package com.iitm.hostel.service;

import com.iitm.hostel.dto.RoutineTaskDto;
import com.iitm.hostel.dto.RoutineTaskLogRequest;
import com.iitm.hostel.exception.ResourceNotFoundException;
import com.iitm.hostel.model.Location;
import com.iitm.hostel.model.RoutineTaskLog;
import com.iitm.hostel.model.RoutineTaskTemplate;
import com.iitm.hostel.repository.LocationRepository;
import com.iitm.hostel.repository.RoutineTaskLogRepository;
import com.iitm.hostel.repository.RoutineTaskTemplateRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;
import java.util.Optional;

/**
 * Drives the "cleaning / mopping" style routine checklist that sits
 * alongside the physical asset checklist on the inspection screen.
 *
 * Unlike assets, these tasks are NOT persistent: the list shown for "today"
 * is built by taking every {@link RoutineTaskTemplate} that applies to the
 * location's type and left-joining it against any {@link RoutineTaskLog}
 * row for today's date. If nobody has logged the task yet today, it simply
 * doesn't have a row yet, so it comes back completed=false -- i.e. the
 * checklist naturally resets every day with no cron job or scheduler needed.
 */
@Service
public class RoutineTaskService {

    private final RoutineTaskTemplateRepository templateRepository;
    private final RoutineTaskLogRepository logRepository;
    private final LocationRepository locationRepository;

    public RoutineTaskService(RoutineTaskTemplateRepository templateRepository,
                               RoutineTaskLogRepository logRepository,
                               LocationRepository locationRepository) {
        this.templateRepository = templateRepository;
        this.logRepository = logRepository;
        this.locationRepository = locationRepository;
    }

    public List<RoutineTaskDto> getTodayChecklist(Long locationId) {
        Location location = findLocationOrThrow(locationId);
        List<RoutineTaskTemplate> templates = templateRepository.findByLocationTypeOrderBySortOrderAsc(location.getType());
        if (templates.isEmpty()) {
            return List.of();
        }

        LocalDate today = LocalDate.now();
        List<RoutineTaskLog> todaysLogs = logRepository.findByLocationIdAndLogDate(locationId, today);
        Map<String, RoutineTaskLog> byTaskName = todaysLogs.stream()
                .collect(java.util.stream.Collectors.toMap(RoutineTaskLog::getTaskName, l -> l, (a, b) -> a));

        return templates.stream().map(template -> {
            RoutineTaskLog log = byTaskName.get(template.getName());
            if (log == null) {
                return new RoutineTaskDto(template.getName(), false, null, null, null);
            }
            return new RoutineTaskDto(
                    log.getTaskName(),
                    log.isCompleted(),
                    log.getComment(),
                    log.getLoggedBy(),
                    log.getLoggedAt() != null ? log.getLoggedAt().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME) : null
            );
        }).toList();
    }

    /** Ticks (or un-ticks) one routine task for today, creating today's log row the first time it's touched. */
    @Transactional
    public RoutineTaskDto logTask(Long locationId, RoutineTaskLogRequest request) {
        Location location = findLocationOrThrow(locationId);
        LocalDate today = LocalDate.now();

        Optional<RoutineTaskLog> existing = logRepository.findByLocationIdAndTaskNameAndLogDate(locationId, request.taskName(), today);
        RoutineTaskLog log = existing.orElseGet(RoutineTaskLog::new);
        log.setLocation(location);
        log.setTaskName(request.taskName());
        log.setLogDate(today);
        log.setCompleted(request.completed());
        log.setComment(request.comment() == null || request.comment().isBlank() ? null : request.comment());
        log.setLoggedBy(request.loggedBy());
        log.setLoggedAt(java.time.LocalDateTime.now());
        RoutineTaskLog saved = logRepository.save(log);

        return new RoutineTaskDto(
                saved.getTaskName(),
                saved.isCompleted(),
                saved.getComment(),
                saved.getLoggedBy(),
                saved.getLoggedAt().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME)
        );
    }

    private Location findLocationOrThrow(Long locationId) {
        return locationRepository.findById(locationId)
                .orElseThrow(() -> new ResourceNotFoundException("Location " + locationId + " not found"));
    }
}
