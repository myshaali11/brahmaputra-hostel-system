from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
import joblib
import os
import uvicorn

app = FastAPI(
    title="Brahmaputra Hostel AI Predictive Maintenance & Triage Service",
    version="1.0.0",
    description="Machine learning microservice for automated complaint classification, risk prediction, and preventative maintenance alerting."
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
CAT_MODEL_PATH = os.path.join(BASE_DIR, "category_model.pkl")
PRIO_MODEL_PATH = os.path.join(BASE_DIR, "priority_model.pkl")

cat_model = None
prio_model = None

if os.path.exists(CAT_MODEL_PATH) and os.path.exists(PRIO_MODEL_PATH):
    cat_model = joblib.load(CAT_MODEL_PATH)
    prio_model = joblib.load(PRIO_MODEL_PATH)
else:
    print("⚠️ Model pickle files not found. Run train_model.py first.")

class ComplaintRequest(BaseModel):
    title: str
    description: str
    assetName: Optional[str] = None
    locationName: Optional[str] = None

class PredictionResponse(BaseModel):
    predictedCategory: str
    predictedPriority: str
    confidence: float
    recommendation: str
    isHazard: bool

class AssetHistoryItem(BaseModel):
    complaintId: int
    title: str
    status: str
    createdAt: Optional[str] = None

class AnomalyCheckRequest(BaseModel):
    assetId: int
    assetName: str
    locationName: Optional[str] = None
    pastComplaints: List[AssetHistoryItem]

class AnomalyCheckResponse(BaseModel):
    assetId: int
    complaintCount: int
    failureRiskLevel: str  # NORMAL, MODERATE, HIGH, CRITICAL
    replacementRecommended: bool
    insight: str

@app.get("/health")
def health_check():
    return {
        "status": "UP",
        "service": "Brahmaputra AI Maintenance Analytics",
        "modelsLoaded": cat_model is not None and prio_model is not None
    }

@app.post("/api/ai/triage", response_model=PredictionResponse)
def triage_complaint(req: ComplaintRequest):
    if cat_model is None or prio_model is None:
        raise HTTPException(status_code=503, detail="AI models not loaded")

    text = f"{req.title} {req.description} {req.assetName or ''}".strip()
    if not text:
        return PredictionResponse(
            predictedCategory="GENERAL",
            predictedPriority="LOW",
            confidence=0.5,
            recommendation="Standard review required.",
            isHazard=False
        )

    category = cat_model.predict([text])[0]
    priority = prio_model.predict([text])[0]

    # Calculate prediction confidence if predict_proba is available
    confidence = 0.88
    try:
        cat_probs = cat_model.predict_proba([text])[0]
        confidence = float(max(cat_probs))
    except Exception:
        pass

    # Safety Hazard Check
    hazard_keywords = ["spark", "fire", "smoke", "short circuit", "flood", "collapse", "burst", "shock"]
    is_hazard = any(k in text.lower() for k in hazard_keywords)
    if is_hazard:
        priority = "URGENT"

    # Actionable Recommendation mapping
    recs = {
        ("ELECTRICAL", "URGENT"): "🚨 High Hazard Risk: Isolate breaker line and dispatch electrician immediately.",
        ("ELECTRICAL", "HIGH"): "Power disruption: Schedule electrical maintenance within 4 hours.",
        ("ELECTRICAL", "MEDIUM"): "Standard electrical maintenance: Inspect capacitor, motor or switch.",
        ("ELECTRICAL", "LOW"): "Routine replacement: Swap out tube/bulb during scheduled rounds.",
        ("PLUMBING", "URGENT"): "🚨 Flood Risk: Shut off isolation valve and dispatch plumber immediately.",
        ("PLUMBING", "HIGH"): "Active leak: Priority repair to avoid water damage.",
        ("PLUMBING", "MEDIUM"): "Sanitary maintenance: Clear blockage or replace washer.",
        ("CARPENTRY", "URGENT"): "Security/Safety risk: Inspect and secure latch/frame immediately.",
        ("CARPENTRY", "HIGH"): "Structural instability: Restrict usage until repaired.",
        ("CARPENTRY", "MEDIUM"): "Standard repair: Tighten fittings, replace hinges, or resurface.",
        ("CLEANING", "HIGH"): "Sanitation breach: Immediate housekeeping dispatch.",
    }

    recommendation = recs.get(
        (category, priority),
        f"Route ticket to {category.lower()} team with {priority.lower()} priority."
    )

    return PredictionResponse(
        predictedCategory=category,
        predictedPriority=priority,
        confidence=round(confidence, 2),
        recommendation=recommendation,
        isHazard=is_hazard
    )

@app.post("/api/ai/anomaly", response_model=AnomalyCheckResponse)
def check_asset_anomaly(req: AnomalyCheckRequest):
    count = len(req.pastComplaints)
    
    if count >= 3:
        risk = "CRITICAL"
        replace = True
        insight = f"⚠️ Recurring Degradation: Asset has failed {count} times. Preventative replacement strongly recommended to prevent repeated downtime."
    elif count == 2:
        risk = "HIGH"
        replace = False
        insight = f"Accelerated wear detected ({count} complaints). Comprehensive overhaul suggested."
    elif count == 1:
        risk = "MODERATE"
        replace = False
        insight = "Single isolated issue reported. Monitor during next routine inspection."
    else:
        risk = "NORMAL"
        replace = False
        insight = "Asset operating normally with no failure history."

    return AnomalyCheckResponse(
        assetId=req.assetId,
        complaintCount=count,
        failureRiskLevel=risk,
        replacementRecommended=replace,
        insight=insight
    )

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=5001)
