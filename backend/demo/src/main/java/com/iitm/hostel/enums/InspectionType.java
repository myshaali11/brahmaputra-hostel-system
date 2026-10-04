package com.iitm.hostel.enums;

/**
 * Why an inspection round was done. Mirrors the three moments in the
 * hostel's paper workflow where room assets are checked.
 */
public enum InspectionType {
    /** Check-in: record the state of every asset when a student moves in. */
    OCCUPANCY,
    /** Check-out: compare against occupancy to find damage / missing items. */
    VACANCY,
    /** Routine monthly / periodic round by hostel staff. */
    PERIODIC
}
