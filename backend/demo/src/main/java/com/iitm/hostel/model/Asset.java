package com.iitm.hostel.model;

import com.iitm.hostel.enums.AssetStatus;
import jakarta.persistence.*;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * The actual physical item sitting in a location (a specific Fan in Room 101,
 * a specific Tap in RR-01). Defaults to WORKING and only needs staff
 * attention when a complaint pushes it out of that state.
 */
@Data
@Entity
@Table(name = "assets")
public class Asset {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private AssetStatus status = AssetStatus.WORKING;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "asset_template_id")
    private AssetTemplate assetTemplate;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "location_id", nullable = false)
    private Location location;

    @Column(length = 1000)
    private String comment;

    @Column(name = "last_checked_at")
    private LocalDateTime lastCheckedAt;
}
