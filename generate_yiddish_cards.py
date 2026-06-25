#!/usr/bin/env python3
"""
Generates yiddish_cards.json (5,001 Yiddish-English flashcards).
Translates Spanish fronts from spanish_cards.json into Yiddish.
Front: Yiddish  Back: English. No audio.
Translating ES→YI avoids comma-separated multi-value English translations.
Usage: python3 generate_yiddish_cards.py
Safe to re-run — resumes from cached progress.
"""
import json, re, time
from pathlib import Path
from deep_translator import GoogleTranslator

BASE     = Path(__file__).parent / "YetAnotherLearningCards/YetAnotherLearningCards"
SRC_JSON = BASE / "spanish_cards.json"
OUT_JSON = BASE / "yiddish_cards.json"
CACHE    = BASE / "yiddish_cache.json"

BATCH = 50
DELAY = 0.3

def strip_annotation(text: str) -> str:
    return re.sub(r'\s*\([^)]+\)\s*$', '', text).strip()

with open(SRC_JSON, encoding="utf-8") as f:
    src = json.load(f)

cache: dict[str, str] = {}
if CACHE.exists():
    with open(CACHE, encoding="utf-8") as f:
        cache = json.load(f)

translator = GoogleTranslator(source="es", target="yi")

def translate_batch(texts: list[str]) -> list[str]:
    joined = "\n||||\n".join(texts)
    result = translator.translate(joined)
    parts = result.split("\n||||\n")
    if len(parts) != len(texts):
        return [translator.translate(t) for t in texts]
    return parts

all_spanish = [strip_annotation(card["front"]) for card in src]
needed_unique = list(dict.fromkeys(t for t in all_spanish if t not in cache))

print(f"Translating {len(needed_unique)} unique Spanish strings ES→YI...")

for i in range(0, len(needed_unique), BATCH):
    batch = needed_unique[i:i+BATCH]
    try:
        translated = translate_batch(batch)
        for orig, yi in zip(batch, translated):
            cache[orig] = yi
        if (i // BATCH) % 10 == 0:
            with open(CACHE, "w", encoding="utf-8") as f:
                json.dump(cache, f, ensure_ascii=False)
            print(f"  {i + len(batch)}/{len(needed_unique)} done...")
        time.sleep(DELAY)
    except Exception as e:
        print(f"Error at batch {i}: {e} — retrying in 5s")
        time.sleep(5)
        try:
            translated = translate_batch(batch)
            for orig, yi in zip(batch, translated):
                cache[orig] = yi
        except Exception as e2:
            print(f"Failed again: {e2} — keeping original")
            for orig in batch:
                cache[orig] = orig

with open(CACHE, "w", encoding="utf-8") as f:
    json.dump(cache, f, ensure_ascii=False)

result = []
for card, spanish in zip(src, all_spanish):
    yi_front = cache.get(spanish, spanish)
    result.append({"front": yi_front, "back": card["back"]})

with open(OUT_JSON, "w", encoding="utf-8") as f:
    json.dump(result, f, ensure_ascii=False, indent=2)

print(f"Done. Written {len(result)} cards to {OUT_JSON.name}")
