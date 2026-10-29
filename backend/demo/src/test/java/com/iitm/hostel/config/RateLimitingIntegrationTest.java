package com.iitm.hostel.config;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.web.servlet.MockMvc;

import static org.hamcrest.Matchers.containsString;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_EACH_TEST_METHOD)
class RateLimitingIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    @DisplayName("POST /api/auth/login triggers HTTP 429 Too Many Requests after 5 attempts from same IP")
    void testLoginEndpointRateLimiting() throws Exception {
        String loginJson = "{\"username\":\"unknown\",\"password\":\"wrongpass\"}";
        String clientIp = "10.0.0.50";

        // Attempts 1 to 5 should pass through the rate limiter (returning 401 Unauthorized because credentials are bad)
        for (int i = 1; i <= 5; i++) {
            mockMvc.perform(post("/api/auth/login")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(loginJson)
                            .with(request -> {
                                request.setRemoteAddr(clientIp);
                                return request;
                            }))
                    .andExpect(status().isUnauthorized())
                    .andExpect(header().exists("X-Rate-Limit-Remaining"));
        }

        // 6th attempt from the same IP must be rejected with 429 Too Many Requests
        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(loginJson)
                        .with(request -> {
                            request.setRemoteAddr(clientIp);
                            return request;
                        }))
                .andExpect(status().isTooManyRequests())
                .andExpect(header().string("X-Rate-Limit-Remaining", "0"))
                .andExpect(header().exists("Retry-After"))
                .andExpect(header().exists("X-Rate-Limit-Retry-After-Seconds"))
                .andExpect(jsonPath("$.status").value(429))
                .andExpect(jsonPath("$.error").value("Too Many Requests"))
                .andExpect(jsonPath("$.message", containsString("Too many login attempts")));

        // A different IP address should still succeed (returning 401, not 429)
        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(loginJson)
                        .with(request -> {
                            request.setRemoteAddr("10.0.0.99");
                            return request;
                        }))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @DisplayName("POST /api/complaints triggers HTTP 429 after 5 submissions within 10 minutes")
    @WithMockUser(username = "test_student", roles = {"STUDENT"})
    void testComplaintCreationRateLimiting() throws Exception {
        String complaintJson = "{\"hostelId\":1,\"floorId\":1,\"locationId\":1,\"category\":\"ELECTRICAL\",\"title\":\"Fan broken\",\"description\":\"Not spinning\"}";

        // Submissions 1 through 5 should proceed (they might fail validation/database or return 201/400/404, but NOT 429)
        for (int i = 1; i <= 5; i++) {
            final int attempt = i;
            mockMvc.perform(post("/api/complaints")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(complaintJson))
                    .andExpect(result -> {
                        int status = result.getResponse().getStatus();
                        org.junit.jupiter.api.Assertions.assertNotEquals(429, status, "Request " + attempt + " should not be rate-limited");
                    });
        }

        // 6th submission must be rejected with HTTP 429
        mockMvc.perform(post("/api/complaints")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(complaintJson))
                .andExpect(status().isTooManyRequests())
                .andExpect(jsonPath("$.status").value(429))
                .andExpect(jsonPath("$.message", containsString("Complaint submission limit reached")));
    }

    @Test
    @DisplayName("Authenticated /api/** triggers HTTP 429 after exceeding 60 requests in a minute")
    @WithMockUser(username = "heavy_api_user", roles = {"MANAGER"})
    void testGeneralApiRateLimiting() throws Exception {
        // Perform 60 requests
        for (int i = 1; i <= 60; i++) {
            mockMvc.perform(get("/api/complaints"))
                    .andExpect(status().isOk());
        }

        // 61st request must return 429
        mockMvc.perform(get("/api/complaints"))
                .andExpect(status().isTooManyRequests())
                .andExpect(header().string("X-Rate-Limit-Remaining", "0"))
                .andExpect(header().exists("Retry-After"))
                .andExpect(jsonPath("$.status").value(429))
                .andExpect(jsonPath("$.message", containsString("API rate limit exceeded")));
    }
}
