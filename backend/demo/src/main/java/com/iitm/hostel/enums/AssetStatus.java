package com.iitm.hostel.enums;

/**
 * Lifecycle state of a physical asset.
 * WORKING is the default/base state -- staff never have to touch an asset
 * unless something changes it away from WORKING.
 */
public enum AssetStatus {
    WORKING,
    COMPLAINT_RAISED,
    UNDER_REPAIR,
    REPLACED,
    DECOMMISSIONED
}
