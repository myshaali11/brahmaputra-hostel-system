package com.iitm.hostel.enums;

/** Condition of one asset as observed during an inspection round. */
public enum AssetCondition {
    GOOD,
    DAMAGED,
    MISSING;

    /** DAMAGED and MISSING both need follow-up, so they auto-raise a complaint. */
    public boolean needsAction() {
        return this != GOOD;
    }
}
