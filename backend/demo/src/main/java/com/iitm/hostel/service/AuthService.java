package com.iitm.hostel.service;

import com.iitm.hostel.config.SecurityConfig;
import com.iitm.hostel.dto.LoginRequest;
import com.iitm.hostel.dto.LoginResponse;
import com.iitm.hostel.dto.UserDto;
import com.iitm.hostel.exception.UnauthorizedException;
import com.iitm.hostel.model.AppUser;
import com.iitm.hostel.repository.AppUserRepository;
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

/** Verifies credentials and issues signed JWTs. */
@Service
@Transactional(readOnly = true)
public class AuthService {

    private final AppUserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtEncoder jwtEncoder;
    private final Duration tokenLifetime;

    public AuthService(AppUserRepository userRepository, PasswordEncoder passwordEncoder, JwtEncoder jwtEncoder,
                       @Value("${app.jwt.expiry-hours:12}") long expiryHours) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtEncoder = jwtEncoder;
        this.tokenLifetime = Duration.ofHours(expiryHours);
    }

    public LoginResponse login(LoginRequest request) {
        AppUser user = userRepository.findByUsername(request.username().trim())
                .filter(u -> passwordEncoder.matches(request.password(), u.getPasswordHash()))
                // Same message for unknown user and wrong password, so usernames can't be probed.
                .orElseThrow(() -> new UnauthorizedException("Invalid username or password"));

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
