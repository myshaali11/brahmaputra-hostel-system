package com.iitm.hostel.model;

import com.iitm.hostel.enums.LocationType;
import jakarta.persistence.*;
import lombok.Data;

/**
 * Defines what physical asset *should* exist in a given type of location
 * (e.g. every RESTROOM should have a "Tap"). New locations are provisioned
 * from these templates so nobody has to remember to add the standard
 * assets by hand every time a room is added to the system.
 */
@Data
@Entity
@Table(name = "asset_templates")
public class AssetTemplate {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    @Enumerated(EnumType.STRING)
    @Column(name = "location_type", nullable = false)
    private LocationType locationType;

    /** True for assets that only exist in some, not all, locations of that type (e.g. a Vending Machine). */
    @Column(name = "is_optional", nullable = false)
    private boolean optional = false;

    @Column(name = "sort_order", nullable = false)
    private Integer sortOrder = 0;
}
