# Publishing DecisionDeck to the App Store

## 1. Apple Developer account
- Enroll at developer.apple.com/programs ($99/year) if you haven't already.

## 2. Fix the bundle identifier
The project currently uses `com.example.DecisionDeck` — a placeholder that won't work for submission.
- In Xcode: select the target → Signing & Capabilities → change `PRODUCT_BUNDLE_IDENTIFIER` to something unique you own, e.g. `com.toddzhang.decisiondeck`.
- Set your Team under Signing & Capabilities.

## 3. Secure the API keys before shipping
`Config.swift` has the Gemini + Places keys hardcoded and gitignored — fine for local dev, but an App Store binary can be decompiled and the keys extracted since they ship inside the app bundle. Before real users get this build:
- Restrict the keys in Google Cloud Console (HTTP referrer / iOS bundle ID restrictions, API-specific restrictions), or
- Proxy the calls through a small backend so keys never leave your server.

## 4. App Store Connect setup
- Go to appstoreconnect.apple.com → My Apps → New App.
- Fill in: name (check availability here), primary language, bundle ID (must match Xcode), SKU (any internal string).
- Fill in app info: category, age rating, privacy policy URL (required — even a simple static page saying what data you collect, e.g. none/location for place search).

## 5. Prepare store assets
- App icon (1024x1024, no alpha/rounded corners).
- Screenshots for at least one required device size (6.7" iPhone covers most requirements).
- Description, keywords, support URL, marketing URL (optional).

## 6. Archive and upload
1. In Xcode, select **Any iOS Device (arm64)** as the destination (not a simulator).
2. Product → Archive.
3. In the Organizer window, click **Distribute App** → App Store Connect → Upload.
4. Xcode handles signing automatically if "Automatically manage signing" is on.

## 7. TestFlight (recommended before public release)
- Once the build finishes processing in App Store Connect, add it under TestFlight.
- Install TestFlight on your phone and test the real build (not simulator) — this is where key restrictions or network issues would surface.

## 8. Submit for review
- Attach the uploaded build to your app version in App Store Connect.
- Fill in "App Review Information" (contact info, demo notes if needed).
- Submit for review. Typical turnaround is 24–48 hours.

## 9. After approval
- Release manually or set it to auto-release on approval.

## Name ideas considered
- DecisionDeck (current)
- ShortlistIt, PickDeck, NarrowIt
- SwipeShortlist, Culled, KeepSwipe, DeckIt
- Undecided, LessChoice, Pared, Whittle
- Sift, Shortr, Picky
