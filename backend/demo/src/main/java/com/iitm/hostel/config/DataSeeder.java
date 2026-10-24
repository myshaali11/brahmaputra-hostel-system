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
import org.springframework.core.annotation.Order;
@Order(1)
@Configuration
public class DataSeeder {

    @Bean
    @Order(1)
    public CommandLineRunner seedData(
            AppUserRepository userRepository,
            HostelRepository hostelRepository,
            FloorRepository floorRepository,
            LocationRepository locationRepository,
            AssetRepository assetRepository,
            PasswordEncoder passwordEncoder) {
        return args -> {
            Hostel hostel = hostelRepository.findByName("Brahmaputra")
                    .orElseGet(() -> {
                        Hostel h = new Hostel();
                        h.setName("Brahmaputra");
                        return hostelRepository.save(h);
                    });

            Floor floor = floorRepository.findByHostelIdOrderByFloorNumberAsc(hostel.getId()).stream()
                    .filter(f -> f.getFloorNumber().equals(1))
                    .findFirst()
                    .orElseGet(() -> {
                        Floor f = new Floor();
                        f.setFloorNumber(1);
                        f.setHostel(hostel);
                        return floorRepository.save(f);
                    });

            Location room1 = locationRepository.findByNameAndFloorId("Room 101", floor.getId())
                    .orElseGet(() -> {
                        Location r = new Location();
                        r.setName("Room 101");
                        r.setFloor(floor);
                        r.setType(LocationType.ROOM);
                        r.setRoomType(RoomType.DOUBLE);
                        return locationRepository.save(r);
                    });

            if (userRepository.findByUsername("admin").isEmpty()) {
                AppUser manager = new AppUser();
                manager.setUsername("admin");
                manager.setFullName("Admin Manager");
                manager.setPasswordHash(passwordEncoder.encode("password"));
                manager.setRole(UserRole.MANAGER);
                manager.setHostel(hostel);
                userRepository.save(manager);
            }

            if (userRepository.findByUsername("staff1").isEmpty()) {
                AppUser staff = new AppUser();
                staff.setUsername("staff1");
                staff.setFullName("Maintenance Staff 1");
                staff.setPasswordHash(passwordEncoder.encode("password"));
                staff.setRole(UserRole.STAFF);
                staff.setHostel(hostel);
                userRepository.save(staff);
            }

            if (userRepository.findByUsername("student1").isEmpty()) {
                AppUser student = new AppUser();
                student.setUsername("student1");
                student.setFullName("Student One");
                student.setPasswordHash(passwordEncoder.encode("password"));
                student.setRole(UserRole.STUDENT);
                student.setHostel(hostel);
                student.setAllocatedRoom(room1);
                userRepository.save(student);
            }
            
            System.out.println("✅ Base accounts verified: admin, staff1, student1");
        };
    }
}
