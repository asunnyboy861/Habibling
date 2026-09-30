# Pricing Configuration

## Monetization Model: Freemium with One-Time IAP + Optional Cloud Add-on Subscription

Habibling is free to download with a genuinely generous free tier (unlimited habits, all home-screen widgets, free iCloud sync). A one-time lifetime purchase (Plus) unlocks depth features — no subscription is ever required for core use. A separate optional auto-renewable subscription (Cloud+) hosts GLM cloud AI. The pet never dies and the app never ambushes with paywalls; tier boundaries are printed on the store page and in-app.

## Subscription Group
- **Group Name**: Habibling Cloud
- **Reference Name**: Habibling Cloud
- **Products in group**: Habibling Cloud+ Monthly (only auto-renewable product)

## Subscription Tiers (Auto-Renewable)

### 1. Cloud+ Monthly
- **Reference Name**: Habibling Cloud+ Monthly
- **Product ID**: `com.zzoutuo.Habibling.cloud.monthly`
- **Type**: Auto-renewable subscription
- **Price**: $1.99 USD per month (cancel anytime, one tap)
- **Display Name**: `Habibling Cloud+` (17 chars, ≤35 ✅)
- **Description**: `Monthly GLM cloud AI deep reports, cancel anytime` (50 chars, ≤55 ✅)
- **Localization**: English (US)
- **Subscription Group**: Habibling Cloud
- **Restore Purchases**: ✅ Required
- **Boundary note**: Cloud+ unlocks cloud AI features ONLY (GLM monthly deep report, GLM weekly Pixel Post, GLM encouragement lines — all available even on devices without Apple Intelligence). It does NOT unlock Plus features (Watch, Live Activities, 4K export, themes). Plus does NOT include Cloud+ — they are independent purchases.

## One-Time Purchases (Non-Consumable)

### 1. Plus Lifetime
- **Reference Name**: Habibling Plus Lifetime
- **Product ID**: `com.zzoutuo.Habibling.plus.lifetime`
- **Type**: Non-consumable (one-time purchase, permanently unlocked, Family Sharing enabled)
- **Price**: $24.99 USD (one-time; launch sale $14.99 handled via App Store Connect price schedule, not code)
- **Display Name**: `Habibling Plus` (14 chars, ≤35 ✅)
- **Description**: `Lifetime unlock: all Plus features, Family Sharing` (50 chars, ≤55 ✅)
- **Localization**: English (US)
- **Restore Purchases**: ✅ Required
- **Note**: Zero ongoing server cost for Plus features (CloudKit is free, on-device AI has no marginal cost, no third-party dependencies) — safe to sell as lifetime.
- **Differentiation note**: Plus unlocks depth features (adult pet evolution + seasonal outfits, all themes/icons, 4K yearly mosaic export, full stats, Watch app, Live Activities, lock-screen widgets, Siri/App Intents, unlimited on-device AI, CSV/JSON import+export). It does NOT include Cloud+ cloud AI.

## Free Tier (Default)

- **Price**: Free, forever, transparently
- **Features**:
  - Unlimited habits (competitor limits free habits — we never do)
  - Full check-in with berry burst + haptic + chirp
  - Counter, timer, and negative habits with partial credit
  - Yesterday rescue card + editable history calendar
  - Vibe % elastic score (never zeroes your progress)
  - Pixel mosaic heatmap (per-habit + overall)
  - Mood diary (one pixel per day)
  - Categories
  - Free iCloud sync via private CloudKit database (no account)
  - Home-screen pet widget (interactive check-in) — free
  - Pet egg → hatchling evolution
  - AI habit plan (1×), pet line (daily), weekly Pixel Post (1×/month) — on-device
  - JSON export
- **Conversion hooks** (this app's own value only, no competitor prices):
  - "Your pet grows up with Plus" — adult evolution, seasonal outfits, full dex
  - "Take Habibling everywhere" — Watch app, Dynamic Island, lock-screen widgets
  - "One coffee, forever" — Plus is one payment, not a subscription; price table shows exactly what free includes, no dark patterns

## Pro Features Unlocked (All Paid Tiers)

Cross-referenced with capabilities.md (all listed features are implemented in PHASE 4+5).

| Feature | Free | Plus ($24.99 lifetime) | Cloud+ ($1.99/mo) |
|---------|:----:|:----------------------:|:-----------------:|
| Unlimited habits | ✅ | ✅ | ✅ |
| Check-in / rescue card / editable history | ✅ | ✅ | ✅ |
| Negative, counter, timer habits | ✅ | ✅ | ✅ |
| Mood diary | ✅ | ✅ | ✅ |
| iCloud sync (private CloudKit) | ✅ | ✅ | ✅ |
| Home-screen pet widget (interactive) | ✅ | ✅ | ✅ |
| Pet egg → hatchling evolution | ✅ | ✅ | ✅ |
| On-device AI: plan 1×, pet line daily, weekly post 1×/mo | ✅ | ✅ | ✅ |
| JSON export | ✅ | ✅ | ✅ |
| Pet adult evolution + all seasonal outfits + full dex | ❌ | ✅ | ❌ |
| All themes & alternate app icons | ❌ | ✅ | ❌ |
| Full stats, trends, yearly heatmap | ❌ | ✅ | ❌ |
| Yearly mosaic 4K export with watermark | ❌ | ✅ | ❌ |
| Watch app | ❌ | ✅ | ❌ |
| Live Activities / Dynamic Island pet | ❌ | ✅ | ❌ |
| Lock-screen widgets | ❌ | ✅ | ❌ |
| Siri / App Intents check-in | ❌ | ✅ | ❌ |
| Unlimited on-device AI (regenerate pet lines, plans, posts) | ❌ | ✅ | ❌ |
| CSV export + JSON/CSV import | ❌ | ✅ | ❌ |
| GLM monthly deep data report | ❌ | ❌ Not included — separate Cloud+ | ✅ |
| GLM weekly Pixel Post & encouragement (no Apple Intelligence needed) | ❌ | ❌ Not included — separate Cloud+ | ✅ |

## Free Trial

- **Duration**: None — Plus is a non-consumable (no trials supported) and Cloud+ is priced low enough that the transparent free tier acts as the trial. No intro offers at launch.

## Policy Pages Required

- Support Page: ✅ (includes subscription management + cancellation instructions for Cloud+, and restore-purchase instructions)
- Privacy Policy: ✅
- Terms of Use (EULA): ✅ (REQUIRED — auto-renewable subscription present; must include auto-renewal terms)
- **Total policy pages**: 3

## Apple IAP Compliance Checklist

- [x] Auto-renewal terms will be included in Terms of Use
- [x] Cancellation instructions will be included in Support Page
- [x] Pricing clearly stated in PaywallView (3-tier honest table, no dark patterns)
- [x] No free trial terms needed (none offered)
- [x] Restore purchases functionality implemented (StoreKit 2 `Transaction.currentEntitlements`)
- [x] No external payment links (Guideline 3.1.1)
- [x] No price references to outside-App-Store options (no competitor price comparisons anywhere)
- [x] All IAP descriptions ≤ 55 characters
- [x] All IAP display names ≤ 35 characters
- [x] IAP type purity: non-consumable (Plus) and auto-renewable (Cloud+) kept in separate sections; Cloud+ is the only subscription-group product
- [x] Add-on scoping: Cloud+ features marked "not included" in Plus column — paywall matches entitlements exactly
- [x] No free-generation counting code (`freeGenerationsUsed` / `maxFreeGenerations` forbidden)
