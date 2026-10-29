package com.iitm.hostel.service;

import com.github.benmanes.caffeine.cache.Cache;
import com.github.benmanes.caffeine.cache.Caffeine;
import io.github.bucket4j.Bandwidth;
import io.github.bucket4j.Bucket;
import io.github.bucket4j.ConsumptionProbe;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.util.concurrent.TimeUnit;

/**
 * In-memory rate limiting service using Bucket4j backed by Caffeine caches.
 *
 * <p>Implements the Token Bucket algorithm across three distinct tiers:
 * <ul>
 *   <li><b>Login tier:</b> 5 requests / minute per client IP (protects BCrypt from CPU exhaustion).</li>
 *   <li><b>User API tier:</b> 60 requests / minute per authenticated user token.</li>
 *   <li><b>Complaint tier:</b> 5 submissions / 10 minutes per authenticated user (prevents DB flooding).</li>
 * </ul>
 *
 * Inactive IP/user buckets are automatically evicted by Caffeine to avoid unbounded memory growth.
 */
@Service
public class RateLimitingService {

    // 1. /api/auth/login: 5 requests / minute per IP
    private final Cache<String, Bucket> loginBuckets = Caffeine.newBuilder()
            .expireAfterAccess(15, TimeUnit.MINUTES)
            .maximumSize(50_000)
            .build();

    // 2. /api/**: 60 requests / minute per user token
    private final Cache<String, Bucket> userApiBuckets = Caffeine.newBuilder()
            .expireAfterAccess(15, TimeUnit.MINUTES)
            .maximumSize(20_000)
            .build();

    // 3. POST /api/complaints: 5 submissions / 10 minutes per user
    private final Cache<String, Bucket> complaintBuckets = Caffeine.newBuilder()
            .expireAfterAccess(30, TimeUnit.MINUTES)
            .maximumSize(20_000)
            .build();

    /**
     * Checks if the given client IP has capacity to attempt a login.
     * Consumes 1 token if available.
     */
    public ConsumptionProbe checkLoginRateLimit(String clientIp) {
        Bucket bucket = loginBuckets.get(clientIp, key -> createLoginBucket());
        return bucket.tryConsumeAndReturnRemaining(1);
    }

    /**
     * Checks if the given authenticated user has capacity for a general API call.
     * Consumes 1 token if available.
     */
    public ConsumptionProbe checkUserApiRateLimit(String username) {
        Bucket bucket = userApiBuckets.get(username, key -> createUserApiBucket());
        return bucket.tryConsumeAndReturnRemaining(1);
    }

    /**
     * Checks if the given authenticated user has capacity to submit a new complaint.
     * Consumes 1 token if available.
     */
    public ConsumptionProbe checkComplaintRateLimit(String username) {
        Bucket bucket = complaintBuckets.get(username, key -> createComplaintBucket());
        return bucket.tryConsumeAndReturnRemaining(1);
    }

    private Bucket createLoginBucket() {
        Bandwidth limit = Bandwidth.builder()
                .capacity(5)
                .refillGreedy(5, Duration.ofMinutes(1))
                .build();
        return Bucket.builder().addLimit(limit).build();
    }

    private Bucket createUserApiBucket() {
        Bandwidth limit = Bandwidth.builder()
                .capacity(60)
                .refillGreedy(60, Duration.ofMinutes(1))
                .build();
        return Bucket.builder().addLimit(limit).build();
    }

    private Bucket createComplaintBucket() {
        Bandwidth limit = Bandwidth.builder()
                .capacity(5)
                .refillGreedy(5, Duration.ofMinutes(10))
                .build();
        return Bucket.builder().addLimit(limit).build();
    }
}
