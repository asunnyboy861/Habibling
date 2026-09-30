# Habibling — App Review Information

Prepared for App Store Connect submission. Everything below reflects the shipped code as of 2026-09-30.

## 1. App Overview (Review Notes summary)

Habibling is a pixel-pet habit tracker. Every completed habit feeds a tiny 16×16 pixel pet that hatches from an egg, grows through 4 stages, and never dies — missing a day only makes it nap. Core loop: check in → pet gets fed → vibe % (elastic EMA score) rises → pet evolves.

- **Primary language**: English (US). No other localizations at launch.
- **Minimum iOS**: 17.0. Watch app requires watchOS 10.0.
- **Sign in**: NOT required. No accounts, no login, no email collection. iCloud sync uses the user's own iCloud account via CloudKit private database.
- **Demo account**: Not applicable (no account system).

## 2. AI Features (full disclosure)

Habibling has three AI engines, with automatic fallback:

| Engine | Availability | Cost to user | Data handling |
|--------|-------------|--------------|---------------|
| Apple Intelligence (FoundationModels) | iOS 26+ devices with Apple Intelligence enabled | Free, unlimited | Fully on-device, Private Cloud Compute when needed |
| GLM Cloud AI | Habibling Cloud+ subscription ($1.99/mo) | Subscription | Sends anonymized habit names + counters to `cramjam-api.calcs.top` (Cloudflare Worker proxy for GLM API); no personal identifiers beyond a random device-generated userId |
| Rule-based text pool | Always (fallback) | Free, unlimited | Nothing leaves the device |

AI feature surface: daily pet encouragement line, AI habit plan (onboarding), weekly Pixel Post, monthly deep report.

**Review notes for AI**: All AI features work without any subscription on devices with Apple Intelligence. On other devices, the rule engine produces all the same UI surfaces (templated text) for free — no feature is AI-gated. A demo/preview of cloud AI is NOT available without subscription, but the same content is produced by the free rule engine, so reviewers can experience every screen.

## 3. AI Configuration / API Keys

- The GLM Cloud proxy devKey (`cramjam-dev-2026`) is compiled in **Debug builds only** (`#if DEBUG`). It does not exist in Release/App Store builds — Release builds send `{appId, userId, appTransaction}` where `appTransaction` is the App Store-signed transaction JWS from `Transaction.currentEntitlements`. The Worker verifies the ES256 signature, certificate chain (anchored to Apple Root CA - G3), bundleId whitelist, refund status, and expiry; it accepts both Production and Sandbox receipts (TestFlight and App Review use the Sandbox channel). Rate limiting (30 req/hour + 200 req/day per appId:userId) protects the API key from abuse; normal use is unaffected.
- No API keys, no secrets in the App Store build. (Verified by repo scan before push.)

## 4. Subscriptions & IAP

| Product | ID | Type | Price |
|---------|----|------|-------|
| Habibling Plus | `com.zzoutuo.Habibling.plus.lifetime` | Non-consumable | $24.99 one-time |
| Habibling Cloud+ | `com.zzoutuo.Habibling.cloud.monthly` | Auto-renewable subscription | $1.99/month |

- StoreKit configuration file: `Habibling.storekit` (for local testing).
- Paywall shows both products, Restore Purchases button, legal links (Privacy Policy + Terms of Use) directly below the buy buttons, and full auto-renewal disclosure text (charge at confirmation, renews unless canceled ≥24h before period end, manage in App Store settings).
- The pet never dies and no core feature is paywalled: free tier includes unlimited habits, check-ins, widgets, iCloud sync, JSON export.
- Contact Support screen (Settings → Contact Support) includes a "Purchases & billing" topic; tickets POST to our endpoint and fall back to mailto.

## 5. Permissions (Info.plist)

| Permission | Purpose string | Used by |
|-----------|----------------|---------|
| Microphone | Voice notes for habit journals, transcribed on-device | SpeechService (NoteSheet dictation) |
| Speech Recognition | On-device transcription of voice notes | SpeechService (requiresOnDeviceRecognition when supported) |
| Camera | **REMOVED in this build** — no camera feature ships in v1.0 | — |

No location, contacts, photos, health, notifications-permission surprises. Local notifications are requested contextually during onboarding (reminder opt-in).

## 6. Background & System Features

- **BGAppRefreshTask** (`com.zzoutuo.Habibling.refresh`): refreshes widget snapshot + Live Activity every ~4h. Declared in `BGTaskSchedulerPermittedIdentifiers`.
- **Background Modes**: `processing`, `remote-notification` (CloudKit push).
- **Live Activity / Dynamic Island**: today's progress ring + pet; auto-rebuilds at day rollover.
- **Widgets**: home-screen pet widget (small/medium, interactive check-in via App Intents), lock-screen (rectangular/inline/circular).
- **Watch app**: standalone-ish companion; mirrors today's tiles via WCSession `applicationContext`, check-ins sync back.
- **URL scheme**: `habibling://` (e.g. `habibling://today` from widgets).
- **Encryption**: `ITSAppUsesNonExemptEncryption = false` (HTTPS/standard crypto only).

## 7. Data & Privacy ("Nutrition label")

Collected: **nothing**. No analytics SDKs, no ads, no tracking, no third-party frameworks.

- Feedback form (optional name/email) POSTs to `https://msg.calcs.top/api/feedback` — user-initiated only, contents shown in-UI before sending; mailto fallback available.
- Cloud AI (Cloud+ only) sends habit names/counts with a random userId to the GLM proxy; disclosed on the Cloud+ paywall and in privacy policy.
- Everything else (habits, completions, notes, mood, pet) stays in SwiftData/local + the user's private CloudKit database.

## 8. Support & Legal Links

- Support: https://asunnyboy861.github.io/Habibling/support.html
- Privacy Policy: https://asunnyboy861.github.io/Habibling/privacy.html
- Terms of Use (EULA incl. auto-renewal terms): https://asunnyboy861.github.io/Habibling/terms.html
- Contact email: asunnyboy168@icloud.com

## 9. Reviewer Tips

1. Launch → onboarding creates pet + first habit (also the AI habit plan, rule engine on simulator).
2. Check in from Today tab or the home-screen widget — pet reacts (berry burst + haptic + chirp).
3. Stats tab → weekly Pixel Post works free (rule engine on simulator); monthly deep report explains the tier boundary and opens the paywall on simulator (no Apple Intelligence).
4. Settings → Contact Support, Data (JSON/CSV), theme, day-start hour are all functional.
5. StoreKit testing config is bundled (`Habibling.storekit`) — purchases can be exercised in the simulator via the paywall.
