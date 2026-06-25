#!/usr/bin/env python3
"""
Generates ukrainian_cards.json (5,001 Ukrainian-English flashcards).
Reuses existing Spanish-Ukrainian translations — no API calls needed.
Ukrainian front = spanish_uk_cards back, English back = spanish_cards back.
Usage: python3 generate_ukrainian_cards.py
"""
import json
from pathlib import Path

BASE        = Path(__file__).parent / "YetAnotherLearningCards/YetAnotherLearningCards"
SP_JSON     = BASE / "spanish_cards.json"
SP_UK_JSON  = BASE / "spanish_uk_cards.json"
OUT_JSON    = BASE / "ukrainian_cards.json"

with open(SP_JSON, encoding="utf-8") as f:
    sp_cards = json.load(f)

with open(SP_UK_JSON, encoding="utf-8") as f:
    sp_uk_cards = json.load(f)

result = []
for i, (sp, uk) in enumerate(zip(sp_cards, sp_uk_cards)):
    result.append({"front": uk["back"], "back": sp["back"], "audioIndex": i})

with open(OUT_JSON, "w", encoding="utf-8") as f:
    json.dump(result, f, ensure_ascii=False, indent=2)

print(f"Done. Written {len(result)} cards to {OUT_JSON.name}")
print(f"Sample: {result[0]['front']} → {result[0]['back']}")
