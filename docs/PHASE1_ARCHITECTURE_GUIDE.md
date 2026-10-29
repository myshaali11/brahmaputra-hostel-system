# Brahmaputra Hostel Management System — Phase 1 Architecture Guide

> **Reference Diagram:** [Phase1_ArchitectureFlow.jpeg](file:///d:/IITM/PAI/PAI_project/project_repo/Phase1_ArchitectureFlow.jpeg)  
> **Course:** CS5013 — Programming with AI (PAI)  
> **Team:** Team 16 · Akhilesh K.R (CS26E001) & Mysha Ali (CS26E008)  
> **Repository:** `myshaali11/brahmaputra-hostel-system`

---

## Table of Contents
1. [High-Level Architecture at a Glance](#1-high-level-architecture-at-a-glance)
2. [Layman's Analogy: The High-Security Hotel](#2-laymans-analogy-the-high-security-hotel)
3. [What is JWT? (Layman & Technical Explanation)](#3-what-is-jwt-layman--technical-explanation)
4. [How Spring Boot Implements This (Architecture & Pipeline)](#4-how-spring-boot-implements-this-architecture--pipeline)
5. [Deep Dive into the 6 Architecture Steps](#5-deep-dive-into-the-6-architecture-steps)
   - [Step 1: User / Flutter App or Swagger](#step-1-user--flutter-app-or-swagger)
   - [Step 2: REST API (Spring Boot Engine)](#step-2-rest-api-spring-boot-engine)
   - [Step 3: Authentication & Authorization (The Security Gate)](#step-3-authentication--authorization-the-security-gate)
   - [Step 4: Controller → Service → Repository (The Core Engine)](#step-4-controller--service--repository-the-core-engine)
   - [Step 5: Database Layer (PostgreSQL & H2 In-Memory)](#step-5-database-layer-postgresql--h2-in-memory)
   - [Step 6: JSON Response & Global Error Handling](#step-6-json-response--global-error-handling)
6. [Complete Swagger UI Live Demo Script](#6-complete-swagger-ui-live-demo-script)
7. [Comprehensive Codebase Directory Map](#7-comprehensive-codebase-directory-map)

---

## 1. High-Level Architecture at a Glance

The architecture flow represents the full round-trip journey of a client's request from the user interface down to the database and back:

```mermaid
flowchart LR
    A["1. Client\n(Flutter / Swagger)"] -->|"HTTP JSON"| B["2. Spring Boot\nREST API (:8080)"]
    B -->|"Filter Interception"| C["3. Security\n(JWT & Roles)"]
    C -->|"Authorized Dispatch"| D["4. Business Layer\n(Ctrl ➔ Svc ➔ Repo)"]
    D -->|"SQL / JPA"| E["5. Database\n(H2 / PostgreSQL)"]
    E -->|"Entities"| D
    D -->|"DTO / Error"| F["6. JSON Response\n(Jackson / Advice)"]
    F -->|"200 OK / 4xx"| A
```

| Step | Architecture Box | Primary Responsibility | Key Code Files |
| :--- | :--- | :--- | :--- |
| **1** | **User / Flutter App or Swagger** | Client interaction for Manager, Staff, and Students | [OpenApiConfig.java](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/java/com/iitm/hostel/config/OpenApiConfig.java), `frontend/` |
| **2** | **REST API (Spring Boot)** | HTTP reception, port binding, CORS, CSRF configuration | [HostelApplication.java](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/java/com/iitm/hostel/HostelApplication.java), [application.properties](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/resources/application.properties) |
| **3** | **Authentication & Authorization** | Credential checks, JWT signing, signature verification, RBAC rules | [SecurityConfig.java](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/java/com/iitm/hostel/config/SecurityConfig.java), [AuthService.java](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/java/com/iitm/hostel/service/AuthService.java), [CurrentUser.java](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/java/com/iitm/hostel/service/CurrentUser.java) |
| **4** | **Controller → Service → Repository** | Request routing, business validations, complaint-asset state machine | [ComplaintService.java](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/java/com/iitm/hostel/service/ComplaintService.java), [LocationService.java](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/java/com/iitm/hostel/service/LocationService.java), Controllers |
| **5** | **PostgreSQL / H2 Database** | Persistent relational storage of hostels, rooms, assets, users, tickets | [DataSeeder.java](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/java/com/iitm/hostel/config/DataSeeder.java), [import_dataset.py](file:///d:/IITM/PAI/PAI_project/project_repo/database/import_dataset.py), JPA Entities |
| **6** | **JSON Response** | Standardized serialised output and unified error bodies | [GlobalExceptionHandler.java](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/java/com/iitm/hostel/exception/GlobalExceptionHandler.java), DTO records |

---

## 2. Layman's Analogy: The High-Security Hotel

To explain this simply during an evaluation, use the **Hotel Resort Analogy**:

1. **Step 1 (The Guests):** Guests arrive at a hotel. Some are Hotel Owners (**Managers**), some are Housekeeping (**Staff**), and some are Resident Guests (**Students**). They enter through the mobile app or the front desk terminal (**Swagger UI**).
2. **Step 2 (The Front Doors):** The revolving entrance of the hotel (**Spring Boot REST API**). It greets everyone, ensures visitors use the correct entrance doors, and provides basic entry instructions (**CORS**).
3. **Step 3 (Reception & Security Guards):**
   - **Login (Reception):** You show your ID and password. Reception verifies you in the ledger and gives you a tamper-proof digital wristband (**JWT Token**).
   - **The Guards (Security Filter):** Every elevator and corridor has an armed security guard (**SecurityFilterChain**). You cannot enter the VIP Penthouse (**Manager Dashboard**) if your wristband says "Resident Guest" (**Student**). The guard scans your wristband before you take a single step forward.
4. **Step 4 (Hotel Departments):**
   - **Concierge (Controller):** Directs you to the right department based on what you asked for.
   - **Operations Staff (Service):** Does the actual work. For instance, if you report a broken ceiling fan, the service marks that fan as "BROKEN" and automatically assigns a repair ticket.
   - **Filing Clerk (Repository):** Retrieves files from the records room.
5. **Step 5 (The Archive Vault):**
   - The master record books (**Database**). In everyday live demo mode, it uses a quick whiteboard ledger (**H2 In-Memory Database**). In full production, it uses a heavy steel underground vault (**PostgreSQL**).
6. **Step 6 (The Printed Receipt):**
   - Whatever department you spoke with hands you a clear, printed confirmation slip (**JSON Response**). If something went wrong, they hand you a standardized incident report explaining the problem (**Global Exception Handler**).

---

## 3. What is JWT? (Layman & Technical Explanation)

### The Layman Explanation
A **JWT (JSON Web Token)** is like a digital, stamped concert wristband.
- In traditional web applications (session cookies), the server keeps a giant list in its memory of every single user logged in. If 10,000 students log in, the server's RAM gets clogged.
- With a JWT, the server signs a small digital token and hands it to you. You carry it in your pocket. Whenever you ask for something, you flash the wristband. The server verifies the signature with its secret stamp. It does not need to store your session in its memory.

### The Technical Structure
A JWT is a string of three Base64URL-encoded parts joined by dots (`.`):
$$\mathbf{Header} \;.\; \mathbf{Payload} \;.\; \mathbf{Signature}$$

```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhZG1pbiIsInJvbGUiOiJNQU5BR0VSIiwiZXhwIjoxNzU3ODI5NjAwfQ.dBjftJeZ4C...
```

1. **Header:** Defines the cryptographic algorithm:
   ```json
   { "alg": "HS256", "typ": "JWT" }
   ```
2. **Payload (The Claims):** Contains user details and role permissions:
   ```json
   {
     "iss": "brahmaputra-hostel",
     "sub": "admin",
     "role": "MANAGER",
     "iat": 1757743200,
     "exp": 1757829600
   }
   ```
3. **Signature:** The mathematical proof that guarantees integrity:
   $$\text{Signature} = \text{HMAC-SHA256}(\text{Base64Url}(\text{Header}) + "." + \text{Base64Url}(\text{Payload}), \text{SecretKey})$$

> **Why Can't a Student Fake Being a Manager?**  
> If `student1` edits their token payload to say `"role": "MANAGER"`, the signature calculation will fail because the student does not know the server's secret key (`app.jwt.secret` in [application.properties](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/resources/application.properties#L28)). Spring Boot detects the signature mismatch and immediately rejects the request with an HTTP **401 Unauthorized**.

---

## 4. How Spring Boot Implements This (Architecture & Pipeline)

### The Golden Rule: Filters Run *Before* Controllers

A frequent misconception is that `@RestController` handles authentication. In Spring Boot:

$$\text{HTTP Request} \longrightarrow \mathbf{SecurityFilterChain} \text{ (Filter Layer)} \longrightarrow \mathbf{DispatcherServlet} \longrightarrow \mathbf{@RestController} \longrightarrow \mathbf{@Service}$$

If an unauthenticated or unauthorized request arrives, it is blocked inside the **Filter Layer**. The `@RestController` code is **never called**.

### Architectural Breakdown of Spring Boot Components

1. **`@SpringBootApplication` ([HostelApplication.java](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/java/com/iitm/hostel/HostelApplication.java)):**  
   The bootstrap runner. Initializes the Spring IoC container and starts Tomcat on port 8080.
2. **`@Configuration` & `@Bean` ([SecurityConfig.java](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/java/com/iitm/hostel/config/SecurityConfig.java)):**  
   Configures the security filter chain, password encoders, and token signers into Spring's ApplicationContext.
3. **`@RestController` & `@RequestMapping` (Controllers):**  
   Exposes HTTP endpoints and deserializes incoming JSON payloads into Java request objects.
4. **`@Service` & `@Transactional` (Services):**  
   Houses pure business logic and manages database transactions (ensuring all SQL operations either succeed together or rollback).
5. **`@Repository` (Repositories):**  
   Extends Spring Data `JpaRepository<Entity, ID>` to provide CRUD and custom query methods without writing manual SQL.
6. **`@Entity` & `@Table` (Models):**  
   Java classes mapped directly to database tables using Hibernate / JPA.
7. **`@RestControllerAdvice` ([GlobalExceptionHandler.java](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/java/com/iitm/hostel/exception/GlobalExceptionHandler.java)):**  
   A global interceptor that catches any uncaught runtime exceptions and transforms them into clean JSON error bodies.

---

## 5. Deep Dive into the 6 Architecture Steps

### Step 1: User / Flutter App or Swagger

#### What it does:
Serves as the interactive client layer for all three user personas:
- **Manager:** Uses Swagger or the web dashboard to inspect hostel health and allocate assets.
- **Housekeeping Staff:** Uses the mobile app to execute room checklists and vacancy walkthroughs.
- **Student:** Uses the mobile app to view their allocated room fixtures and raise repair complaints.

#### Codebase Connection:
* **Swagger UI Configuration:** [OpenApiConfig.java](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/java/com/iitm/hostel/config/OpenApiConfig.java#L12-L31)
  ```java
  @Configuration
  public class OpenApiConfig {
      private static final String SECURITY_SCHEME_NAME = "BearerAuth";

      @Bean
      public OpenAPI hostelApiInfo() {
          return new OpenAPI()
              .info(new Info().title("IITM Hostel Asset & Complaint Management API").version("v2.0"))
              .addSecurityItem(new SecurityRequirement().addList(SECURITY_SCHEME_NAME))
              .components(new Components().addSecuritySchemes(SECURITY_SCHEME_NAME,
                  new SecurityScheme()
                      .name(SECURITY_SCHEME_NAME)
                      .type(SecurityScheme.Type.HTTP)
                      .scheme("bearer")
                      .bearerFormat("JWT")));
      }
  }
  ```
* **Pre-seeded Accounts:** Configured in [DataSeeder.java](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/java/com/iitm/hostel/config/DataSeeder.java#L64-L88):
  * `admin` / `password` (Manager)
  * `staff1` / `password` (Staff)
  * `student1` / `password` (Student assigned to `Room 101`)

---

### Step 2: REST API (Spring Boot Engine)

#### What it does:
Listens on port 8080. It handles protocol-level duties:
- Binds to `http://localhost:8080`.
- Enables CORS so Flutter web/mobile can communicate without cross-origin browser blocks.
- Disables CSRF because the system uses stateless Bearer tokens instead of session cookies.

#### Codebase Connection:
* **Server Port:** [application.properties](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/resources/application.properties#L25) (`server.port=8080`)
* **CORS Bean:** [SecurityConfig.java](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/java/com/iitm/hostel/config/SecurityConfig.java#L111-L121)
  ```java
  @Bean
  public CorsConfigurationSource corsConfigurationSource() {
      CorsConfiguration config = new CorsConfiguration();
      config.setAllowedOriginPatterns(List.of("*"));
      config.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
      config.setAllowedHeaders(List.of("*"));
      UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
      source.registerCorsConfiguration("/api/**", config);
      return source;
  }
  ```

---

### Step 3: Authentication & Authorization (The Security Gate)

#### What it does:
1. **Authentication (Login):** Validates username and password, then issues a signed JWT token.
2. **Authorization (Token Validation & RBAC):** Validates incoming bearer tokens on protected endpoints and verifies role permissions.

#### Codebase Connection:

##### A. Login Controller & Service
* **Controller:** [AuthController.java](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/java/com/iitm/hostel/controller/AuthController.java#L18-L21)
  ```java
  @PostMapping("/login")
  public LoginResponse login(@RequestBody LoginRequest request) {
      return authService.login(request);
  }
  ```
* **Service:** [AuthService.java](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/java/com/iitm/hostel/service/AuthService.java#L41-L58)
  ```java
  public LoginResponse login(LoginRequest request) {
      AppUser user = userRepository.findByUsername(request.username().trim())
              .filter(u -> passwordEncoder.matches(request.password(), u.getPasswordHash()))
              .orElseThrow(() -> new UnauthorizedException("Invalid username or password"));

      Instant now = Instant.now();
      JwtClaimsSet claims = JwtClaimsSet.builder()
              .issuer("brahmaputra-hostel")
              .subject(user.getUsername())
              .issuedAt(now)
              .expiresAt(now.plus(tokenLifetime))
              .claim(SecurityConfig.ROLE_CLAIM, user.getRole().name()) // Embeds MANAGER, STAFF, or STUDENT
              .build();

      JwsHeader header = JwsHeader.with(MacAlgorithm.HS256).build();
      String token = jwtEncoder.encode(JwtEncoderParameters.from(header, claims)).getTokenValue();
      return new LoginResponse(token, now.plus(tokenLifetime).toString(), UserDto.from(user));
  }
  ```

##### B. Security Filter Chain & RBAC Access Matrix
* **Filter Configuration:** [SecurityConfig.java](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/java/com/iitm/hostel/config/SecurityConfig.java#L52-L81)
  ```java
  @Bean
  public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
      http
          .csrf(csrf -> csrf.disable())
          .cors(Customizer.withDefaults())
          .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
          .authorizeHttpRequests(auth -> auth
              .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()
              .requestMatchers("/api/auth/login", "/error").permitAll()
              .requestMatchers("/swagger-ui.html", "/swagger-ui/**", "/v3/api-docs/**").permitAll()
              .requestMatchers("/h2-console/**").permitAll()
              .requestMatchers("/api/auth/me", "/api/me/**").authenticated()
              .requestMatchers(HttpMethod.POST, "/api/complaints").authenticated()
              .requestMatchers("/api/dashboard/**").hasRole("MANAGER")
              .requestMatchers(HttpMethod.POST, "/api/floors/*/locations").hasRole("MANAGER")
              .requestMatchers("/api/**").hasAnyRole("MANAGER", "STAFF")
              .anyRequest().denyAll())
          .oauth2ResourceServer(o -> o.jwt(jwt -> jwt.jwtAuthenticationConverter(jwtAuthenticationConverter())));
      return http.build();
  }

  // Maps the "role" claim (e.g. "MANAGER") to Spring Security authority "ROLE_MANAGER"
  private JwtAuthenticationConverter jwtAuthenticationConverter() {
      JwtGrantedAuthoritiesConverter authorities = new JwtGrantedAuthoritiesConverter();
      authorities.setAuthoritiesClaimName(ROLE_CLAIM);
      authorities.setAuthorityPrefix("ROLE_");
      JwtAuthenticationConverter converter = new JwtAuthenticationConverter();
      converter.setJwtGrantedAuthoritiesConverter(authorities);
      return converter;
  }
  ```

##### C. Principal Extraction & Anti-Spoofing Component
* **Current User Helper:** [CurrentUser.java](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/java/com/iitm/hostel/service/CurrentUser.java#L24-L31)
  ```java
  public AppUser get() {
      Authentication auth = SecurityContextHolder.getContext().getAuthentication();
      if (auth == null || !auth.isAuthenticated() || auth.getName() == null) {
          throw new UnauthorizedException("Not signed in");
      }
      return userRepository.findByUsername(auth.getName())
              .orElseThrow(() -> new UnauthorizedException("Account no longer exists"));
  }
  ```

---

### Step 4: Controller → Service → Repository (The Core Engine)

#### What it does:
Implements the core business rules and workflows:
1. **Hierarchical Navigation:** Hostels $\rightarrow$ Floors $\rightarrow$ Locations $\rightarrow$ Assets.
2. **Auto-provisioning:** Creating a new room automatically provisions standard assets (Fan, Cot, Table, Chair) from templates.
3. **Two-Way Complaint State Machine:** Raising a complaint updates the asset status to `COMPLAINT_RAISED`. Resolving the complaint restores the asset status to `WORKING`.

#### Codebase Connection:

##### A. Controllers
* [ComplaintController.java](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/java/com/iitm/hostel/controller/ComplaintController.java): Manages complaint feeds, creation, and resolution updates.
* [DashboardController.java](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/java/com/iitm/hostel/controller/DashboardController.java): Exposes `GET /api/dashboard/summary` for hostel-level metrics.
* [LocationController.java](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/java/com/iitm/hostel/controller/LocationController.java): Manages rooms, common areas, and inspection stamps.
* [AssetController.java](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/java/com/iitm/hostel/controller/AssetController.java): Lists and updates assets per location.

##### B. Services
* **Complaint Lifecycle Management:** [ComplaintService.java](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/java/com/iitm/hostel/service/ComplaintService.java#L86-L130)
  ```java
  // Raising a complaint puts the asset into COMPLAINT_RAISED state:
  if (request.assetId() != null) {
      Asset asset = assetRepository.findById(request.assetId()).orElseThrow(...);
      complaint.setAsset(asset);
      asset.setStatus(AssetStatus.COMPLAINT_RAISED);
      asset.setComment(complaint.getDescription());
      assetRepository.save(asset);
  }

  // Resolving the complaint returns the asset to WORKING state:
  if (status == ComplaintStatus.RESOLVED || status == ComplaintStatus.CLOSED) {
      complaint.setResolvedAt(LocalDateTime.now());
      if (complaint.getAsset() != null) {
          Asset asset = complaint.getAsset();
          asset.setStatus(AssetStatus.WORKING);
          asset.setComment(null);
          assetRepository.save(asset);
      }
  }
  ```
* **Auto-Provisioning Assets:** [LocationService.java](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/java/com/iitm/hostel/service/LocationService.java#L76-L86)
  ```java
  List<AssetTemplate> templates = assetTemplateRepository.findByLocationTypeOrderBySortOrderAsc(type);
  for (AssetTemplate template : templates) {
      if (template.isOptional()) continue;
      Asset asset = new Asset();
      asset.setName(template.getName());
      asset.setAssetTemplate(template);
      asset.setLocation(location);
      assetRepository.save(asset);
  }
  ```

---

### Step 5: Database Layer (PostgreSQL & H2 In-Memory)

#### What it does:
Persists relational data structures:
* **Hostel & Floor:** [Hostel.java](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/java/com/iitm/hostel/model/Hostel.java), [Floor.java](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/java/com/iitm/hostel/model/Floor.java)
* **Location:** [Location.java](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/java/com/iitm/hostel/model/Location.java) with [LocationType](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/java/com/iitm/hostel/enums/LocationType.java) (`ROOM`, `COMMON_AREA`, `RESTROOM`) and [RoomType](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/java/com/iitm/hostel/enums/RoomType.java) (`SINGLE`, `DOUBLE`, `TRIPLE`).
* **Asset:** [Asset.java](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/java/com/iitm/hostel/model/Asset.java) with [AssetStatus](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/java/com/iitm/hostel/enums/AssetStatus.java) (`WORKING`, `COMPLAINT_RAISED`, `DAMAGED`).
* **AppUser:** [AppUser.java](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/java/com/iitm/hostel/model/AppUser.java) with `allocatedRoom` field scoping student permissions.

#### Dual Database Strategy:
1. **H2 In-Memory (Zero-setup demo):**
   * Configured in [application.properties](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/resources/application.properties#L4-L10):
     ```properties
     spring.datasource.url=jdbc:h2:mem:hosteldb
     spring.h2.console.enabled=true
     spring.h2.console.path=/h2-console
     ```
   * Populated on startup by [DataSeeder.java](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/java/com/iitm/hostel/config/DataSeeder.java).
2. **PostgreSQL (Production/Staging):**
   * Populated via [database/import_dataset.py](file:///d:/IITM/PAI/PAI_project/project_repo/database/import_dataset.py) reading `brahmaputra_synthetic_dataset_boys_only.xlsx` with real room allocations.

---

### Step 6: JSON Response & Global Error Handling

#### What it does:
Serializes domain records into JSON representations. If an error occurs anywhere during execution, it ensures consistent, friendly JSON errors rather than generic HTML stack traces.

#### Codebase Connection:
* **Global Advice:** [GlobalExceptionHandler.java](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/java/com/iitm/hostel/exception/GlobalExceptionHandler.java#L26-L92)
  ```java
  @RestControllerAdvice
  public class GlobalExceptionHandler {

      @ExceptionHandler({ResourceNotFoundException.class, NoResourceFoundException.class})
      public ResponseEntity<Object> handleNotFound(Exception ex) {
          return build(HttpStatus.NOT_FOUND, ex.getMessage());
      }

      @ExceptionHandler(InvalidRequestException.class)
      public ResponseEntity<Object> handleInvalid(InvalidRequestException ex) {
          return build(HttpStatus.BAD_REQUEST, ex.getMessage());
      }

      @ExceptionHandler(UnauthorizedException.class)
      public ResponseEntity<Object> handleUnauthorized(UnauthorizedException ex) {
          return build(HttpStatus.UNAUTHORIZED, ex.getMessage());
      }

      @ExceptionHandler(ForbiddenException.class)
      public ResponseEntity<Object> handleForbidden(ForbiddenException ex) {
          return build(HttpStatus.FORBIDDEN, ex.getMessage());
      }

      private ResponseEntity<Object> build(HttpStatus status, String message) {
          Map<String, Object> body = new LinkedHashMap<>();
          body.put("timestamp", LocalDateTime.now().toString());
          body.put("status", status.value());
          body.put("error", status.getReasonPhrase());
          body.put("message", message);
          return ResponseEntity.status(status).body(body);
      }
  }
  ```

---

## 6. Complete Swagger UI Live Demo Script

Follow these steps to demonstrate the end-to-end architecture in Swagger:

### 1. Start the Application
In your terminal, run:
```powershell
cd d:\IITM\PAI\PAI_project\project_repo\backend\demo
.\mvnw.cmd clean spring-boot:run
```
The server will start on port `8080`.

### 2. Open Swagger UI
Open your browser to:
```
http://localhost:8080/swagger-ui.html
```
Point out the top-right green **Authorize 🔓** button configured by [OpenApiConfig.java](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/java/com/iitm/hostel/config/OpenApiConfig.java).

### 3. Step-by-Step Flow Demo

#### Step A: Authentication (Minting the Manager JWT)
1. In Swagger UI, expand `POST /api/auth/login`.
2. Click **Try it out** and enter:
   ```json
   {
     "username": "admin",
     "password": "password"
   }
   ```
3. Click **Execute**.
4. **Explain:**
   - Status: `200 OK`.
   - [AuthService.java](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/java/com/iitm/hostel/service/AuthService.java) loaded `admin`, matched the BCrypt password hash, and used `JwtEncoder` with the HS256 secret key to mint a token with `"role": "MANAGER"`.

#### Step B: Authorizing Swagger UI
1. Copy the long `"token"` string (without quotes).
2. Click the green **Authorize 🔓** button at the top of the Swagger page.
3. Paste the token into the text box and click **Authorize**, then **Close**.
4. The lock icon is now locked (🔒). Swagger will send `Authorization: Bearer <token>` on all requests.

#### Step C: Successful Protected Request (Steps 3, 4, 5, 6)
1. Expand `GET /api/dashboard/summary`.
2. Set `hostelId = 1` and click **Execute**.
3. **Explain:**
   - Status: `200 OK`.
   - The token was intercepted by [SecurityConfig.java](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/java/com/iitm/hostel/config/SecurityConfig.java).
   - `JwtDecoder` validated the signature.
   - `jwtAuthenticationConverter()` extracted `"role": "MANAGER"` $\rightarrow$ `ROLE_MANAGER`.
   - The rule `.requestMatchers("/api/dashboard/**").hasRole("MANAGER")` granted access.
   - [DashboardController.java](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/java/com/iitm/hostel/controller/DashboardController.java) queried [DashboardService.java](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/java/com/iitm/hostel/service/DashboardService.java) and returned the aggregated statistics.

#### Step D: Role-Based Access Control Rejection (403 Forbidden)
1. Click **Authorize** and then **Logout**.
2. Call `POST /api/auth/login` with student credentials:
   ```json
   {
     "username": "student1",
     "password": "password"
   }
   ```
3. Copy the student's JWT token, click **Authorize**, and paste the new token.
4. Call `GET /api/dashboard/summary?hostelId=1` again and click **Execute**.
5. **Explain:**
   - Status: `403 Forbidden`.
   - The token signature is valid, but the user only has `ROLE_STUDENT`.
   - Spring Security rejected the request in the filter chain. [DashboardController.java](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/java/com/iitm/hostel/controller/DashboardController.java) was never executed, proving server-side RBAC protection.

#### Step E: Inspect the Live H2 Database
1. Open a new browser tab to: `http://localhost:8080/h2-console`
2. Set:
   - **JDBC URL:** `jdbc:h2:mem:hosteldb`
   - **User Name:** `sa`
   - **Password:** `password`
3. Click **Connect**.
4. Run:
   ```sql
   SELECT * FROM APP_USERS;
   SELECT * FROM LOCATIONS;
   SELECT * FROM ASSETS;
   ```
   Show that the records seeded by [DataSeeder.java](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/java/com/iitm/hostel/config/DataSeeder.java) correspond directly with the REST API output.

---

## 7. Comprehensive Codebase Directory Map

| Package / Directory | File | Core Purpose |
| :--- | :--- | :--- |
| **`config`** | [SecurityConfig.java](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/java/com/iitm/hostel/config/SecurityConfig.java) | RBAC URL rules, stateless session, `JwtEncoder`, `JwtDecoder`, `PasswordEncoder` |
| | [OpenApiConfig.java](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/java/com/iitm/hostel/config/OpenApiConfig.java) | Swagger UI BearerAuth security scheme configuration |
| | [DataSeeder.java](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/java/com/iitm/hostel/config/DataSeeder.java) | Automatic database population on startup |
| **`controller`** | [AuthController.java](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/java/com/iitm/hostel/controller/AuthController.java) | Exposes `POST /api/auth/login` |
| | [DashboardController.java](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/java/com/iitm/hostel/controller/DashboardController.java) | Exposes `GET /api/dashboard/summary` (Manager only) |
| | [ComplaintController.java](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/java/com/iitm/hostel/controller/ComplaintController.java) | Exposes complaint CRUD and status update endpoints |
| | [LocationController.java](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/java/com/iitm/hostel/controller/LocationController.java) | Exposes location listing, room creation, and inspection stamps |
| | [AssetController.java](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/java/com/iitm/hostel/controller/AssetController.java) | Exposes asset listing and manual condition corrections |
| | [FloorController.java](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/java/com/iitm/hostel/controller/FloorController.java) | Exposes floor endpoints |
| | [RoutineTaskController.java](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/java/com/iitm/hostel/controller/RoutineTaskController.java) | Exposes daily cleaning checklists |
| **`service`** | [AuthService.java](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/java/com/iitm/hostel/service/AuthService.java) | BCrypt verification and HS256 JWT minting |
| | [CurrentUser.java](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/java/com/iitm/hostel/service/CurrentUser.java) | Extracts authenticated user entity from `SecurityContextHolder` |
| | [ComplaintService.java](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/java/com/iitm/hostel/service/ComplaintService.java) | Two-way state machine synchronizing complaints and asset states |
| | [LocationService.java](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/java/com/iitm/hostel/service/LocationService.java) | Location management and automatic asset provisioning via templates |
| | [AssetService.java](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/java/com/iitm/hostel/service/AssetService.java) | Direct status and comment updates for assets |
| | [DashboardService.java](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/java/com/iitm/hostel/service/DashboardService.java) | Aggregates stats across locations, assets, and active complaints |
| **`model`** | [AppUser.java](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/java/com/iitm/hostel/model/AppUser.java) | User credentials, role (`UserRole`), allocated room |
| | [Location.java](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/java/com/iitm/hostel/model/Location.java) | Room / Common Area node linked to floors |
| | [Asset.java](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/java/com/iitm/hostel/model/Asset.java) | Physical items (`WORKING`, `COMPLAINT_RAISED`, `DAMAGED`) |
| | [Complaint.java](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/java/com/iitm/hostel/model/Complaint.java) | Issue tickets linked to locations and assets |
| **`exception`** | [GlobalExceptionHandler.java](file:///d:/IITM/PAI/PAI_project/project_repo/backend/demo/src/main/java/com/iitm/hostel/exception/GlobalExceptionHandler.java) | Transforms exceptions into uniform JSON error bodies |
| **`database`** | [import_dataset.py](file:///d:/IITM/PAI/PAI_project/project_repo/database/import_dataset.py) | Python script importing Excel synthetic dataset into PostgreSQL |
