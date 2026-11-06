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

    public static String normalizeRoomName(String originalRoom, int floorNumber) {
        if (originalRoom == null || originalRoom.isBlank()) return "Room";
        String digits = originalRoom.replaceAll("\\D+", "");
        int index = 1;
        if (!digits.isEmpty()) {
            int fullNum = Integer.parseInt(digits);
            index = fullNum % 100;
            if (index == 0) index = fullNum;
        }
        String formattedNum = String.format("%02d", index);
        return switch (floorNumber) {
            case 0 -> "G" + formattedNum;
            case 1 -> "F" + formattedNum;
            case 2 -> "S" + formattedNum;
            case 3 -> "T" + formattedNum;
            case 4 -> "Fo" + formattedNum;
            default -> "R" + floorNumber + "-" + formattedNum;
        };
    }

    @Override
    public void run(String... args) throws Exception {
        List<Path> candidates = List.of(
            Path.of("../../database/brahmaputra_synthetic_dataset_boys_only.xlsx"),
            Path.of("../database/brahmaputra_synthetic_dataset_boys_only.xlsx"),
            Path.of("database/brahmaputra_synthetic_dataset_boys_only.xlsx"),
            Path.of("brahmaputra_synthetic_dataset_boys_only.xlsx")
        );

        Path file = candidates.stream().filter(Files::exists).findFirst().orElse(null);

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

        // 1. Provision Ground Floor (Floor 0) with G01-G10, Washrooms & Laundry Area
        provisionGroundFloor(hostel, floorMap, roomMap);

        if (file == null) {
            System.out.println("Excel dataset not found; skipping synthetic data import.");
            return;
        }

        System.out.println("Starting synthetic dataset import from: " + file.toAbsolutePath());

        try (InputStream input = Files.newInputStream(file);
             Workbook workbook = WorkbookFactory.create(input)) {

            DataFormatter formatter = new DataFormatter();

            // 2. Import Rooms from Excel (Floors 1 to 4)
            Sheet roomSheet = workbook.getSheet("Rooms");
            int roomsCreated = 0;

            for (int i = 1; i <= roomSheet.getLastRowNum(); i++) {
                Row row = roomSheet.getRow(i);
                if (row == null) continue;

                String rawRoomNumber = cell(formatter, row, 0);
                String floorText = cell(formatter, row, 1);
                String typeText = cell(formatter, row, 2);

                if (rawRoomNumber.isBlank() || floorText.isBlank() || typeText.isBlank()) continue;

                int floorNumber = Integer.parseInt(floorText);
                String normalizedRoom = normalizeRoomName(rawRoomNumber, floorNumber);

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
                    .findByNameAndFloorId(normalizedRoom, floor.getId())
                    .orElseGet(() -> {
                        Location loc = new Location();
                        loc.setName(normalizedRoom);
                        loc.setFloor(floor);
                        loc.setType(LocationType.ROOM);
                        loc.setRoomType(roomType);
                        return locations.save(loc);
                    });

                room.setRoomType(roomType);
                room = locations.save(room);

                // Store mappings for student allocation lookups
                roomMap.put(floorNumber + "|" + normalizedRoom, room);
                roomMap.put(floorNumber + "|" + rawRoomNumber, room);
                roomMap.put(rawRoomNumber, room);
                roomMap.put(normalizedRoom, room);
                roomsCreated++;

                // Provision standard room assets if none exist yet
                provisionRoomAssetsIfMissing(room);

                // Provision washrooms & laundry for this floor
                provisionWashroomsForFloor(hostel, floor);
                provisionLaundryForFloor(hostel, floor);
            }

            // 3. Import Students & map them to allocated rooms
            Sheet studentSheet = workbook.getSheet("Students");
            int studentsImported = 0;

            for (int i = 1; i <= studentSheet.getLastRowNum(); i++) {
                Row row = studentSheet.getRow(i);
                if (row == null) continue;

                String name = cell(formatter, row, 0);
                String rollNumber = cell(formatter, row, 1);
                String email = cell(formatter, row, 2);
                String rawRoomNumber = cell(formatter, row, 3);
                String floorText = cell(formatter, row, 4);

                if (name.isBlank() || rollNumber.isBlank() || rawRoomNumber.isBlank() || floorText.isBlank()) continue;

                int floorNumber = Integer.parseInt(floorText);
                String normalizedRoom = normalizeRoomName(rawRoomNumber, floorNumber);
                Location room = roomMap.get(floorNumber + "|" + normalizedRoom);
                if (room == null) {
                    room = roomMap.get(floorNumber + "|" + rawRoomNumber);
                }
                if (room == null) {
                    room = roomMap.get(normalizedRoom);
                }

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
            System.out.println("✅ Synthetic Dataset & Amenities Imported Successfully!");
            System.out.println("   Rooms Processed: " + roomsCreated + " across floors 0-4");
            System.out.println("   Washrooms & Washing Machine Amenities active on every floor");
            System.out.println("   Students Enrolled: " + studentsImported);
            System.out.println("   All accounts configured with @smail.iitm.ac.in emails");
            System.out.println("   Password for all synthetic accounts: password");
            System.out.println("=================================================");
        }
    }

    private void provisionGroundFloor(Hostel hostel, Map<Integer, Floor> floorMap, Map<String, Location> roomMap) {
        Floor groundFloor = floorMap.computeIfAbsent(0, num -> floors
            .findByHostelIdOrderByFloorNumberAsc(hostel.getId())
            .stream()
            .filter(f -> f.getFloorNumber().equals(0))
            .findFirst()
            .orElseGet(() -> {
                Floor f = new Floor();
                f.setFloorNumber(0);
                f.setHostel(hostel);
                return floors.save(f);
            })
        );

        for (int i = 1; i <= 10; i++) {
            String roomName = String.format("G%02d", i);
            Location room = locations.findByNameAndFloorId(roomName, groundFloor.getId())
                .orElseGet(() -> {
                    Location loc = new Location();
                    loc.setName(roomName);
                    loc.setFloor(groundFloor);
                    loc.setType(LocationType.ROOM);
                    loc.setRoomType(RoomType.DOUBLE);
                    return locations.save(loc);
                });
            roomMap.put("0|" + roomName, room);
            roomMap.put(roomName, room);
            provisionRoomAssetsIfMissing(room);
        }

        provisionWashroomsForFloor(hostel, groundFloor);
        provisionLaundryForFloor(hostel, groundFloor);
    }

    private void provisionWashroomsForFloor(Hostel hostel, Floor floor) {
        int floorNum = floor.getFloorNumber();
        int startId;
        int endId;
        String prefix;
        if (floorNum == 0) {
            startId = 1;
            endId = 10;
            prefix = "RR-G";
        } else if (floorNum == 1) {
            startId = 1;
            endId = 10;
            prefix = "RR";
        } else if (floorNum == 2) {
            startId = 11;
            endId = 20;
            prefix = "RR";
        } else if (floorNum == 3) {
            startId = 21;
            endId = 30;
            prefix = "RR";
        } else if (floorNum == 4) {
            startId = 31;
            endId = 40;
            prefix = "RR";
        } else {
            startId = (floorNum * 10) + 1;
            endId = startId + 9;
            prefix = "RR" + floorNum + "-";
        }

        List<String> restroomAssets = List.of(
            "Wash Basin & Tap",
            "Flush Valve & Cistern",
            "Shower Head",
            "Health Faucet / Jet Spray",
            "Exhaust Fan",
            "Mirror"
        );

        for (int i = startId; i <= endId; i++) {
            String washroomName = prefix + i;
            Location restroom = locations.findByNameAndFloorId(washroomName, floor.getId())
                .orElseGet(() -> {
                    Location loc = new Location();
                    loc.setName(washroomName);
                    loc.setFloor(floor);
                    loc.setType(LocationType.RESTROOM);
                    return locations.save(loc);
                });

            if (assets.findByLocationIdOrderByNameAsc(restroom.getId()).isEmpty()) {
                for (String assetName : restroomAssets) {
                    Asset a = new Asset();
                    a.setName(assetName);
                    a.setLocation(restroom);
                    a.setStatus(AssetStatus.WORKING);
                    assets.save(a);
                }
            }
        }
    }

    private void provisionLaundryForFloor(Hostel hostel, Floor floor) {
        String laundryName = "Laundry & Wash Area (Floor " + floor.getFloorNumber() + ")";
        Location laundry = locations.findByNameAndFloorId(laundryName, floor.getId())
            .orElseGet(() -> {
                Location loc = new Location();
                loc.setName(laundryName);
                loc.setFloor(floor);
                loc.setType(LocationType.COMMON_AREA);
                return locations.save(loc);
            });

        if (assets.findByLocationIdOrderByNameAsc(laundry.getId()).isEmpty()) {
            List<String> laundryAssets = List.of(
                "Washing Machine 1 (Front Load 8kg)",
                "Washing Machine 2 (Top Load 7.5kg)",
                "Water Purifier (RO + UV Dispenser)",
                "Ironing Station & Table"
            );
            for (String aName : laundryAssets) {
                Asset a = new Asset();
                a.setName(aName);
                a.setLocation(laundry);
                a.setStatus(AssetStatus.WORKING);
                assets.save(a);
            }
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
