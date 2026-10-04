package com.iitm.hostel.enums;

/**
 * Who is using the system. Drives every access rule in
 * {@link com.iitm.hostel.config.SecurityConfig}:
 * <ul>
 *   <li>MANAGER - hostel manager; full access, dashboard, analytics, adding locations.</li>
 *   <li>STAFF   - caretakers / inspectors doing rounds; inspections, checklists, complaint handling.</li>
 *   <li>STUDENT - residents; can only see their own room and raise complaints for it,
 *       or for restrooms / common areas on their floor.</li>
 * </ul>
 */
public enum UserRole {
    MANAGER,
    STAFF,
    STUDENT
}
