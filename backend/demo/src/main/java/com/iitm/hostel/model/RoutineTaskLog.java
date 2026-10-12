package com.iitm.hostel.model;

import jakarta.persistence.*;
import lombok.Data;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * A single day's record of one routine task (e.g. "Mopping" in RR-01 on
 * 2026-09-02) being ticked off. One row is created the first time a task
 * is confirmed for a given location+day; if no row exists for today, the
 * task is treated as not yet done -- this is what gives the daily reset
 * behaviour without a scheduled job.
 */
@Data
@Entity
@Table(name = "routine_task_logs", uniqueConstraints = {
        @UniqueConstraint(columnNames = {"location_id", "task_name", "log_date"})
})
public class RoutineTaskLog {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "location_id", nullable = false)
    private Location location;

    @Column(name = "task_name", nullable = false)
    private String taskName;

    @Column(name = "log_date", nullable = false)
    private LocalDate logDate;

    @Column(nullable = false)
    private boolean completed = false;

    @Column(length = 1000)
    private String comment;

    @Column(name = "logged_by")
    private String loggedBy;

    @Column(name = "logged_at")
    private LocalDateTime loggedAt;
}
