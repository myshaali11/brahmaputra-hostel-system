package com.iitm.hostel.dto;

public record LoginResponse(String token, String expiresAt, UserDto user) {
}
