package com.iitm.hostel.model;

import com.iitm.hostel.enums.InspectionType;
import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * One inspection round of a single location (occupancy check-in, vacancy
 * check-out, or a periodic round). Replaces the paper tick-box sheet: each
 * asset in the location gets an {@link InspectionItem} recording its
 * observed condition, an optional remark and optional photo evidence.
 */
@Data
@Entity
@Table(name = "inspections")
public class Inspection {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "location_id", nullable = false)
    private Location location;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private InspectionType type;

    @Column(name = "inspected_by", nullable = false)
    private String inspectedBy;

    @Column(length = 2000)
    private String notes;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @OneToMany(mappedBy = "inspection", cascade = CascadeType.ALL, orphanRemoval = true)
    @OrderBy("id ASC")
    private List<InspectionItem> items = new ArrayList<>();

    public void addItem(InspectionItem item) {
        item.setInspection(this);
        items.add(item);
    }
}
