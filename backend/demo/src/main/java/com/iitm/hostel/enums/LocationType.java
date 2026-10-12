package com.iitm.hostel.enums;

/**
 * The three physical categories of space inside a hostel floor.
 * Every {@link com.iitm.hostel.model.Location} is exactly one of these,
 * and this is what drives which asset templates / routine tasks apply.
 */
public enum LocationType {
    ROOM,
    RESTROOM,
    COMMON_AREA
}
