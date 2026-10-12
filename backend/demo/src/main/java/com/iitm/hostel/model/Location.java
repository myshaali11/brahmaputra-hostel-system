package com.iitm.hostel.model;

import com.iitm.hostel.enums.LocationType;
import com.iitm.hostel.enums.RoomType;
import jakarta.persistence.*;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * A single addressable spot on a floor: a student Room, a Restroom (RR),
 * or a Common Area (lobby, TT arena, vending zone, etc).
 * This is the node that assets, routine tasks and complaints all hang off.
 */
@Data
@Entity
@Table(name = "locations")
public class Location {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private LocationType type;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "floor_id", nullable = false)
    private Floor floor;

    /** Single / double / triple sharing. Null for restrooms and common areas. */
    @Enumerated(EnumType.STRING)
    @Column(name = "room_type")
    private RoomType roomType;

    @Column(name = "last_inspected_at")
    private LocalDateTime lastInspectedAt;

    @Column(name = "last_inspected_by")
    private String lastInspectedBy;
}
