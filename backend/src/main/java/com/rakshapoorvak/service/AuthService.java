package com.rakshapoorvak.service;

import com.rakshapoorvak.exception.BadRequestException;
import com.rakshapoorvak.exception.UnauthorizedException;
import com.rakshapoorvak.model.dto.auth.AuthResponse;
import com.rakshapoorvak.model.dto.auth.LoginRequest;
import com.rakshapoorvak.model.dto.auth.RefreshRequest;
import com.rakshapoorvak.model.dto.auth.RegisterRequest;
import com.rakshapoorvak.model.dto.user.UserSummaryDto;
import com.rakshapoorvak.model.entity.RefreshToken;
import com.rakshapoorvak.model.entity.Role;
import com.rakshapoorvak.model.entity.User;
import com.rakshapoorvak.model.entity.enums.RoleName;
import com.rakshapoorvak.repository.RefreshTokenRepository;
import com.rakshapoorvak.repository.RoleRepository;
import com.rakshapoorvak.repository.UserRepository;
import com.rakshapoorvak.security.JwtUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Instant;
import java.util.HashSet;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Authentication service - login, register, refresh.
 */
@Service
public class AuthService {

    private static final Logger log = LoggerFactory.getLogger(AuthService.class);

    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;
    private final AuthenticationManager authenticationManager;
    private final UserDetailsService userDetailsService;

    public AuthService(UserRepository userRepository, RoleRepository roleRepository,
                       RefreshTokenRepository refreshTokenRepository, PasswordEncoder passwordEncoder,
                       JwtUtil jwtUtil, AuthenticationManager authenticationManager,
                       UserDetailsService userDetailsService) {
        this.userRepository = userRepository;
        this.roleRepository = roleRepository;
        this.refreshTokenRepository = refreshTokenRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtUtil = jwtUtil;
        this.authenticationManager = authenticationManager;
        this.userDetailsService = userDetailsService;
    }

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        log.info("Registering user: {}", request.getEmail());
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new BadRequestException("Email already registered");
        }

        Set<Role> roles = resolveRoles(request.getRoles());
        User user = User.builder()
                .email(request.getEmail())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .fullName(request.getFullName())
                .phone(request.getPhone())
                .roles(roles)
                .build();
        user = userRepository.save(user);
        log.info("User registered: id={}", user.getId());

        return buildAuthResponse(user);
    }

    public AuthResponse login(LoginRequest request) {
        log.info("Login attempt: {}", request.getEmail());
        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.getEmail(), request.getPassword())
        );

        User user = userRepository.findByEmailWithRoles(request.getEmail())
                .orElseThrow(() -> new UnauthorizedException("User not found"));
        log.info("User logged in: id={}", user.getId());

        return buildAuthResponse(user);
    }

    public AuthResponse refresh(RefreshRequest request) {
        String tokenHash = hashToken(request.getRefreshToken());
        RefreshToken rt = refreshTokenRepository.findByTokenHash(tokenHash)
                .orElseThrow(() -> new UnauthorizedException("Invalid refresh token"));

        if (rt.getExpiresAt().isBefore(Instant.now())) {
            refreshTokenRepository.delete(rt);
            throw new UnauthorizedException("Refresh token expired");
        }

        User user = userRepository.findByIdWithRoles(rt.getUser().getId())
                .orElseThrow(() -> new UnauthorizedException("User not found"));
        return buildAuthResponse(user);
    }

    public UserSummaryDto getCurrentUser(String email) {
        User user = userRepository.findByEmailWithRoles(email)
                .orElseThrow(() -> new UnauthorizedException("User not found"));
        return toUserSummary(user);
    }

    private AuthResponse buildAuthResponse(User user) {
        UserDetails userDetails = userDetailsService.loadUserByUsername(user.getEmail());
        String accessToken = jwtUtil.generateAccessToken(userDetails);
        String refreshToken = jwtUtil.generateRefreshToken(user.getEmail());

        RefreshToken rt = RefreshToken.builder()
                .user(user)
                .tokenHash(hashToken(refreshToken))
                .expiresAt(Instant.now().plusMillis(7 * 24 * 60 * 60 * 1000L))
                .build();
        refreshTokenRepository.save(rt);

        return AuthResponse.builder()
                .accessToken(accessToken)
                .refreshToken(refreshToken)
                .expiresIn(jwtUtil.getAccessExpirationMs())
                .user(toUserSummary(user))
                .build();
    }

    private Set<Role> resolveRoles(Set<String> roleNames) {
        if (roleNames == null || roleNames.isEmpty()) {
            roleNames = Set.of("USER");
        }
        Set<Role> roles = new HashSet<>();
        for (String name : roleNames) {
            try {
                RoleName rn = RoleName.valueOf(name.toUpperCase());
                roleRepository.findByName(rn).ifPresent(roles::add);
            } catch (IllegalArgumentException ignored) {
                // skip invalid role names
            }
        }
        if (roles.isEmpty()) {
            roleRepository.findByName(RoleName.USER).ifPresent(roles::add);
        }
        return roles;
    }

    private String hashToken(String token) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] hash = md.digest(token.getBytes(StandardCharsets.UTF_8));
            StringBuilder sb = new StringBuilder();
            for (byte b : hash) sb.append(String.format("%02x", b));
            return sb.toString();
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException("SHA-256 not available", e);
        }
    }

    private UserSummaryDto toUserSummary(User user) {
        return UserSummaryDto.builder()
                .id(user.getId())
                .email(user.getEmail())
                .fullName(user.getFullName())
                .phone(user.getPhone())
                .roles(user.getRoles().stream()
                        .map(r -> r.getName().name())
                        .collect(Collectors.toSet()))
                .build();
    }
}
