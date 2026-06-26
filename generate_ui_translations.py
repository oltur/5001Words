#!/usr/bin/env python3
"""
Generates Localizable.strings for all supported languages.
Translates English UI strings via Google Translate.
Writes to both iOS and Watch App target directories.
Usage: python3 generate_ui_translations.py
Safe to re-run — overwrites all files.
"""
import time
from pathlib import Path
from deep_translator import GoogleTranslator

ROOT      = Path(__file__).parent / "YetAnotherLearningCards"
IOS_DIR   = ROOT / "YetAnotherLearningCards"
WATCH_DIR = ROOT / "YetAnotherLearningCards Watch App"

LANGUAGES = [
    "bg", "ca", "cs", "cy", "da", "de", "el", "es", "et", "eu",
    "fi", "fr", "ga", "gd", "gl", "he", "hi", "hr", "hu", "is",
    "it", "ja", "ko", "lt", "lv", "nb", "nl", "pl", "pt", "ro",
    "sk", "sl", "sq", "sv", "th", "uk",
]

# Google Translate language codes that differ from lproj codes
LANG_MAP = {
    "cy": "cy",   # Welsh
    "gd": "gd",   # Scottish Gaelic
    "gl": "gl",   # Galician
    "eu": "eu",   # Basque
    "nb": "no",   # Norwegian Bokmål → Norwegian in Google
    "is": "is",   # Icelandic
    "sq": "sq",   # Albanian
    "he": "iw",   # Hebrew (Google uses legacy code)
}

# All UI strings: key = English text (used directly as LocalizedStringKey in SwiftUI)
STRINGS = {
    # Main view
    "Loading cards...":           "Loading cards...",
    "· Focus":                    "· Focus",
    "Get more languages…":        "Get more languages…",
    "Direction":                  "Direction",

    # Completion view
    "Focus set complete!":                          "Focus set complete!",
    "You've learned all words in your focus set.":  "You've learned all words in your focus set.",
    "Pick new set of 20":                           "Pick new set of 20",
    "All done!":                                    "All done!",
    "Open Settings":                                "Open Settings",

    # Buttons
    "Audio":       "Audio",
    "Download":    "Download",
    "Learned":     "Learned",
    "Remove":      "Remove",
    "Failed":      "Failed",
    "Retry":       "Retry",
    "Done":        "Done",
    "Reset":       "Reset",
    "Cancel":      "Cancel",

    # Settings sections
    "Settings":               "Settings",
    "Auto-play word aloud":   "Auto-play word aloud",
    "Focus Mode":             "Focus Mode",
    "Focus on 20 words":      "Focus on 20 words",
    "Progress":               "Progress",
    "Remaining":              "Remaining",
    "Total":                  "Total",
    "Reset all progress":     "Reset all progress",
    "Language Packs":         "Language Packs",
    "Each pack includes the word list and audio. Stored locally, not backed up to iCloud.":
        "Each pack includes the word list and audio. Stored locally, not backed up to iCloud.",
    "About":                  "About",
    "About & Contact":        "About & Contact",
    "Privacy Policy":         "Privacy Policy",

    # Dialogs
    "Reset all progress?":    "Reset all progress?",
    "This clears all learned words and focus sets for this deck.":
        "This clears all learned words and focus sets for this deck.",
    "The word list and audio will be deleted. You can re-download anytime.":
        "The word list and audio will be deleted. You can re-download anytime.",

    # Pack row status labels
    "5,001 cards included · No audio":          "5,001 cards included · No audio",
    "5,001 cards + audio installed":             "5,001 cards + audio installed",
    "5,001 cards included · Download for audio": "5,001 cards included · Download for audio",
    "5,001 cards + audio  ·  ~30 MB":           "5,001 cards + audio  ·  ~30 MB",

    # Impressum / About view
    "App":        "App",
    "Version":    "Version",
    "Developer":  "Developer",
    "Contact":    "Contact",

    # Privacy Policy view (iOS)
    "Data Storage":       "Data Storage",
    "All your progress (learned words, focus sets) and settings are stored locally on your device only. No data is transmitted to external servers or third parties.":
        "All your progress (learned words, focus sets) and settings are stored locally on your device only. No data is transmitted to external servers or third parties.",
    "Data Collection":    "Data Collection",
    "We do not collect, store, or share any personal information. The app only saves your vocabulary progress and preferences locally on your device.":
        "We do not collect, store, or share any personal information. The app only saves your vocabulary progress and preferences locally on your device.",
    "Audio Downloads":    "Audio Downloads",
    "Language packs (word lists and audio files) are downloaded from GitHub Releases and stored locally in your device storage. No account or personal information is required to download packs.":
        "Language packs (word lists and audio files) are downloaded from GitHub Releases and stored locally in your device storage. No account or personal information is required to download packs.",
    "Data Control":       "Data Control",
    "You have full control over your data. You can reset all progress or remove downloaded language packs at any time through the Settings screen.":
        "You have full control over your data. You can reset all progress or remove downloaded language packs at any time through the Settings screen.",
    "No Third-Party Tracking":    "No Third-Party Tracking",
    "This app contains no ads, no analytics, and no third-party tracking SDKs.":
        "This app contains no ads, no analytics, and no third-party tracking SDKs.",

    # Watch-specific
    "Auto-play":      "Auto-play",
    "Focus 20":       "Focus 20",
    "New set of 20":  "New set of 20",
    "Reset progress": "Reset progress",
    "Reset?":         "Reset?",
    "No data collected.":
        "No data collected.",
    "All progress is stored locally on your device. No servers, no tracking, no ads.":
        "All progress is stored locally on your device. No servers, no tracking, no ads.",
    "Privacy":        "Privacy",
}

def escape(s: str) -> str:
    return s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")

def write_strings(directory: Path, lang: str, translations: dict[str, str]):
    lproj = directory / f"{lang}.lproj"
    lproj.mkdir(parents=True, exist_ok=True)
    lines = [f"/* {lang} */\n"]
    for key, value in translations.items():
        lines.append(f'"{escape(key)}" = "{escape(value)}";\n')
    (lproj / "Localizable.strings").write_text("".join(lines), encoding="utf-8")

def translate_all(lang: str) -> dict[str, str]:
    google_lang = LANG_MAP.get(lang, lang)
    translator = GoogleTranslator(source="en", target=google_lang)
    result = {}
    keys = list(STRINGS.keys())
    # Batch translate using separator
    SEP = "\n||||\n"
    BATCH = 20
    for i in range(0, len(keys), BATCH):
        batch = keys[i:i+BATCH]
        english_vals = [STRINGS[k] for k in batch]
        joined = SEP.join(english_vals)
        try:
            translated = translator.translate(joined)
            parts = translated.split(SEP)
            if len(parts) != len(batch):
                # Fall back to one-by-one
                parts = [translator.translate(v) for v in english_vals]
        except Exception as e:
            print(f"  Error batch {i}: {e}, falling back to individual...")
            parts = []
            for v in english_vals:
                try:
                    parts.append(translator.translate(v))
                    time.sleep(0.1)
                except Exception as e2:
                    print(f"  Error translating '{v[:30]}': {e2}")
                    parts.append(v)
        for key, tr in zip(batch, parts):
            result[key] = tr.strip() if tr else STRINGS[key]
        time.sleep(0.2)
    return result

# Write English first
print("Writing English (en)...")
write_strings(IOS_DIR, "en", STRINGS)
write_strings(WATCH_DIR, "en", STRINGS)

# Translate and write all other languages
for lang in LANGUAGES:
    print(f"Translating {lang}...")
    try:
        translations = translate_all(lang)
        write_strings(IOS_DIR, lang, translations)
        write_strings(WATCH_DIR, lang, translations)
        print(f"  ✓ {lang} done")
    except Exception as e:
        print(f"  ✗ {lang} failed: {e}")
    time.sleep(0.3)

print("\nDone. Add the .lproj folders to both Xcode targets.")
print("In Xcode: File → Add Files → select each .lproj, check both targets.")
