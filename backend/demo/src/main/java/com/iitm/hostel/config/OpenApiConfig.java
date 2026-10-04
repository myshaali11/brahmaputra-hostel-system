package com.iitm.hostel.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI hostelApiInfo() {
        return new OpenAPI().info(new Info()
                .title("IITM Hostel Asset & Complaint Management API")
                .description("Backend for the hostel asset inspection, routine checklist and complaint tracking system.")
                .version("v2.0"));
    }
}
