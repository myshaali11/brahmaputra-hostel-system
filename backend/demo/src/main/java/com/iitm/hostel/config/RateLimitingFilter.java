package com.iitm.hostel.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.iitm.hostel.service.RateLimitingService;
import io.github.bucket4j.ConsumptionProbe;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.concurrent.TimeUnit;

/**
 * Filter that applies Bucket4j token bucket rate limiting:
 * 1. POST /api/auth/login: 5 req/min per IP
 * 2. POST /api/complaints: 5 submissions/10 min per user token
 * 3. /api/**: 60 req/min per user token
 *
 * Runs inside Spring Security filter chain right before AuthorizationFilter so that
 * Bearer tokens are already parsed and authenticated.
 */
public class RateLimitingFilter extends OncePerRequestFilter {

    private final RateLimitingService rateLimitingService;
    private final ObjectMapper objectMapper;

    public RateLimitingFilter(RateLimitingService rateLimitingService, ObjectMapper objectMapper) {
        this.rateLimitingService = rateLimitingService;
        this.objectMapper = objectMapper;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {

        // Never rate-limit CORS preflight requests
        if ("OPTIONS".equalsIgnoreCase(request.getMethod())) {
            filterChain.doFilter(request, response);
            return;
        }

        String path = request.getRequestURI();

        // 1. Login endpoint rate limiting by IP (5 requests / minute)
        if (isLoginEndpoint(path)) {
            String clientIp = extractClientIp(request);
            ConsumptionProbe probe = rateLimitingService.checkLoginRateLimit(clientIp);
            if (!probe.isConsumed()) {
                sendRateLimitExceededResponse(
                        response,
                        probe,
                        "Too many login attempts from this IP. Please try again in " + toSeconds(probe) + " seconds."
                );
                return;
            }
            addRateLimitHeaders(response, probe);
            filterChain.doFilter(request, response);
            return;
        }

        // 2. Authenticated API endpoints under /api/**
        if (path.startsWith("/api/")) {
            Authentication authentication = SecurityContextHolder.getContext().getAuthentication();

            if (authentication != null && authentication.isAuthenticated() && !"anonymousUser".equals(authentication.getName())) {
                String username = authentication.getName();

                // 2a. POST /api/complaints -> 5 submissions / 10 minutes
                if (isComplaintCreation(request, path)) {
                    ConsumptionProbe complaintProbe = rateLimitingService.checkComplaintRateLimit(username);
                    if (!complaintProbe.isConsumed()) {
                        sendRateLimitExceededResponse(
                                response,
                                complaintProbe,
                                "Complaint submission limit reached. Maximum 5 complaints every 10 minutes. Try again in "
                                        + toSeconds(complaintProbe) + " seconds."
                        );
                        return;
                    }
                }

                // 2b. General /api/** -> 60 requests / minute
                ConsumptionProbe userProbe = rateLimitingService.checkUserApiRateLimit(username);
                if (!userProbe.isConsumed()) {
                    sendRateLimitExceededResponse(
                            response,
                            userProbe,
                            "API rate limit exceeded. Maximum 60 requests per minute allowed. Try again in "
                                    + toSeconds(userProbe) + " seconds."
                    );
                    return;
                }
                addRateLimitHeaders(response, userProbe);
            }
        }

        filterChain.doFilter(request, response);
    }

    private boolean isLoginEndpoint(String path) {
        return "/api/auth/login".equals(path) || "/api/auth/login/".equals(path);
    }

    private boolean isComplaintCreation(HttpServletRequest request, String path) {
        return "POST".equalsIgnoreCase(request.getMethod())
                && ("/api/complaints".equals(path) || "/api/complaints/".equals(path));
    }

    private String extractClientIp(HttpServletRequest request) {
        String xForwardedFor = request.getHeader("X-Forwarded-For");
        if (xForwardedFor != null && !xForwardedFor.isBlank()) {
            return xForwardedFor.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }

    private long toSeconds(ConsumptionProbe probe) {
        return Math.max(1, TimeUnit.NANOSECONDS.toSeconds(probe.getNanosToWaitForRefill()));
    }

    private void addRateLimitHeaders(HttpServletResponse response, ConsumptionProbe probe) {
        response.setHeader("X-Rate-Limit-Remaining", String.valueOf(probe.getRemainingTokens()));
    }

    private void sendRateLimitExceededResponse(HttpServletResponse response, ConsumptionProbe probe, String message)
            throws IOException {
        long retryAfterSeconds = toSeconds(probe);

        response.setStatus(HttpStatus.TOO_MANY_REQUESTS.value());
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        response.setHeader("Retry-After", String.valueOf(retryAfterSeconds));
        response.setHeader("X-Rate-Limit-Remaining", "0");
        response.setHeader("X-Rate-Limit-Retry-After-Seconds", String.valueOf(retryAfterSeconds));

        Map<String, Object> errorBody = new LinkedHashMap<>();
        errorBody.put("timestamp", LocalDateTime.now().toString());
        errorBody.put("status", HttpStatus.TOO_MANY_REQUESTS.value());
        errorBody.put("error", HttpStatus.TOO_MANY_REQUESTS.getReasonPhrase());
        errorBody.put("message", message);
        errorBody.put("retryAfterSeconds", retryAfterSeconds);

        response.getWriter().write(objectMapper.writeValueAsString(errorBody));
    }
}
