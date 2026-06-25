#!/usr/bin/env python3
"""
Adds niqqud (vowel diacritics) to Hebrew cards using nakdimon (offline).
Processes all words in one batch for speed.
Usage: python3 add_hebrew_niqqud.py
"""
import json
from pathlib import Path
from nakdimon import diacritize

BASE     = Path(__file__).parent / "YetAnotherLearningCards/YetAnotherLearningCards"
OUT_JSON = BASE / "hebrew_cards.json"

with open(OUT_JSON, encoding="utf-8") as f:
    cards = json.load(f)

print(f"Processing {len(cards)} Hebrew words in one batch...")
joined = "\n".join(c["front"] for c in cards)
result = diacritize(joined)
nikkud_words = result.split("\n")

if len(nikkud_words) != len(cards):
    print(f"Warning: got {len(nikkud_words)} results for {len(cards)} cards — check output")

for card, nikkud in zip(cards, nikkud_words):
    card["front"] = nikkud.strip()

with open(OUT_JSON, "w", encoding="utf-8") as f:
    json.dump(cards, f, ensure_ascii=False, indent=2)

print(f"Done. Samples:")
for c in cards[:5]:
    print(f"  {c['front']} → {c['back']}")
