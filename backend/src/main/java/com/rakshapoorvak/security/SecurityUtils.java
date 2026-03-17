package com.rakshapoorvak.security;

import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.Optional;

/**
 * Helper to get current user from SecurityContext.
 */
public final class SecurityUtils {

    private SecurityUtils() {
    }

    public static Optional<String> getCurrentUserEmail() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.isAuthenticated() && auth.getPrincipal() != null
                && !(auth.getPrincipal() instanceof String && "anonymousUser".equals(auth.getPrincipal()))) {
            if (auth.getPrincipal() instanceof org.springframework.security.core.userdetails.UserDetails ud) {
                return Optional.of(ud.getUsername());
            }
        }
        return Optional.empty();
    }

    public static String getCurrentUserEmailOrThrow() {
        return getCurrentUserEmail()
                .orElseThrow(() -> new com.rakshapoorvak.exception.UnauthorizedException("Not authenticated"));
    }
}
