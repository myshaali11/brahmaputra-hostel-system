package com.iitm.hostel.model;

import com.iitm.hostel.enums.UserRole;
import jakarta.persistence.*;
import lombok.Data;

/**
 * An authenticated user of the system. Replaces the earlier name-only
 * "staff identity" picker with real accounts so that role-based access
 * (manager / staff / student) can actually be enforced on the server.
 */
@Data
@Entity
@Table(name = "app_users")
public class AppUser {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String username;

    @Column(unique = true)
    private String email;

    /** BCrypt hash - the plain password is never stored. */
    @Column(name = "password_hash", nullable = false)
    private String passwordHash;

    @Column(name = "full_name", nullable = false)
    private String fullName;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private UserRole role;

    /** Hostel the user belongs to (staff / manager scope, student's hostel). */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "hostel_id")
    private Hostel hostel;

    /** For students only: the room they are currently allocated to. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "allocated_room_id")
    private Location allocatedRoom;
}
