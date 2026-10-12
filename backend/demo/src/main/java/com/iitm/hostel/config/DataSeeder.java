package com.iitm.hostel.config;

import com.iitm.hostel.enums.AssetStatus;
import com.iitm.hostel.enums.LocationType;
import com.iitm.hostel.enums.RoomType;
import com.iitm.hostel.enums.UserRole;
import com.iitm.hostel.model.*;
import com.iitm.hostel.repository.*;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.password.PasswordEncoder;

@Configuration
public class DataSeeder {

    @Bean
    public CommandLineRunner seedData(
            AppUserRepository userRepository,
            HostelRepository hostelRepository,
            FloorRepository floorRepository,
            LocationRepository locationRepository,
            AssetRepository assetRepository,
            PasswordEncoder passwordEncoder) {
        return args -> {
            if (userRepository.count() > 0) {
                return; // already seeded
            }

            Hostel hostel = new Hostel();
            hostel.setName("Brahmaputra");
            hostel = hostelRepository.save(hostel);

            Floor floor = new Floor();
            floor.setFloorNumber(1);
            floor.setHostel(hostel);
            floor = floorRepository.save(floor);

            Location room1 = new Location();
            room1.setName("Room 101");
            room1.setFloor(floor);
            room1.setType(LocationType.ROOM);
            room1.setRoomType(RoomType.DOUBLE);
            room1 = locationRepository.save(room1);
            
            Location commonArea = new Location();
            commonArea.setName("First Floor Common Area");
            commonArea.setFloor(floor);
            commonArea.setType(LocationType.COMMON_AREA);
            commonArea = locationRepository.save(commonArea);

            Asset dispenser = new Asset();
            dispenser.setName("Water Dispenser 1");
            dispenser.setLocation(commonArea);
            dispenser.setStatus(AssetStatus.WORKING);
            assetRepository.save(dispenser);
            
            Asset fan = new Asset();
            fan.setName("Ceiling Fan A");
            fan.setLocation(room1);
            fan.setStatus(AssetStatus.WORKING);
            assetRepository.save(fan);

            AppUser manager = new AppUser();
            manager.setUsername("admin");
            manager.setFullName("Admin Manager");
            manager.setPasswordHash(passwordEncoder.encode("password"));
            manager.setRole(UserRole.MANAGER);
            manager.setHostel(hostel);
            userRepository.save(manager);

            AppUser staff = new AppUser();
            staff.setUsername("staff1");
            staff.setFullName("Maintenance Staff 1");
            staff.setPasswordHash(passwordEncoder.encode("password"));
            staff.setRole(UserRole.STAFF);
            staff.setHostel(hostel);
            userRepository.save(staff);

            AppUser student = new AppUser();
            student.setUsername("student1");
            student.setFullName("Student One");
            student.setPasswordHash(passwordEncoder.encode("password"));
            student.setRole(UserRole.STUDENT);
            student.setHostel(hostel);
            student.setAllocatedRoom(room1);
            userRepository.save(student);
            
            System.out.println("Demo Data Seeded Successfully!");
        };
    }
}
