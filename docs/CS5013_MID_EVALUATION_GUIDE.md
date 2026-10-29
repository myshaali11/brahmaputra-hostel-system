# CS5013 Mid-Evaluation Presentation & Defense Guide
**System:** Brahmaputra Hostel Management & IVRS Maintenance System  
**Team Members:** Akhilesh & Mysha Ali  
**Repository:** [github.com/myshaali11/brahmaputra-hostel-system](https://github.com/myshaali11/brahmaputra-hostel-system)  
**Deliverable Document:** `brahmaputra_mid_evaluation_architecture.png`  

---

## 1. 2-Minute Joint Presentation Script

### 0:00 – 0:35: System Overview & Problem Statement (Shared / Akhilesh)
> *"Good morning Evaluators. We are Akhilesh and Mysha Ali, presenting the Brahmaputra Hostel Management System. In Brahmaputra Hostel with over 140+ resident students across multiple wings, tracking room fixture health, logging maintenance tickets, and validating inspections historically suffered from fragmented WhatsApp messages and lost paper logs.  
> We engineered an end-to-end, zero-configuration reactive architecture with a Spring Boot 3.4 REST engine and a Material 3 Flutter web/mobile portal. Our system provides automated institutional onboarding using IITM Smail Google OAuth, dynamic role classification, token-bucket DoS protection, and a real-time IVRS ticket lifecycle."*

### 0:35 – 1:20: Ingestion, Security & Auth Architecture (Akhilesh — Stages 1 to 4)
> *"On the backend infrastructure side, which I spearheaded:  
> - **Stage 1 (Ingestion):** We built an Apache POI streaming pipeline that parses the hostel roster from Excel, automatically linking 146 students to floors and room numbers upon startup with zero manual database setup.  
> - **Stage 2 (Identity & Classification):** We enforced institutional OAuth restricted to `@smail.iitm.ac.in`. We use a custom regular expression `^[a-zA-Z]{2}\d{2}[a-zA-Z]\d{3,4}$` to identify student roll numbers and automatically grant the `STUDENT` role and bind their allocated room. Management and maintenance emails are classified into `MANAGER` and `STAFF`.  
> - **Stage 3 (Rate Limiting Defense):** To protect BCrypt’s CPU-intensive key derivation function from brute-force denial-of-service, we integrated a Bucket4j Token Bucket filter that throttles clients to 10 requests/minute per IP, rejecting floods with HTTP 429 before password hashing occurs.  
> - **Stage 4 (Tokenization):** Once validated, the system issues cryptographically signed HMAC-SHA256 JWTs embedding role claims and room IDs for stateless session verification."*

### 1:20 – 1:55: Lifecycle, Dashboards & Executive KPI (Mysha Ali — Stages 5 to 8)
> *"On the operational and UI/UX lifecycle side, which I spearheaded:  
> - **Stage 5 (Authorization):** Every incoming request is intercepted by Spring Security's filter chain with method-level `@PreAuthorize`, ensuring students cannot view or modify other rooms' complaints.  
> - **Stage 6 (Ticket Lifecycle):** Students can report broken fixtures with priority tags (LOW to URGENT), instantly generating an IVRS tracking ticket (`TICK-XXXX`).  
> - **Stage 7 (Audit & Inspection):** Hostel maintenance staff have dedicated inspection stamping tools to record physical floor rounds and update tickets with resolution notes.  
> - **Stage 8 (Executive Analytics):** The Manager Suite provides real-time KPI metrics on occupancy, pending tickets, and maintenance health, supported by a rich Material 3 Flutter interface."*

### 1:55 – 2:00: Wrap-Up & Live Demo Readiness (Shared)
> *"All 78 backend classes and Flutter client tests compile and run with 100% pass rates. We are ready to demonstrate the live Swagger UI and take your live code modification tasks."*

---

## 2. Division of Work & Technical Ownership

| Component / Layer | Primary Owner | Architectural Scope | Key Code Files |
| :--- | :--- | :--- | :--- |
| **Stages 1–4:** Data Ingestion & Security | **Akhilesh** | Apache POI roster ingestion, IITM Smail regex classifier, Bucket4j rate limiter, BCrypt DoS safeguard, JWT generator | `ExcelDataImporter.java`, `AuthService.java`, `RateLimitingFilter.java`, `RateLimitingService.java`, `AppUser.java` |
| **Stages 5–8:** Business Logic & Operations | **Mysha Ali** | Spring Security RBAC, Complaint IVRS State Machine, Location & Asset hierarchy, Inspection stamping, Manager KPI analytics | `ComplaintService.java`, `ComplaintController.java`, `LocationService.java`, `SecurityConfig.java`, `DataSeeder.java` |
| **Fullstack & UI:** Client & Verification | **Shared** | Flutter Material 3 client, Smail login dialog, Quick-fill chips, Swagger OpenAPI 3.0, Unit & Widget test suites | `login_screen.dart`, `student_dashboard_screen.dart`, `staff_dashboard_screen.dart`, `manager_dashboard_screen.dart`, `api_service.dart` |

---

## 3. How to Run the Live Demo

### Step 1: Start Backend (Spring Boot 3.4.3)
```powershell
cd D:\IITM\PAI\PAI_project\project_repo\backend\demo
./mvnw clean spring-boot:run
```
- In-memory H2 database initializes instantly.
- Roster importer seeds 146 students, floors, and rooms from `brahmaputra_synthetic_dataset_boys_only.xlsx`.
- Server runs on `http://localhost:8080`.

### Step 2: Open Swagger UI (OpenAPI 3.0)
- URL: `http://localhost:8080/swagger-ui/index.html`
- Demonstrate:
  1. `POST /api/auth/google` with Smail account `ch23b001@smail.iitm.ac.in` $\to$ Returns JWT with `ROLE_STUDENT`.
  2. Click **Authorize** button and paste `Bearer <token>`.
  3. `GET /api/complaints/my-room` $\to$ Returns room-scoped complaints.
  4. Test Rate Limiting: Rapidly send 11 requests to `/api/auth/login` $\to$ 11th request receives `429 Too Many Requests`.

### Step 3: Run Frontend (Flutter Web)
```powershell
cd D:\IITM\PAI\PAI_project\project_repo\frontend
flutter run -d chrome
```
- Click on **Demo Quick Fill** chips (`ch23b001` or `admin`).
- Demonstrate Student Dashboard (Asset health, File complaint modal).
- Demonstrate Manager Dashboard (Analytics KPI cards, Complaint queue, Add location modal).

---

## 4. Anticipated Live Code Modification Tasks & Instant Solutions

| Scenario | Anticipated TA Task | File to Modify | Solution Approach |
| :--- | :--- | :--- | :--- |
| **1. Role Classifier** | Add a new role `WARDEN` or allow `@faculty.iitm.ac.in` | `AuthService.java` | Add condition in `loginWithGoogle`: `if (email.endsWith("@faculty.iitm.ac.in")) user.setRole(Role.MANAGER);` |
| **2. Rate Limiting** | Change rate limit to 5 requests per 30 seconds | `RateLimitingService.java` | Modify `Bandwidth.classic(5, Refill.greedy(5, Duration.ofSeconds(30)))` |
| **3. Priority Tag** | Add a new priority `EMERGENCY` | `Priority.java` & `ComplaintModel.dart` | Add `EMERGENCY` to Java enum and Flutter dropdown list |
| **4. Ticket Filtering** | Add endpoint to fetch tickets by priority | `ComplaintRepository.java` & `ComplaintController.java` | Add `List<Complaint> findByPriority(Priority p)` in repo and expose via GET endpoint |
| **5. Frontend Validation** | Enforce min 10 characters in complaint description | `student_dashboard_screen.dart` | In `_showNewComplaintSheet`, add check: `if (desc.length < 10) { showSnackBar("Min 10 characters required"); return; }` |
