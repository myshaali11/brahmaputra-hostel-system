package com.iitm.hostel.service;

import io.github.bucket4j.ConsumptionProbe;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class RateLimitingServiceTest {

    private RateLimitingService rateLimitingService;

    @BeforeEach
    void setUp() {
        rateLimitingService = new RateLimitingService();
    }

    @Test
    @DisplayName("Login endpoint allows up to 5 attempts per minute per IP and rejects the 6th")
    void testLoginRateLimit() {
        String testIp = "192.168.1.100";

        for (int i = 1; i <= 5; i++) {
            ConsumptionProbe probe = rateLimitingService.checkLoginRateLimit(testIp);
            assertTrue(probe.isConsumed(), "Attempt " + i + " should be allowed");
            assertEquals(5 - i, probe.getRemainingTokens(), "Remaining tokens should match");
        }

        // 6th attempt must be rejected
        ConsumptionProbe rejectedProbe = rateLimitingService.checkLoginRateLimit(testIp);
        assertFalse(rejectedProbe.isConsumed(), "6th attempt should be rejected");
        assertEquals(0, rejectedProbe.getRemainingTokens());
        assertTrue(rejectedProbe.getNanosToWaitForRefill() > 0, "Wait time should be positive");

        // A different IP should have its own separate bucket
        ConsumptionProbe differentIpProbe = rateLimitingService.checkLoginRateLimit("192.168.1.101");
        assertTrue(differentIpProbe.isConsumed(), "Different IP should have independent capacity");
        assertEquals(4, differentIpProbe.getRemainingTokens());
    }

    @Test
    @DisplayName("User API allows up to 60 requests per minute per user and rejects the 61st")
    void testUserApiRateLimit() {
        String username = "student_test_user";

        for (int i = 1; i <= 60; i++) {
            ConsumptionProbe probe = rateLimitingService.checkUserApiRateLimit(username);
            assertTrue(probe.isConsumed(), "Request " + i + " should be allowed");
        }

        // 61st request must be rejected
        ConsumptionProbe rejectedProbe = rateLimitingService.checkUserApiRateLimit(username);
        assertFalse(rejectedProbe.isConsumed(), "61st request should be rejected");
        assertEquals(0, rejectedProbe.getRemainingTokens());

        // A different user should not be affected
        ConsumptionProbe otherUserProbe = rateLimitingService.checkUserApiRateLimit("manager_user");
        assertTrue(otherUserProbe.isConsumed(), "Different user should have independent capacity");
    }

    @Test
    @DisplayName("Complaint creation allows up to 5 submissions per 10 minutes and rejects the 6th")
    void testComplaintRateLimit() {
        String username = "student_complainer";

        for (int i = 1; i <= 5; i++) {
            ConsumptionProbe probe = rateLimitingService.checkComplaintRateLimit(username);
            assertTrue(probe.isConsumed(), "Complaint submission " + i + " should be allowed");
        }

        // 6th complaint must be rejected
        ConsumptionProbe rejectedProbe = rateLimitingService.checkComplaintRateLimit(username);
        assertFalse(rejectedProbe.isConsumed(), "6th complaint submission should be blocked");
        assertEquals(0, rejectedProbe.getRemainingTokens());
    }
}
