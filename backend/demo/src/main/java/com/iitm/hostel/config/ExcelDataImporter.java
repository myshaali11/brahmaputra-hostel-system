package com.iitm.hostel.config;

import com.iitm.hostel.enums.AssetStatus;
import com.iitm.hostel.enums.LocationType;
import com.iitm.hostel.enums.RoomType;
import com.iitm.hostel.enums.UserRole;
import com.iitm.hostel.model.*;
import com.iitm.hostel.repository.*;
import org.apache.poi.ss.usermodel.*;
import org.springframework.boot.CommandLineRunner;
import org.springframework.core.annotation.Order;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Component
@Order(2)
public class ExcelDataImporter implements CommandLineRunner {

    private final HostelRepository hostels;
    private final FloorRepository floors;
    private final LocationRepository locations;
    private final AssetRepository assets;
    private final AppUserRepository users;
    private final PasswordEncoder passwordEncoder;

    public ExcelDataImporter(
            HostelRepository hostels,
            FloorRepository floors,
            LocationRepository locations,
            AssetRepository assets,
            AppUserRepository users,
            PasswordEncoder passwordEncoder) {
        this.hostels = hostels;
        this.floors = floors;
        this.locations = locations;
        this.assets = assets;
        this.users = users;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    public void run(String... args) throws Exception {
        // Multi-path search so it works regardless of working directory
        List<Path> candidates = List.of(
            Path.of("../../database/brahmaputra_synthetic_dataset_boys_only.xlsx"),
            Path.of("../database/brahmaputra_synthetic_dataset_boys_only.xlsx"),
            Path.of("database/brahmaputra_synthetic_dataset_boys_only.xlsx"),
            Path.of("brahmaputra_synthetic_dataset_boys_only.xlsx")
        );

        Path file = candidates.stream().filter(Files::exists).findFirst().orElse(null);

        if (file == null) {
            System.out.println("Excel dataset not found; skipping synthetic data import.");
            return;
        }

        System.out.println("Starting synthetic dataset import from: " + file.toAbsolutePath());

        Hostel hostel = hostels.findByName("Brahmaputra")
            .orElseGet(() -> {
                Hostel h = new Hostel();
                h.setName("Brahmaputra");
                return hostels.save(h);
            });

        // Ensure Manager and Staff accounts always exist with official smail emails
        if (users.findByUsername("admin").isEmpty()) {
            AppUser manager = new AppUser();
            manager.setUsername("admin");
            manager.setFullName("Admin Manager");
            manager.setEmail("admin@smail.iitm.ac.in");
            manager.setPasswordHash(passwordEncoder.encode("password"));
            manager.setRole(UserRole.MANAGER);
            manager.setHostel(hostel);
            users.save(manager);
        } else {
            users.findByUsername("admin").ifPresent(m -> {
                if (m.getEmail() == null) {
                    m.setEmail("admin@smail.iitm.ac.in");
                    users.save(m);
                }
            });
        }

        if (users.findByUsername("staff1").isEmpty()) {
            AppUser staff = new AppUser();
            staff.setUsername("staff1");
            staff.setFullName("Maintenance Staff 1");
            staff.setEmail("staff1@smail.iitm.ac.in");
            staff.setPasswordHash(passwordEncoder.encode("password"));
            staff.setRole(UserRole.STAFF);
            staff.setHostel(hostel);
            users.save(staff);
        } else {
            users.findByUsername("staff1").ifPresent(s -> {
                if (s.getEmail() == null) {
                    s.setEmail("staff1@smail.iitm.ac.in");
                    users.save(s);
                }
            });
        }

        Map<Integer, Floor> floorMap = new HashMap<>();
        Map<String, Location> roomMap = new HashMap<>();

        try (InputStream input = Files.newInputStream(file);
             Workbook workbook = WorkbookFactory.create(input)) {

            DataFormatter formatter = new DataFormatter();

            // 1. Import Rooms
            Sheet roomSheet = workbook.getSheet("Rooms");
            int roomsCreated = 0;

            for (int i = 1; i <= roomSheet.getLastRowNum(); i++) {
                Row row = roomSheet.getRow(i);
                if (row == null) continue;

                String roomNumber = cell(formatter, row, 0);
                String floorText = cell(formatter, row, 1);
                String typeText = cell(formatter, row, 2);

                if (roomNumber.isBlank() || floorText.isBlank() || typeText.isBlank()) continue;

                int floorNumber = Integer.parseInt(floorText);
                RoomType parsedType;
                try {
                    parsedType = RoomType.valueOf(typeText.trim().toUpperCase());
                } catch (IllegalArgumentException e) {
                    parsedType = RoomType.DOUBLE;
                }
                final RoomType roomType = parsedType;

                Floor floor = floorMap.computeIfAbsent(
                    floorNumber, number -> floors
                        .findByHostelIdOrderByFloorNumberAsc(hostel.getId())
                        .stream()
                        .filter(f -> f.getFloorNumber().equals(number))
                        .findFirst()
                        .orElseGet(() -> {
                            Floor f = new Floor();
                            f.setFloorNumber(number);
                            f.setHostel(hostel);
                            return floors.save(f);
                        })
                );

                Location room = locations
                    .findByNameAndFloorId(roomNumber, floor.getId())
                    .orElseGet(() -> {
                        Location loc = new Location();
                        loc.setName(roomNumber);
                        loc.setFloor(floor);
                        loc.setType(LocationType.ROOM);
                        loc.setRoomType(roomType);
                        return locations.save(loc);
                    });

                room.setRoomType(roomType);
                room = locations.save(room);
                roomMap.put(floorNumber + "|" + roomNumber, room);
                roomsCreated++;

                // Provision standard room assets if none exist yet
                provisionRoomAssetsIfMissing(room);
            }

            // 2. Import Students & map them to allocated rooms
            Sheet studentSheet = workbook.getSheet("Students");
            int studentsImported = 0;

            for (int i = 1; i <= studentSheet.getLastRowNum(); i++) {
                Row row = studentSheet.getRow(i);
                if (row == null) continue;

                String name = cell(formatter, row, 0);
                String rollNumber = cell(formatter, row, 1);
                String email = cell(formatter, row, 2);
                String roomNumber = cell(formatter, row, 3);
                String floorText = cell(formatter, row, 4);

                if (name.isBlank() || rollNumber.isBlank() || roomNumber.isBlank() || floorText.isBlank()) continue;

                int floorNumber = Integer.parseInt(floorText);
                Location room = roomMap.get(floorNumber + "|" + roomNumber);

                if (room == null) {
                    continue; // Skip unmapped room gracefully
                }

                String username = rollNumber.trim().toLowerCase();
                String resolvedEmail = email.isBlank() ? (username + "@smail.iitm.ac.in") : email.trim().toLowerCase();

                AppUser user = users.findByUsername(username)
                    .orElseGet(() -> {
                        AppUser u = new AppUser();
                        u.setUsername(username);
                        u.setPasswordHash(passwordEncoder.encode("password"));
                        u.setRole(UserRole.STUDENT);
                        return u;
                    });

                // Do not overwrite manager or staff accounts
                if (user.getId() != null && user.getRole() != UserRole.STUDENT) {
                    continue;
                }

                user.setFullName(name);
                user.setEmail(resolvedEmail);
                user.setRole(UserRole.STUDENT);
                user.setHostel(hostel);
                user.setAllocatedRoom(room);
                users.save(user);
                studentsImported++;
            }

            System.out.println("=================================================");
            System.out.println("✅ Synthetic Dataset Imported Successfully!");
            System.out.println("   Rooms Processed: " + roomsCreated);
            System.out.println("   Students Enrolled: " + studentsImported);
            System.out.println("   All accounts configured with @smail.iitm.ac.in emails");
            System.out.println("   Password for all synthetic accounts: password");
            System.out.println("=================================================");
        }
    }

    private void provisionRoomAssetsIfMissing(Location room) {
        if (!assets.findByLocationIdOrderByNameAsc(room.getId()).isEmpty()) {
            return;
        }

        List<String> defaultFixtures = List.of(
            "Ceiling Fan",
            "Bed Cot",
            "Study Table",
            "Study Chair"
        );

        for (String fixtureName : defaultFixtures) {
            Asset asset = new Asset();
            asset.setName(fixtureName);
            asset.setLocation(room);
            asset.setStatus(AssetStatus.WORKING);
            assets.save(asset);
        }
    }

    private static String cell(DataFormatter formatter, Row row, int index) {
        Cell value = row.getCell(index, Row.MissingCellPolicy.RETURN_BLANK_AS_NULL);
        return value == null ? "" : formatter.formatCellValue(value).trim();
    }
}
