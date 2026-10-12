package com.iitm.hostel.model;

import jakarta.persistence.*;
import lombok.Data;

@Data
@Entity
@Table(name = "hostels")
public class Hostel {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    private String description;

    /** Controls the order hostels appear in the sequential list on the home screen. */
    @Column(name = "display_order", nullable = false)
    private Integer displayOrder = 0;
}
