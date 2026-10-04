package com.iitm.hostel.enums;

/** Occupancy configuration of a student room (only meaningful for LocationType.ROOM). */
public enum RoomType {
    SINGLE(1),
    DOUBLE(2),
    TRIPLE(3);

    private final int capacity;

    RoomType(int capacity) {
        this.capacity = capacity;
    }

    public int capacity() {
        return capacity;
    }
}
