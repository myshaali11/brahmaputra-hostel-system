package com.iitm.hostel.dto;

import com.iitm.hostel.model.AppUser;
import com.iitm.hostel.enums.UserRole;

public record UserDto(
        String username,
        String fullName,
        String email,
        UserRole role,
        Long allocatedRoomId,
        String roomName,
        Long floorId,
        Integer floorNumber
) {
    public static UserDto from(AppUser user) {
        Long roomId = user.getAllocatedRoom() != null ? user.getAllocatedRoom().getId() : null;
        String roomName = user.getAllocatedRoom() != null ? user.getAllocatedRoom().getName() : null;
        Long floorId = (user.getAllocatedRoom() != null && user.getAllocatedRoom().getFloor() != null)
                ? user.getAllocatedRoom().getFloor().getId()
                : null;
        Integer floorNumber = (user.getAllocatedRoom() != null && user.getAllocatedRoom().getFloor() != null)
                ? user.getAllocatedRoom().getFloor().getFloorNumber()
                : null;

        return new UserDto(
                user.getUsername(),
                user.getFullName(),
                user.getEmail(),
                user.getRole(),
                roomId,
                roomName,
                floorId,
                floorNumber
        );
    }
}
