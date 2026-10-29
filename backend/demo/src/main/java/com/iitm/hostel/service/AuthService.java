package com.iitm.hostel.service;

import com.iitm.hostel.config.SecurityConfig;
import com.iitm.hostel.dto.GoogleLoginRequest;
import com.iitm.hostel.dto.LoginRequest;
import com.iitm.hostel.dto.LoginResponse;
import com.iitm.hostel.dto.UserDto;
import com.iitm.hostel.enums.LocationType;
import com.iitm.hostel.enums.UserRole;
import com.iitm.hostel.exception.ForbiddenException;
import com.iitm.hostel.exception.UnauthorizedException;
import com.iitm.hostel.model.AppUser;
import com.iitm.hostel.model.Hostel;
import com.iitm.hostel.model.Location;
import com.iitm.hostel.repository.AppUserRepository;
import com.iitm.hostel.repository.HostelRepository;
import com.iitm.hostel.repository.LocationRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.Instant;
import java.util.UUID;
import java.util.regex.Pattern;

/**
 * Verifies credentials, processes IITM Smail Google OAuth logins, and issues signed JWTs.
 */
@Service
@Transactional
public class AuthService {

    /** Matches official IIT Madras roll numbers: 2 department letters, 2 year digits, 1 program letter, 3-4 serial digits. */
    private static final Pattern ROLL_NO_PATTERN = Pattern.compile("^[a-zA-Z]{2}\\d{2}[a-zA-Z]\\d{3,4}$");

    private final AppUserRepository userRepository;
    private final HostelRepository hostelRepository;
    private final LocationRepository locationRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtEncoder jwtEncoder;
    private final Duration tokenLifetime;

    public AuthService(
            AppUserRepository userRepository,
            HostelRepository hostelRepository,
            LocationRepository locationRepository,
            PasswordEncoder passwordEncoder,
            JwtEncoder jwtEncoder,
            @Value("${app.jwt.expiry-hours:24}") long expiryHours) {
        this.userRepository = userRepository;
        this.hostelRepository = hostelRepository;
        this.locationRepository = locationRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtEncoder = jwtEncoder;
        this.tokenLifetime = Duration.ofHours(expiryHours);
    }

    @Transactional(readOnly = true)
    public LoginResponse login(LoginRequest request) {
        AppUser user = userRepository.findByUsername(request.username().trim())
                .filter(u -> passwordEncoder.matches(request.password(), u.getPasswordHash()))
                // Same message for unknown user and wrong password, so usernames can't be probed.
                .orElseThrow(() -> new UnauthorizedException("Invalid username or password"));

        return createLoginResponse(user);
    }

    /**
     * Authenticates or provisions an IIT Madras Google account (@smail.iitm.ac.in).
     *
     * <p>Role classification logic:
     * <ul>
     *   <li>Prefix matches roll number (e.g. {@code ch23b001}) &rarr; {@link UserRole#STUDENT}.</li>
     *   <li>Prefix contains {@code admin}, {@code manager}, or {@code warden} &rarr; {@link UserRole#MANAGER}.</li>
     *   <li>Prefix contains {@code staff}, {@code maintenance}, or {@code caretaker} &rarr; {@link UserRole#STAFF}.</li>
     * </ul>
     */
    public LoginResponse loginWithGoogle(GoogleLoginRequest request) {
        if (request.email() == null || request.email().isBlank()) {
            throw new UnauthorizedException("Email is required for Google Sign-In");
        }

        String email = request.email().trim().toLowerCase();

        // Strict Domain Check: Only IIT Madras official email domains are authorized
        if (!email.endsWith("@smail.iitm.ac.in") && !email.endsWith("@iitm.ac.in") && !email.endsWith("@admin.iitm.ac.in")) {
            throw new ForbiddenException("Access restricted: Only IIT Madras (@smail.iitm.ac.in) accounts are permitted.");
        }

        String prefix = email.substring(0, email.indexOf('@'));

        // 1. Look up existing user by email or username
        AppUser user = userRepository.findByEmail(email)
                .or(() -> userRepository.findByUsername(prefix))
                .orElse(null);

        Hostel defaultHostel = hostelRepository.findByName("Brahmaputra")
                .orElseGet(() -> {
                    Hostel h = new Hostel();
                    h.setName("Brahmaputra");
                    return hostelRepository.save(h);
                });

        if (user != null) {
            // Update email or full name if missing
            if (user.getEmail() == null) {
                user.setEmail(email);
            }
            if ((user.getFullName() == null || user.getFullName().isBlank()) && request.name() != null) {
                user.setFullName(request.name());
            }
            user = userRepository.save(user);
        } else {
            // 2. Classify and dynamically provision new user based on IITM email structure
            user = new AppUser();
            user.setEmail(email);
            user.setUsername(prefix);
            user.setFullName(request.name() != null && !request.name().isBlank() ? request.name() : prefix.toUpperCase());
            user.setPasswordHash(passwordEncoder.encode(UUID.randomUUID().toString())); // secure random hash
            user.setHostel(defaultHostel);

            if (ROLL_NO_PATTERN.matcher(prefix).matches()) {
                // Verified Student Roll Number
                user.setRole(UserRole.STUDENT);
                // Attempt to auto-allocate room if one is available
                Location sampleRoom = locationRepository.findAll().stream()
                        .filter(l -> l.getType() == LocationType.ROOM)
                        .findFirst()
                        .orElse(null);
                user.setAllocatedRoom(sampleRoom);
            } else if (prefix.contains("admin") || prefix.contains("manager") || prefix.contains("warden")) {
                user.setRole(UserRole.MANAGER);
            } else if (prefix.contains("staff") || prefix.contains("maintenance") || prefix.contains("caretaker")) {
                user.setRole(UserRole.STAFF);
            } else {
                // Default based on domain
                user.setRole(email.endsWith("@smail.iitm.ac.in") ? UserRole.STUDENT : UserRole.STAFF);
            }

            user = userRepository.save(user);
        }

        return createLoginResponse(user);
    }

    private LoginResponse createLoginResponse(AppUser user) {
        Instant now = Instant.now();
        JwtClaimsSet claims = JwtClaimsSet.builder()
                .issuer("brahmaputra-hostel")
                .subject(user.getUsername())
                .issuedAt(now)
                .expiresAt(now.plus(tokenLifetime))
                .claim(SecurityConfig.ROLE_CLAIM, user.getRole().name())
                .build();
        JwsHeader header = JwsHeader.with(MacAlgorithm.HS256).build();
        String token = jwtEncoder.encode(JwtEncoderParameters.from(header, claims)).getTokenValue();
        return new LoginResponse(token, now.plus(tokenLifetime).toString(), UserDto.from(user));
    }
}
