package com.iitm.hostel.model;

import com.iitm.hostel.enums.LocationType;
import jakarta.persistence.*;
import lombok.Data;

/**
 * Defines a recurring housekeeping task for a type of location, e.g.
 * "Cleaning" / "Mopping" for RESTROOM. Unlike physical assets, these are
 * NOT persistent state -- every calendar day resets to "not yet done" and
 * has to be actively ticked off by whoever does the rounds, with today's
 * checklist coming from these templates joined against today's
 * {@link RoutineTaskLog} rows (if any exist yet).
 */
@Data
@Entity
@Table(name = "routine_task_templates")
public class RoutineTaskTemplate {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    @Enumerated(EnumType.STRING)
    @Column(name = "location_type", nullable = false)
    private LocationType locationType;

    @Column(name = "sort_order", nullable = false)
    private Integer sortOrder = 0;
}
