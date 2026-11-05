package com.iitm.hostel.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

import java.util.Map;

@Service
public class AiAnalyticsService {

    private static final Logger log = LoggerFactory.getLogger(AiAnalyticsService.class);
    private final RestClient restClient;

    public record AiTriageResult(
            String predictedCategory,
            String predictedPriority,
            Double confidence,
            String recommendation,
            Boolean isHazard
    ) {}

    public AiAnalyticsService(@Value("${app.ai.service-url:http://localhost:5001}") String aiServiceUrl) {
        this.restClient = RestClient.builder()
                .baseUrl(aiServiceUrl)
                .build();
    }

    /**
     * Calls the Python AI microservice to triage the complaint.
     * If the microservice is offline, gracefully falls back without failing the ticket creation.
     */
    public AiTriageResult analyzeComplaint(String title, String description, String assetName) {
        try {
            Map<String, String> request = Map.of(
                    "title", title != null ? title : "",
                    "description", description != null ? description : "",
                    "assetName", assetName != null ? assetName : ""
            );

            return restClient.post()
                    .uri("/api/ai/triage")
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(request)
                    .retrieve()
                    .body(AiTriageResult.class);
        } catch (Exception ex) {
            log.warn("AI service unreachable or returned error: {}. Proceeding with default heuristic triage.", ex.getMessage());
            return fallbackHeuristic(title, description);
        }
    }

    /**
     * Built-in Java heuristic fallback if the Python AI service is not running.
     */
    private AiTriageResult fallbackHeuristic(String title, String desc) {
        String combined = ((title != null ? title : "") + " " + (desc != null ? desc : "")).toLowerCase();

        String category = "GENERAL";
        String priority = "MEDIUM";
        boolean isHazard = false;

        if (combined.contains("spark") || combined.contains("smoke") || combined.contains("shock") || combined.contains("short circuit")) {
            category = "ELECTRICAL";
            priority = "URGENT";
            isHazard = true;
        } else if (combined.contains("fan") || combined.contains("light") || combined.contains("plug") || combined.contains("switch") || combined.contains("wire")) {
            category = "ELECTRICAL";
        } else if (combined.contains("tap") || combined.contains("pipe") || combined.contains("leak") || combined.contains("flush") || combined.contains("water") || combined.contains("drain")) {
            category = "PLUMBING";
        } else if (combined.contains("cot") || combined.contains("bed") || combined.contains("table") || combined.contains("chair") || combined.contains("door") || combined.contains("wood")) {
            category = "CARPENTRY";
        } else if (combined.contains("clean") || combined.contains("dust") || combined.contains("garbage") || combined.contains("waste")) {
            category = "CLEANING";
            priority = "LOW";
        }

        String rec = isHazard
                ? "🚨 High Hazard Risk: Isolate breaker line and dispatch electrician immediately."
                : "Heuristic Triage: Route to " + category.toLowerCase() + " team.";

        return new AiTriageResult(category, priority, 0.75, rec, isHazard);
    }
}
