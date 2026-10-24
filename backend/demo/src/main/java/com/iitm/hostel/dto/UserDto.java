package com.iitm.hostel.dto;

import com.iitm.hostel.model.AppUser;
import com.iitm.hostel.enums.UserRole;

public record UserDto(String username, String fullName, UserRole role, Long allocatedRoomId, String roomName) {
    public static UserDto from(AppUser user) {
        Long roomId = user.getAllocatedRoom() != null ? user.getAllocatedRoom().getId() : null;
        String roomName = user.getAllocatedRoom() != null ? user.getAllocatedRoom().getName() : null;
        return new UserDto(user.getUsername(), user.getFullName(), user.getRole(), roomId, roomName);
    }
}
