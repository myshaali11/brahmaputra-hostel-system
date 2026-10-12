package com.iitm.hostel.dto;

import com.iitm.hostel.model.AppUser;
import com.iitm.hostel.enums.UserRole;

public record UserDto(String username, String fullName, UserRole role) {
    public static UserDto from(AppUser user) {
        return new UserDto(user.getUsername(), user.getFullName(), user.getRole());
    }
}
