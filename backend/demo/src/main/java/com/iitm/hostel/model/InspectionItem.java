package com.iitm.hostel.model;

import com.iitm.hostel.enums.AssetCondition;
import jakarta.persistence.*;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.ToString;

/** The observed condition of one asset within one {@link Inspection}. */
@Data
@Entity
@Table(name = "inspection_items")
public class InspectionItem {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "inspection_id", nullable = false)
    @ToString.Exclude
    @EqualsAndHashCode.Exclude
    private Inspection inspection;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "asset_id", nullable = false)
    private Asset asset;

    @Enumerated(EnumType.STRING)
    @Column(name = "asset_condition", nullable = false)
    private AssetCondition condition;

    @Column(length = 1000)
    private String remark;

    /** Storage key of the uploaded photo evidence (see PhotoStorage), if any. */
    @Column(name = "photo_key")
    private String photoKey;

    /** Complaint auto-raised because this item was DAMAGED / MISSING, if any. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "complaint_id")
    private Complaint complaint;
}
