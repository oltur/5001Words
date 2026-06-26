#!/usr/bin/env python3
"""
Generates all web content for turevskiy.com/5001words:
- privacyPolicy/privacy-policy-{lang}.html (37 languages)
- appDescription/app-description-{lang}.txt (37 languages)
Translates from English via Google Translate.
Usage: python3 generate_web_content.py
"""
import time, re
from pathlib import Path
from deep_translator import GoogleTranslator

BASE       = Path(__file__).parent / "Other/appleStore"
PP_DIR     = BASE / "privacyPolicy"
DESC_DIR   = BASE / "appDescription"
PP_DIR.mkdir(parents=True, exist_ok=True)
DESC_DIR.mkdir(parents=True, exist_ok=True)

LANGUAGES = [
    "bg", "ca", "cs", "cy", "da", "de", "el", "es", "et", "eu",
    "fi", "fr", "ga", "gd", "gl", "he", "hi", "hr", "hu", "is",
    "it", "ja", "ko", "lt", "lv", "nb", "nl", "pl", "pt", "ro",
    "sk", "sl", "sq", "sv", "th", "uk",
]

LANG_MAP = {"nb": "no", "he": "iw"}

PRIVACY_SECTIONS_EN = {
    "title":            "Privacy Policy",
    "updated":          "Last updated: 2026-06-26",
    "intro":            "5001 Words is designed with your privacy in mind.",
    "h_storage":        "Data Storage",
    "p_storage":        "All your progress (learned words, focus sets) and settings are stored locally on your device only. No data is transmitted to external servers or third parties.",
    "h_collection":     "Data Collection",
    "p_collection":     "We do not collect, store, or share any personal information. The app only saves your vocabulary progress and preferences locally on your device.",
    "h_audio":          "Audio Downloads",
    "p_audio":          "Language packs (word lists and audio files) are downloaded from GitHub Releases and stored locally in your device storage. No account or personal information is required.",
    "h_control":        "Data Control",
    "p_control":        "You have full control over your data. You can reset all progress or remove downloaded language packs at any time through the Settings screen.",
    "h_tracking":       "No Third-Party Tracking",
    "p_tracking":       "This app contains no advertisements, no analytics, and no third-party tracking SDKs of any kind.",
    "h_permissions":    "Permissions",
    "p_permissions":    "The app does not request access to your camera, microphone, location, contacts, or any sensitive system resources beyond standard audio playback.",
    "h_contact":        "Contact",
    "p_contact":        "For questions about this privacy policy, please contact us at",
    "back":             "5001 Words",
}

APP_DESC_EN = """5001 Words — Multilingual Vocabulary Flashcards

Master vocabulary in 8 languages with 5,001 flashcards per deck. Works on iPhone, iPad, and Apple Watch.

LANGUAGES INCLUDED:
• Spanish – English 🇪🇸 (bundled, no download needed)
• Yiddish – English ✡️ (bundled)
• Ukrainian – English 🇺🇦
• French – English 🇫🇷
• German – English 🇩🇪
• Dutch – English 🇳🇱
• Hebrew – English 🇮🇱 (with niqqud vowel marks)
• Spanish – Ukrainian 🇪🇸🇺🇦

KEY FEATURES:
• 5,001 cards per language deck — carefully curated vocabulary
• Native-speaker quality audio — Microsoft Neural TTS voices, copyright-free
• Auto-play — cards read aloud automatically as you swipe
• Bidirectional learning — study in both directions with one tap
• Focus Mode — drill a set of 20 unlearned words until mastered
• Mark as Learned — hides words you know, tracks your progress
• Downloadable packs — language packs download on demand (~30–54 MB each)
• Full Apple Watch support — same features on your wrist
• Privacy-first — no account, no tracking, all data stays on your device

HOW IT WORKS:
1. Select a language deck from Settings
2. Download the language pack (includes word list + audio)
3. Swipe cards left and right to navigate
4. Tap to flip and reveal the translation
5. Double-tap to hear the word pronounced
6. Mark words as learned to track your progress

PERFECT FOR:
• Language learners building core vocabulary
• Students preparing for exams
• Travelers learning practical phrases
• Heritage speakers reconnecting with their language
• Anyone who wants to learn on the go

No subscription. No ads. No account required. Just vocabulary."""

def translate_text(text: str, lang: str) -> str:
    google_lang = LANG_MAP.get(lang, lang)
    try:
        return GoogleTranslator(source="en", target=google_lang).translate(text)
    except Exception as e:
        print(f"  Translate error ({lang}): {e}")
        return text

def translate_dict(d: dict, lang: str) -> dict:
    google_lang = LANG_MAP.get(lang, lang)
    translator = GoogleTranslator(source="en", target=google_lang)
    SEP = "\n||||\n"
    keys = list(d.keys())
    values = list(d.values())
    result = {}
    for i in range(0, len(keys), 15):
        batch_keys = keys[i:i+15]
        batch_vals = values[i:i+15]
        joined = SEP.join(batch_vals)
        try:
            translated = translator.translate(joined)
            parts = translated.split(SEP)
            if len(parts) != len(batch_keys):
                parts = [translator.translate(v) for v in batch_vals]
        except Exception as e:
            print(f"  Batch error: {e}")
            parts = batch_vals
        for k, v in zip(batch_keys, parts):
            result[k] = (v or d[k]).strip()
        time.sleep(0.2)
    return result

def write_privacy_html(lang: str, t: dict):
    html = f"""<!DOCTYPE html>
<html lang="{lang}"{' dir="rtl"' if lang == 'he' else ''}>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{t['title']} - 5001 Words</title>
    <style>
        * {{ margin: 0; padding: 0; box-sizing: border-box; }}
        body {{
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #1a6b3c 0%, #2d4a8a 100%);
            min-height: 100vh; padding: 20px;
        }}
        .container {{
            background: white; border-radius: 20px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            max-width: 800px; margin: 0 auto; padding: 40px;
        }}
        .back-link {{ display: inline-block; color: #2d4a8a; text-decoration: none; font-size: 14px; margin-bottom: 20px; }}
        .back-link:hover {{ text-decoration: underline; }}
        .back-link::before {{ content: '← '; }}
        h1 {{ color: #333; margin-bottom: 8px; font-size: 32px; }}
        .updated {{ color: #999; font-size: 13px; margin-bottom: 24px; }}
        h2 {{ color: #333; margin-top: 25px; margin-bottom: 10px; font-size: 20px; }}
        p {{ color: #555; line-height: 1.7; margin-bottom: 12px; }}
        a {{ color: #2d4a8a; }}
        @media (max-width: 600px) {{ .container {{ padding: 24px 16px; }} h1 {{ font-size: 24px; }} }}
    </style>
</head>
<body>
    <div class="container">
        <a href="/5001words/?lang={lang}" class="back-link">{t['back']}</a>
        <h1>{t['title']}</h1>
        <p class="updated">{t['updated']}</p>
        <p>{t['intro']}</p>
        <h2>{t['h_storage']}</h2><p>{t['p_storage']}</p>
        <h2>{t['h_collection']}</h2><p>{t['p_collection']}</p>
        <h2>{t['h_audio']}</h2><p>{t['p_audio']}</p>
        <h2>{t['h_control']}</h2><p>{t['p_control']}</p>
        <h2>{t['h_tracking']}</h2><p>{t['p_tracking']}</p>
        <h2>{t['h_permissions']}</h2><p>{t['p_permissions']}</p>
        <h2>{t['h_contact']}</h2>
        <p>{t['p_contact']} <a href="mailto:5001words@turevskiy.com">5001words@turevskiy.com</a>.</p>
    </div>
</body>
</html>"""
    (PP_DIR / f"privacy-policy-{lang}.html").write_text(html, encoding="utf-8")

# Write English privacy policy HTML
write_privacy_html("en", PRIVACY_SECTIONS_EN)
# Write English app description
(DESC_DIR / "app-description.txt").write_text(APP_DESC_EN, encoding="utf-8")
print("English done.")

for lang in LANGUAGES:
    print(f"Processing {lang}...")
    try:
        t = translate_dict(PRIVACY_SECTIONS_EN, lang)
        write_privacy_html(lang, t)
        desc = translate_text(APP_DESC_EN, lang)
        (DESC_DIR / f"app-description-{lang}.txt").write_text(desc, encoding="utf-8")
        print(f"  ✓ {lang}")
    except Exception as e:
        print(f"  ✗ {lang}: {e}")
    time.sleep(0.3)

print("\nAll done.")
