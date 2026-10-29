package com.iitm.hostel.controller;

import com.iitm.hostel.dto.GoogleLoginRequest;
import com.iitm.hostel.dto.LoginRequest;
import com.iitm.hostel.dto.LoginResponse;
import com.iitm.hostel.service.AuthService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/login")
    public LoginResponse login(@Valid @RequestBody LoginRequest request) {
        return authService.login(request);
    }

    @PostMapping("/google")
    public LoginResponse googleLogin(@Valid @RequestBody GoogleLoginRequest request) {
        return authService.loginWithGoogle(request);
    }
}
