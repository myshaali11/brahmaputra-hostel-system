package com.iitm.hostel.dto;

import jakarta.validation.constraints.NotBlank;

/**
 * Request payload for Google OAuth on the IIT Madras domain (@smail.iitm.ac.in).
 */
public record GoogleLoginRequest(
        String idToken,
        @NotBlank(message = "Google email is required") String email,
        String name,
        String photoUrl
) {}
