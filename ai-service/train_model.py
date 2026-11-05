import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.pipeline import Pipeline
import joblib
import os

# Comprehensive training dataset representing hostel issues
training_data = [
    # Electrical
    ("Ceiling fan making squeaking grinding noise", "ELECTRICAL", "MEDIUM"),
    ("Sparking switchboard and loose plug socket", "ELECTRICAL", "URGENT"),
    ("Tube light flickering constantly and buzzing", "ELECTRICAL", "LOW"),
    ("No power in room power outlet not working", "ELECTRICAL", "HIGH"),
    ("Fan regulator broken stuck on high speed", "ELECTRICAL", "LOW"),
    ("Short circuit smell near the wiring conduit", "ELECTRICAL", "URGENT"),
    ("Ceiling fan not spinning even after turning on", "ELECTRICAL", "MEDIUM"),
    ("Socket smoking when charger plugged in", "ELECTRICAL", "URGENT"),
    ("Light bulb fused need replacement", "ELECTRICAL", "LOW"),
    ("Exhaust fan broken in restroom", "ELECTRICAL", "MEDIUM"),
    ("Switch panel loose exposing wires", "ELECTRICAL", "URGENT"),

    # Plumbing
    ("Washroom tap leaking continuously wasting water", "PLUMBING", "MEDIUM"),
    ("Severe flush tank overflow and pipe leak", "PLUMBING", "HIGH"),
    ("Restroom drainage blocked water clogged completely", "PLUMBING", "URGENT"),
    ("No running water in bathroom washbasin", "PLUMBING", "HIGH"),
    ("Shower head broken water spraying everywhere", "PLUMBING", "MEDIUM"),
    ("Pipe burst under sink flooding floor", "PLUMBING", "URGENT"),
    ("Foul smell and sewage backflow from floor trap", "PLUMBING", "HIGH"),
    ("Water cooler tap dripping continuously", "PLUMBING", "LOW"),
    ("Toilet jet spray broken and spraying water", "PLUMBING", "MEDIUM"),

    # Carpentry / Furniture
    ("Study table drawer broken stuck and won't open", "CARPENTRY", "LOW"),
    ("Cot wooden plank cracked danger of collapsing", "CARPENTRY", "HIGH"),
    ("Chair leg loose and wobbling unstably", "CARPENTRY", "LOW"),
    ("Cupboard latch and door hinge broken", "CARPENTRY", "MEDIUM"),
    ("Door lock jammed cannot latch door from inside", "CARPENTRY", "URGENT"),
    ("Window glass cracked with sharp edges", "CARPENTRY", "HIGH"),
    ("Study table surface peeled and nails jutting out", "CARPENTRY", "MEDIUM"),
    ("Wardrobe handle broken off", "CARPENTRY", "LOW"),
    ("Curtain rod fell off wall", "CARPENTRY", "LOW"),

    # Housekeeping / Sanitation
    ("Room floor dirty need deep cleaning", "CLEANING", "LOW"),
    ("Dustbin overflow in corridor rotting waste", "CLEANING", "MEDIUM"),
    ("Water dispenser area dirty and stained with fungus", "CLEANING", "MEDIUM"),
    ("Restroom unhygienic not cleaned for two days", "CLEANING", "HIGH"),
    ("Spider webs and severe dust accumulated on ceiling", "CLEANING", "LOW"),
    ("Pest infestation spotted near trash area", "CLEANING", "HIGH"),
]

def train_and_save():
    df = pd.DataFrame(training_data, columns=["text", "category", "priority"])

    # Category classification pipeline
    cat_pipeline = Pipeline([
        ("tfidf", TfidfVectorizer(ngram_range=(1, 2))),
        ("clf", LogisticRegression(max_iter=1000))
    ])
    cat_pipeline.fit(df["text"], df["category"])

    # Priority classification pipeline
    prio_pipeline = Pipeline([
        ("tfidf", TfidfVectorizer(ngram_range=(1, 2))),
        ("clf", LogisticRegression(max_iter=1000))
    ])
    prio_pipeline.fit(df["text"], df["priority"])

    save_dir = os.path.dirname(os.path.abspath(__file__))
    cat_path = os.path.join(save_dir, "category_model.pkl")
    prio_path = os.path.join(save_dir, "priority_model.pkl")

    joblib.dump(cat_pipeline, cat_path)
    joblib.dump(prio_pipeline, prio_path)

    print(f"✅ Models trained successfully!\n   Saved {cat_path}\n   Saved {prio_path}")

if __name__ == "__main__":
    train_and_save()
