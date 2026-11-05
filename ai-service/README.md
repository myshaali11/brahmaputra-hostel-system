# Brahmaputra Hostel — AI Predictive Maintenance & Triage Service

A dedicated Machine Learning microservice built with **Python 3**, **FastAPI**, and **scikit-learn** as part of the CS5013 PAI hostel lifecycle system.

## Capabilities

1. **Automated Triage & Risk Prediction (`POST /api/ai/triage`):**
   - Natural Language classification of complaint text into domain categories (`ELECTRICAL`, `PLUMBING`, `CARPENTRY`, `CLEANING`).
   - Priority and severity detection (`URGENT`, `HIGH`, `MEDIUM`, `LOW`).
   - Hazard detection (e.g. electrical sparks, short circuits, flooding).
   - Generates actionable maintenance recommendations for hostel staff.

2. **Preventative Maintenance & Failure Risk Anomaly Detection (`POST /api/ai/anomaly`):**
   - Aggregates recurring issue frequencies for specific fixtures and equipment.
   - Computes failure risk levels (`NORMAL`, `MODERATE`, `HIGH`, `CRITICAL`).
   - Issues replacement recommendations before catastrophic failure occurs.

## Running the Service

```bash
cd ai-service

# Train/re-train models
python3 train_model.py

# Start the FastAPI service (runs on http://localhost:5001)
python3 main.py
```

Swagger UI documentation is available at `http://localhost:5001/docs`.
