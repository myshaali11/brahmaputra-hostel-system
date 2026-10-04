package com.iitm.hostel.service;

import com.iitm.hostel.exception.UnauthorizedException;
import com.iitm.hostel.model.AppUser;
import com.iitm.hostel.repository.AppUserRepository;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

/**
 * Resolves the signed-in {@link AppUser} from the JWT on the current request.
 * Used for attribution ("who inspected / reported / resolved this") so the
 * client can no longer spoof a name in the request body.
 */
@Component
public class CurrentUser {

    private final AppUserRepository userRepository;

    public CurrentUser(AppUserRepository userRepository) {
        this.userRepository = userRepository;
    }

    public AppUser get() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !auth.isAuthenticated() || auth.getName() == null) {
            throw new UnauthorizedException("Not signed in");
        }
        return userRepository.findByUsername(auth.getName())
                .orElseThrow(() -> new UnauthorizedException("Account no longer exists"));
    }
}
