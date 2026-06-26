# App Store Submission Guide — 5001 Words

## What You Need Before Starting

### 1. Apple Developer Account
- Cost: $99/year
- Sign up: https://developer.apple.com/programs/enroll/
- Takes 24–48 hours to activate
- You'll need a valid Apple ID and a credit card

### 2. External Web Pages to Create

You need two pages hosted somewhere (GitHub Pages, your own domain, etc.):

| Page | URL example | Purpose |
|------|------------|---------|
| **Privacy Policy** | `turevskiy.com/5001words/privacy` | Required by Apple; link in App Store Connect |
| **Support / Contact** | `turevskiy.com/5001words/` | Required support URL in App Store Connect |

**Simplest option — GitHub Pages:**
1. Create repo `5001words-site` on GitHub
2. Add `index.html` (contact/support page) and `privacy.html`
3. Enable GitHub Pages in repo Settings → Pages
4. Your URLs become: `https://yourusername.github.io/5001words-site/`

**Content for the privacy page:** copy from `Other/appleStore/privacy-policy-en.md`

**Content for the support page:** a simple page with `5001words@turevskiy.com` and a brief app description.

### 3. Screenshots

Required sizes (take in Xcode Simulator):

| Device | Size |
|--------|------|
| iPhone 6.7" (required) | 1290 × 2796 px |
| iPhone 6.5" (required) | 1284 × 2778 px |
| Apple Watch 45mm (required) | 396 × 484 px |
| Apple Watch 41mm | 368 × 448 px |

**How to take:**
```bash
# In Xcode: run app in iPhone 16 Pro Max simulator
# Then: Device menu → Screenshot (Cmd+S)
# Or via terminal:
xcrun simctl io booted screenshot ~/Desktop/screenshot.png
```

**Suggested screens to capture:**
1. Main card screen (word showing)
2. Card flipped (translation visible)
3. Settings screen (showing language pack list)
4. Watch app main card view
5. Watch settings screen

### 4. App Information to Prepare

| Field | Value |
|-------|-------|
| App Name | 5001 Words |
| Subtitle | Multilingual Vocabulary Flashcards |
| Bundle ID | `com.turevskiy.YetAnotherLearningCards` |
| Category (Primary) | Education |
| Category (Secondary) | Reference |
| Age Rating | 4+ |
| Price | Free |
| Version | 1.0 |
| Keywords | vocabulary,flashcards,language,spanish,french,german,dutch,hebrew,ukrainian,words,learn |

---

## Step-by-Step Submission

### Step 1 — Prepare Xcode Project

1. Open: `YetAnotherLearningCards/YetAnotherLearningCards.xcodeproj`
2. Select the **YetAnotherLearningCards** target → General tab
3. Verify:
   - Display Name: `5001 Words` (change if needed)
   - Bundle Identifier: `com.turevskiy.YetAnotherLearningCards`
   - Version: `1.0`
   - Build: `1`
4. Signing & Capabilities → select your Team → "Automatically manage signing"

### Step 2 — Build & Archive

1. Select destination: **Any iOS Device (arm64)** (not a simulator)
2. Product → **Archive** (Cmd+Shift+B if mapped)
3. Organizer opens automatically when done
4. Click **Validate App** → fix any errors
5. Click **Distribute App** → App Store Connect → Upload

### Step 3 — Create App in App Store Connect

1. Go to https://appstoreconnect.apple.com
2. My Apps → **+** → New App
3. Fill in:
   - Platforms: iOS ✓ (watchOS is bundled with iOS)
   - Name: `5001 Words`
   - Primary Language: English (U.S.)
   - Bundle ID: select `com.turevskiy.YetAnotherLearningCards`
   - SKU: `5001words-1`
4. Click Create

### Step 4 — Fill in App Store Listing

Under **1.0 Prepare for Submission**:

- **Description:** paste from `Other/appleStore/app-description.txt`
- **Keywords:** `vocabulary,flashcards,language,spanish,french,german,dutch,hebrew,ukrainian,words,learn`
- **Support URL:** your support/contact page URL
- **Privacy Policy URL:** your hosted privacy policy URL
- **Marketing URL:** (optional) your app landing page
- **Screenshots:** upload the screenshots you took in Step 1

### Step 5 — App Privacy

Under **App Privacy** → Get Started:
- "Does your app collect data?" → **No**
- Click Next → Publish

(The app stores everything locally; no data leaves the device.)

### Step 6 — Age Rating

Click Edit next to Age Rating, answer all questions as **None/No**. Result: **4+**.

### Step 7 — Select Build & Answer Compliance

1. Under Build, click **+** and select the uploaded build
2. Export Compliance: "Does your app use encryption?" → **No** (HTTPS only = exempt)
3. Advertising Identifier: **No**

### Step 8 — Submit

1. Check the final checklist (see below)
2. Click **Add for Review** → Submit to App Review
3. Typical wait: 24–48 hours

---

## Pre-Submission Checklist

- [ ] Privacy policy hosted at a public URL
- [ ] Support/contact page hosted at a public URL
- [ ] Screenshots uploaded for iPhone 6.7" and Apple Watch 45mm (minimum)
- [ ] App description filled in (from `app-description.txt`)
- [ ] Keywords set (under 100 characters)
- [ ] Build uploaded and processed (check TestFlight tab)
- [ ] Age rating completed (4+)
- [ ] App Privacy answered (no data collected)
- [ ] Export compliance answered
- [ ] Signing set up with your developer account

---

## After Approval

- App goes live within a few hours of approval
- App Store link format: `https://apps.apple.com/app/id[APP_ID]`
- Monitor crash reports: Xcode → Organizer → Crashes
- For updates: increment Version or Build in Xcode, re-archive, re-upload

## Common Rejection Reasons & Fixes

| Reason | Fix |
|--------|-----|
| Metadata rejection | Screenshots must match actual app UI |
| Missing privacy policy | Host the policy at a reachable URL |
| Crash on launch | Test on a real device before submitting |
| Missing support URL | Create the contact page (see Step 2 above) |
