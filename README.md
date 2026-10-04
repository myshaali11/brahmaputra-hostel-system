# Brahmaputra Hostel System

A comprehensive digital ecosystem for asset management and complaint routing at the Brahmaputra Hostel. This system replaces the tedious, manual paper-based register process with a compact, automated, and roles-based web platform.

## Features

- **Role-Based Access Control (RBAC):** Distinct roles and workflows for Managers, Staff (maintenance), and Students.
- **Hierarchical Asset Tracking:** Track assets by Hostel -> Floor -> Location (Rooms, Restrooms, Common Areas).
- **Complaint Management:** Students can raise complaints for assets in their allocated rooms or common areas. Staff can manage and resolve these tickets.
- **Preventative Maintenance AI (Planned):** A hybrid AI component using a Python microservice to analyze text-based damage reports and predict preventative maintenance needs before complete failure.
- **Interactive Student Dashboard:** See allocated rooms, raise issues, and track resolutions in real-time.

## Project Structure

The project uses a monorepo setup containing the backend, frontend, and design documentation.

- `docs/`: Contains the project proposal (`proposal_v2.tex`, `proposal_v2.pdf`) and the architectural design document (`design_doc.tex`, `design_doc.pdf`).
- `backend/demo/`: The Spring Boot 3 + Spring Security (JWT) REST API backend.
- `frontend/`: (Currently under development) The frontend codebase intended to connect to the backend APIs.

## Architecture

* **Backend:** Java 21, Spring Boot 3.4, Spring Security + OAuth2 Resource Server (JWT), H2 Database (for demo purposes).
* **AI Microservice:** Python (FastAPI/Flask) - *to be integrated in the final milestone*.

## Getting Started (Backend Demo)

The backend is configured with an in-memory H2 database. On startup, a `DataSeeder` automatically populates the database with sample hostels, floors, locations, assets, and users, meaning it is **zero-setup** and ready to run for the October 9 mid-demo.

### Prerequisites

- Java 21 installed.
- Maven (optional, wrapper is included).

### Running the Backend

Navigate to the backend directory and use the Maven wrapper to run the application:

```bash
cd backend/demo
./mvnw clean spring-boot:run
```

The application will start on `http://localhost:8080`.

### Demo Accounts

The `DataSeeder` creates the following accounts. All accounts use the password: `password`

| Role | Username | Password | Notes |
| :--- | :--- | :--- | :--- |
| **Manager** | `admin` | `password` | Has full access to all endpoints. |
| **Staff** | `staff1` | `password` | Can manage assigned tasks and complaints. |
| **Student** | `student1`| `password` | Allocated to "Room 101" to raise complaints. |

### API Testing

The backend includes a Swagger UI for exploring and testing the REST API.

1. Once the backend is running, open: `http://localhost:8080/swagger-ui.html`
2. Authenticate using the `/api/auth/login` endpoint with one of the demo accounts.
3. Use the returned JWT token to authorize subsequent requests in Swagger.

## Milestones

- **Sept 25:** Backend foundation complete (JPA entities, REST controllers) - **Done**
- **Oct 9:** Mid-demo (RBAC, JWT, H2 seeded database) - **Current**
- **Final Submission:** Integration of the Python AI Microservice and finalized frontend.
