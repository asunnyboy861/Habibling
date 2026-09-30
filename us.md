# Habibling - iOS Development Guide

> Source: TR-20260917-像素习惯Habibling复刻升级-操作指南.MD (translated & adapted)
> Target Market: United States (English-only product) | Date: 2026-09-30

## Executive Summary

**Habibling** (Habit + -ling, "your pixel pet, one pixel a day") is a native iOS habit tracker where every completed habit grows a pixel pet. Core promise: **"One pixel a day."** The pet is a *mirror* of your data — it never dies, never gets sick, never punishes you. Miss a day? It naps under a pixel blanket.

**Target audience (US market)**: self-discipline beginners (25-40), Finch/virtual-pet migrants (18-34, female-skewing), ADHD/executive-dysfunction users, gamification enthusiasts fleeing Habitica complexity.

**Six-axis differentiation vs Habit Pixel ($3,142 MRR competitor)**:
1. **Elastic scoring "Vibe %"** (EMA α=0.05) — missing a day never zeroes your progress
2. **Editable history** — rescue yesterday with one tap; edit any past day
3. **Free iCloud sync** (CloudKit private DB, no account) — competitor has none
4. **Zero-maintenance pet** — reflects data, never needs feeding, never dies (anti-Finch-fatigue)
5. **AI double engine** — Apple Foundation Models on-device (free) + GLM-5.3-Flash cloud (managed proxy) for deep reports & photo logging
6. **Watch app + Live Activity/Dynamic Island + transparent pricing** — competitor has none; native app ~15MB vs competitor's 150MB

**Red line**: the pet NEVER dies/gets sick/leaves/loses HP. No guilt mechanics, ever.

**Naming & metadata (locked)**:
- App Store Title (30): `Habibling: Pixel Pet Habits`
- Subtitle (30): `Grow a pet, one habit a day`
- Slogan: `One pixel a day.`
- Keywords (100): `habit tracker,daily streak,pet,motivation,pixel,heatmap,routine,goals,self care,productivity`
- Promo Text (170): `Your habits hatch a tiny pixel pet. Miss a day? It naps — never dies. Free iCloud sync, no account, no guilt. One pixel a day.`

## Competitive Analysis

| App | Strengths | Weaknesses | Our Advantage |
|-----|-----------|------------|---------------|
| **Habit Pixel** (id6742632433, MRR $3,142, 4.9★) | Pixel heatmap, Pip pet, PPP pricing, 12 languages, 150MB Flutter | No sync (5 isolated platforms), no AI/Watch/Live Activities, raw streak anxiety, widget paywall, free habit limit | Free unlimited habits, free widgets, free iCloud sync, elastic Vibe %, editable history, Watch + Dynamic Island + AI, 10× smaller |
| **Finch** (4.9★, 737K ratings) | Best-in-class pet attachment, self-care breadth | Gamification fatigue ("pet becomes a chore in month 3"), subscription fatigue, features shallow | Zero-maintenance pet (never needs feeding), one-time purchase, data-driven not chore-driven |
| **Habitica** | Deep RPG gamification | HP-loss punishment creates anxiety ("I was bullied out of a party"), complex, iOS lags | No punishment mechanics, minimal complexity, pixel charm without HP anxiety |
| **Streaks** (Apple Design Award) | Polished, native, reliable | No free tier, no pet, no sync story beyond iCloud, $ واحد upfront with locked analytics | Free tier is genuinely generous (unlimited habits + widgets + sync) |
| **HabitKit** | Grid UX loved, solo-dev trust | Top complaint (119👍): cannot edit history | History fully editable + yesterday rescue card |
| **Habit Pixel: Streak Tracker** (clone, LEAN ASIA) | Proof the niche is being contested | Shallow mood+heatmap clone | Our moat: pet IP + dex + seasonal ops + sync/AI/Watch depth |

**Category pain points (1-3★ review corpus, 2026 H1)**: ① streak-break anxiety > habit failure itself; ② silent sync failure data loss; ③ gamification fatigue; ④ free-tier ambush + analytics paywall; ⑤ cannot edit history; ⑥ no AI/Watch/Live Activities. Habibling is designed to kill all six.

## Apple Design Guidelines Compliance

- **iOS 26 Liquid Glass native feel**: SwiftUI native components + system materials. Pixel art appears ONLY where it belongs (pet, mosaic, app icon, pet dialogue font) — UI controls stay native. Pixel is flavor, not filter.
- **Human Interface Guidelines — Accessibility**: Dynamic Type to XXXL, VoiceOver labels on all interactive elements (mosaic announces "Habit mosaic, current vibe 87 percent"), Reduce Motion fully honored (all animations optional).
- **SF Symbols + SF Pro** for all UI; pixel font (Press Start 2P class, SIL OFL) ONLY for pet dialogue.
- **Dark Mode**: automatic adaptation (US dark usage >60%). Pet colors tint from most-checked habit color.
- **Haptics**: UINotificationFeedbackGenerator .success on check-in (≤300ms animation budget).
- **Widgets**: WidgetKit with App Group JSON snapshot (extensions NEVER touch SwiftData — architecture iron rule).
- **Privacy**: no account, no telemetry, no third-party SDK (zero dependencies). iCloud sync in user's private CloudKit DB. Privacy label: Data Not Collected.

## ⚠️ App Store Compliance — AI Features

### Apple Intelligence (Default Free AI Backend)
This app uses Apple Intelligence (on-device Foundation Models) as the default AI backend. On supported devices (iPhone 15 Pro+, iOS 26+), AI features work immediately after download with zero configuration.

**iOS Version Handling**:
- **iOS 26+**: Apple Intelligence is default for pet lines / habit plan / weekly Pixel Post. Works out-of-the-box.
- **iOS < 26**: Apple Intelligence unavailable. App falls back to: ① rule-engine copy pools (pre-written warm lines, zero guilt) for pet dialogue; ② GLM cloud proxy (below) if Cloud+ is active; ③ AI plan/weekly review buttons hidden when no engine is available — NEVER show clickable AI buttons that lead to errors.
- **Simulator**: Apple Intelligence is not available on simulators. For testing, the GLM cloud proxy is used.

### GLM Cloud Proxy (Managed Backend — NOT user BYO key)
Cloud AI (monthly deep report, photo habit logging) calls a **managed Cloudflare Worker proxy** holding the developer's GLM key. Users never paste API keys. Access is gated by Cloud+ subscription in production (StoreKit 2 `AppTransaction` JWS) and by devKey in development.

**Hard rules (verified 2026-09-30, must be encoded in client)**:
1. Endpoint: `https://cramjam-api.calcs.top` (backup: `https://cramjam-proxy.iocompile67692.workers.dev`)
2. Request body: `{"appId":"habibling","userId":"<Keychain UUID>","payload":{...}}` (+ `devKey` in DEBUG, + `appTransaction` in release)
3. `model: "glm-5.3-flash"`; **must** pass `"thinking":{"level":"low"}` (model forces thinking; omitting errors 1210)
4. **max_tokens must be generous**: ≥4096 text, ≥8192 vision/structured (reasoning tokens count toward budget; short budget → empty content, `finish_reason:"length"`)
5. Structured output: strong system prompt + `response_format:{"type":"json_object"}`; client ignores `reasoning_content`
6. Vision: `image_url` with base64 data URL
7. Error handling: 429 → friendly "Taking a short break, try again soon" (rate limit 30/hr + 200/day per appId:userId); 401 → restore-purchase prompt; 400 → client bug

**Guideline 2.1(a) — App Completeness**: AI features must work on reviewer devices. Apple FM covers iOS 26+; rule-engine fallback covers the rest. Create `app_review_info.md` describing demo behavior.

**Dead Code Prevention**:
- ❌ NEVER add: `freeGenerationsUsed`, `maxFreeGenerations`, `canGenerateFree`, `incrementGenerationCount()`
- Entitlement logic: `canUseOnDeviceAI = appleIntelligenceAvailable || isPlus`; `canUseCloudAI = isCloudPlus` — no free-generation counters.

## ⚠️ App Store Compliance — Subscriptions

### Guideline 3.1.2(c) — Subscription Information
The Cloud+ auto-renewable subscription requires the Paywall view to show:
- Functional link to Privacy Policy
- Functional link to Terms of Use (EULA)
- Subscription title, length ($1.99/month), and price
- Auto-renewal disclosure text

### Transparent Pricing (anti-paywall-ambush)
- **Free** ($0, permanent): unlimited habits, full check-in/backfill/rescue/negative habits/mood diary/categories, ALL widgets free, free iCloud sync, egg→hatchling evolution, AI plan 1× + pet line daily + weekly post 1×/month, JSON export
- **Plus** ($24.99 lifetime, launch $14.99, Family Sharing): adult evolution + all seasonal outfits + all themes/icons, yearly mosaic 4K export, full stats, Watch app, Live Activities/Dynamic Island, lock-screen widgets, Siri/App Intents, unlimited on-device AI, CSV/JSON import+export
- **Cloud+** ($1.99/month, optional add-on, never bundled into Plus): GLM monthly deep report + photo habit logging + pet long-term memory. BYO-free alternative not needed (proxy is managed).
- Store page + in-app store page must show the honest 3-tier table: "No subscription required. Ever." (Plus), "Cancel anytime, one tap" (Cloud+).

## Technical Architecture

- **Language**: Swift 5.9+ / Swift 6 concurrency-safe
- **UI**: SwiftUI, `@Observable` macro, iOS 17+ deployment target
- **Data**: SwiftData `@Model` + CloudKit private database (`.private("iCloud.com.zzoutuo.Habibling")`), `VersionedSchema` + migration plan
- **Extensions**: WidgetKit (home + lock screen), ActivityKit (Live Activity/Dynamic Island), Watch app (SwiftUI, watchOS 10+)
- **Intents**: App Intents (Siri "Mark [habit] in Habibling", notification Done action)
- **IAP**: StoreKit 2 (non-consumable lifetime + auto-renewable monthly)
- **Notifications**: UserNotifications, 28-day rolling schedule, UNNotificationCategory with Done/Snooze actions
- **AI**: FoundationModels (iOS 26+, `@available` gated) + URLSession GLM proxy client
- **Audio**: AVFoundation 8-bit chirp (procedurally generated, no asset bloat)
- **Zero third-party dependencies** — no SPM packages, no CocoaPods

### CloudKit shape rules (from Kadō CLAUDE.md — mandatory)
- All `@Relationship` properties must be optional
- All properties must have default values
- Unique constraints via `#Unique`
- Container init: `ModelContainer(for: Schema([Habit, Completion, MoodEntry], version: SchemaV1.self), migrationPlan: MigrationPlan.self, configurations: ModelConfiguration(cloudKitDatabase: .private("iCloud.com.zzoutuo.Habibling")))`

### Data integrity — five guards (from guide §6.2, all mandatory)
1. **Day bucketing**: every record keyed by `localCalendar.startOfDay(for: date)`; "Day Starts At" setting (0-6h) shifts midnight; changing the setting NEVER recomputes history
2. **Unique constraint**: `(habitPersistentID, dayBucket)` unique — re-check-in updates `value` (accumulate), never inserts a duplicate row
3. **Backfill recompute**: editing history invalidates EMA score cache from that day forward; pet (pure function) "grows back" automatically
4. **Sync conflicts**: CloudKit record-level last-writer-wins + completions are idempotent by unique key; sync status shown honestly in Settings (failure states show the reason)
5. **Widget/Watch freshness**: extensions read ONLY the App Group JSON snapshot (`group.com.zzoutuo.Habibling`); app writes snapshot + `WidgetCenter.reloadAllTimelines()` after every mutation + BGTask refresh fallback

### Pet state "never corrupts" design (guide §6.3 — mandatory)
```
PetState ≡ PetDeriver(dailyScores, currentSeason, petCreatedAt)
```
The pet stores NO state fields. Stage/mood/outfit are derived in real time from score history by a pure function. Restore/sync/switch device → pet always reappears correctly. Exhaustively testable.

## Module Structure

```
Habibling/
├── Habibling/                      # Main app target
│   ├── App/
│   │   ├── HabiblingApp.swift          # @main, ModelContainer setup
│   │   └── AppEnvironment.swift        # Dependency container
│   ├── Models/
│   │   ├── Habit.swift                 # @Model
│   │   ├── Completion.swift            # @Model, unique(habitID, dayBucket)
│   │   ├── MoodEntry.swift             # @Model, unique(dayBucket)
│   │   ├── HabitType.swift             # binary/counter/timer/negative
│   │   ├── HabitSchedule.swift         # daily/daysPerWeek/weekdays/everyNDays
│   │   ├── CheckInSource.swift         # manual/notification/siri/widget/ai
│   │   └── Schema.swift                # VersionedSchema + MigrationPlan
│   ├── Core/
│   │   ├── HabitScoreCalculator.swift  # EMA α=0.05 Vibe %
│   │   ├── StreakCalculator.swift      # current/best/total
│   │   ├── PetDeriver.swift            # pure function: scores→PetState
│   │   ├── Season.swift                # spring/summer/fall/winter/holiday
│   │   └── SnapshotBuilder.swift       # App Group JSON builder
│   ├── Sprites/
│   │   ├── SpriteSheet.swift           # 16×16 frame index + JSON atlas
│   │   └── PixelPetView.swift          # Canvas nearest-neighbor renderer
│   ├── Views/
│   │   ├── Today/ (TodayView, HabitTileView, RescueCard, BerryBurst)
│   │   ├── Pet/ (PetPageView, PetDexView, MoodRow, PixelPostHistory)
│   │   ├── Stats/ (StatsView, MosaicView, TrendCharts)
│   │   ├── HabitDetail/ (Detail, MonthCalendar, VibeExplainPopover)
│   │   ├── Onboarding/ (Welcome, CardPicker, AIPlanSheet, HatchMoment)
│   │   ├── Settings/ (SettingsView, SyncStatus, DayStart, AIConfig, Store)
│   │   ├── Paywall/ (PaywallView — 3-tier table + legal links)
│   │   └── Share/ (MosaicExportView, EvolutionShareCard)
│   ├── Services/
│   │   ├── PersistenceController.swift
│   │   ├── CheckInService.swift        # single write path, recalc+snapshot
│   │   ├── ReminderScheduler.swift     # 28-day rolling, Done/Snooze
│   │   ├── PurchaseManager.swift       # StoreKit 2
│   │   ├── OnDeviceAICoach.swift       # FoundationModels @available(iOS 26)
│   │   ├── GLMCloudService.swift       # Cloudflare proxy client
│   │   ├── KeychainStore.swift         # userId UUID
│   │   ├── SoundPlayer.swift           # 8-bit chirp synth
│   │   ├── ShareRenderer.swift         # ImageRenderer 4K mosaic + watermark
│   │   └── BackupService.swift         # JSON/CSV import+export
│   └── Intents/
│       ├── CheckInIntent.swift         # Siri + widget + notification Done
│       └── IntentDefs.swift
├── HabiblingWidgets/               # Widget extension target
│   ├── PetWidget.swift                 # home screen (free)
│   └── LockScreenWidget.swift
├── HabiblingWatch/                 # Watch app target (watchOS 10+)
│   ├── HabiblingWatchApp.swift
│   ├── WatchTodayView.swift            # read-only snapshot + check-in via Intent
│   └── WatchPetView.swift
├── HabiblingLiveActivity/          # (in Widgets target) ActivityAttributes
│   └── PetLiveActivity.swift
└── Resources/
    ├── Assets.xcassets                 # AppIcon, AccentColor
    ├── Sprites/ (JSON atlases + PNG sheets, 24 frames at launch)
    └── Localizable.xcstrings           # EN ES PT FR DE JA
```

## ⚠️ Feature Inventory (MANDATORY — Every Feature Must Be Listed)

### Primary Features

| # | Feature | User Operation Flow | Data Input | Processing | Data Output | Persistence | Acceptance Criteria |
|---|---------|--------------------|------------|------------|-------------|-------------|---------------------|
| 1 | Onboarding (fast path) | Launch → no account/permission walls → <1s to home → pick 1-3 starter habit cards → tap Done → pixel egg appears → hatch animation → pet born | Card selection (name pre-filled, editable) | Create Habit records, create pet anchor date (first launch stored in App Group defaults) | Pet egg + first tile lit | Habit rows, `petCreatedAt` UserDefaults/App Group | Fresh install → pet hatched in <30s, ≤3 taps to first habit |
| 2 | Onboarding (AI path) | On card picker tap "✨ Describe a goal" → type "I want to get fit" → AI returns 3 atomic habit cards → swipe keep/discard → confirm | Goal text | On-device FM (iOS 26+) generates JSON array of 3 habits (name ≤24 chars, SF Symbol, colorHex, schedule, why ≤15 words); fallback: GLM proxy (Cloud+) or hidden if no engine | Editable habit card stack | Habit rows after confirm | 3 cards generated or feature gracefully hidden; never an error dead-end |
| 3 | Daily check-in | Today tab → tap habit tile → pixel lights + berry burst (≤300ms) + haptic success + 8-bit chirp | Tap | CheckInService: upsert Completion (unique habitID+dayBucket, value+=target for counter / value=1 binary), recalc EMA cache, rebuild snapshot, reload widgets, pet reacts | Lit pixel tile, berry particles, pet chirp animation | Completion row (updated in place on repeat) | Double-tap same day updates value, never duplicates row; widgets refresh <5s |
| 4 | Counter habits (partial) | Tile shows progress ring (e.g. water 6/8) → tap "+" adds one unit or open sheet to enter amount | Amount stepper | value/target → partial score (0.75 for 6/8) | Progress ring + partial pixel opacity | Completion.value | 6/8 cups → Vibe contribution 0.75 |
| 5 | Negative habits | Create habit with type=negative + daily limit (e.g. cigarettes ≤5) → log count → fewer is better | Count | Reverse scoring: `max(0, 1 - value/max(target,1))` | Score inversely proportional to count | Completion.value | 2/5 limit → score 0.6; 0 → 1.0 |
| 6 | Timer habits | Start/stop timer on tile → elapsed accumulates | Elapsed seconds | Accumulate into Completion.value (minutes), score vs target | Duration display + ring | Completion.value | Timer persists across app backgrounding |
| 7 | Multiple check-ins/day | Tap tile again → value increments (e.g. +1 glass) | Tap | Same row value accumulation (guard #2) | Count badge on tile | Completion.value updated | Row count for (habit,day) stays exactly 1 |
| 8 | Vibe % (EMA elastic score) | Open habit detail or Today header ring | — | HabitScoreCalculator: EMA α=0.05, only scheduled days count, partial/negative values normalized; overall Vibe = mean across active habits | Vibe % ring (habit + global) | DailyScore cache (recomputed on write) | Perfect 30 days > 0.75; perfect month then 1 missed day barely drops; 10 missed days drops significantly; recovery climbs back |
| 9 | Vibe explain popover | Tap Vibe ring → popover explains EMA in plain English ("recent days weigh a little more; a miss never erases your story") | Tap | Static explainer + current numbers | Popover | — | Popover reachable in ≤2 taps; no dark-pattern |
| 10 | Yesterday rescue card | Launch with missed-yesterday habits → card(s) at top of Today → tap "Rescue" → yesterday lit | Tap | Query habits due yesterday without Completion → insert Completion(dayBucket: yesterday) → recalc | Rescue card(s), ≤3 shown | Completion rows | After rescue, mosaic yesterday cell lit, pet unaffected negatively |
| 11 | Editable history calendar | Habit detail → month calendar → tap any past day → add/edit/delete completion | Tap + optional value/note | Upsert/delete Completion for that dayBucket → recalc from that day | Calendar cell state, mosaic updates | Completion rows | Any past day editable in ≤2 taps; deleting works |
| 12 | Pixel mosaic heatmap | Habit detail top + Stats yearly view | — | Render DailyScores as GitHub-style grid: 26 weeks (detail) / 52 weeks (yearly), 5-level opacity (0.07 empty → 1.0 full), sharp squares (no rounding) | Canvas mosaic | — (derived) | Colors match habit color; yearly export renders 4K |
| 13 | Streaks | Habit detail + Stats | — | current streak (consecutive due-days completed, grace per schedule), best streak, total completions | Stat rows | — (derived) | Matches Kadō streak.md semantics; schedule-aware (daysPerWeek doesn't punish rest days) |
| 14 | Mood diary | Pet page bottom mood row → tap today's pixel → pick 1-5 + optional note | Level + note | Unique per dayBucket (one mood/day, editable) | Mood pixel row (colored by level) | MoodEntry row | One row per day max; edit overwrites |
| 15 | Pixel pet engine | Pet page / Today header | — | PetDeriver pure fn: daysKept(scores ≥0.5)→stage (egg <3, hatchling <14, juvenile <30, adult ≥30); mood from 7-day avg (≥0.6 joyful, ≥0.25 content, else sleepy); outfit = season × stage; progression = daysKept/30 | Animated 16×16 pet, 8fps idle frames | NOTHING persisted (pure derivation) | Same data → same pet on any device; pet never sick/dead; sleepy = blanket nap animation |
| 16 | Pet evolution moment | Cross stage threshold on check-in → full-screen pixel particle convergence animation → share button | Automatic on threshold | Detect stage change between previous and current PetState → play once → mark shown | Evolution animation + share card | `lastShownStage` App Group (presentation-only flag, NOT pet state) | Animation plays once per evolution; share card exports with pet + date |
| 17 | Pet naming & dex | Pet page → tap name → rename; Dex grid shows unlocked forms/outfits | Name text | Store pet name; dex = derived unlocked stages×seasons | Name, dex collection grid | petName in App Group defaults | Rename instant; dex locks show silhouettes for locked items |
| 18 | Habit CRUD | Today "+", or Habit detail → Edit → name/icon(SF)/color/type/schedule/target/category → Save; Archive from detail | Form fields | Validation, sortOrder, unique color per habit | Habit list updates | Habit row | Archived habits leave Today but keep history; category assignment works |
| 19 | Categories | Settings/Habit editor → create/rename/delete category → assign habits | Text + color | Group filter on Stats & Today | Category chips | Category model or enum-string on Habit | Filtering works on both Today and Stats |
| 20 | iCloud sync | Automatic; Settings shows status | — | SwiftData `.private` CloudKit; record-level LWW; idempotent completions | Sync status row: synced/syncing/failed(reason) | CloudKit private DB | Two devices converge; failure shows reason, never fake success |
| 21 | Day Starts At setting | Settings → picker 0-6h | Hour | Future day-bucketing uses shifted startOfDay; history NEVER recomputed | Setting persists | App Group defaults | Changing setting does not alter past cells |
| 22 | Notifications (28-day rolling) | First successful check-in → permission prompt (peak-goodwill moment) → habit reminder time → BGTask weekly renewal | Time + habit schedule | Schedule per-day non-repeating UNCalendarNotificationTrigger for next 28 due days (≤64 limit), category with Done/Snooze 1h actions; copy variants from warm pool | Lock-screen notifications with Done/Snooze buttons | UNUserNotificationCenter + BGTask schedule | Done from lockscreen writes completion without opening app; DST safe (per-date triggers, no repeating) |
| 23 | Home-screen pet widget (FREE) | Long-press home → add Habibling widget | — | Read App Group snapshot (pet state mini-render, today tiles, vibe) | Small/medium/large widget; tap tile = check-in via AppIntent | Read-only snapshot | Widget reflects check-in within seconds (reloadAllTimelines); extension never opens SwiftData |
| 24 | Lock-screen widgets (Plus) | Lock screen → add | — | Snapshot read: pet face + today count | accessoryCircular/inline | Read-only snapshot | Gated: free users see upgrade prompt on add attempt |
| 25 | Watch app (Plus) | Watch app launch | — | Snapshot read → today list + mini pet; tap → CheckInIntent (phone write via WCSession/background or local watch write if model present) | Watch Today + Pet views | Snapshot via App Group/watch connectivity | Check-in from watch appears on phone; Plus-gated on iPhone |
| 26 | Live Activity / Dynamic Island (Plus) | During "today in progress" (first check-in until last habit done or midnight) | — | ActivityKit: pet face + progress "3/5" + tap to open | Dynamic Island compact/expanded, lock-screen banner | ActivityKit + snapshot | Starts on first check-in, ends on completion or midnight; Plus-gated |
| 27 | Siri / App Intents (Plus) | "Mark read in Habibling" | Habit name spoken | Fuzzy match habit → CheckInIntent writes completion | Siri confirmation | Completion row | Works from lockscreen; ambiguous name → disambiguation UI |
| 28 | AI pet line (daily) | Today header pet dialogue bubble | — | iOS 26: FM generates ≤12 warm words per pet state (never scolds); <26: warm copy pool rotation | Dialogue line in pixel font | Cached per day | Never guilt language; refreshed daily; Plus = regenerate on tap |
| 29 | Weekly Pixel Post | Monday first launch → letter card from pet: 3 insights + 1 tiny suggestion | Weekly summary (habit names + counts + vibe, anonymized) | FM (iOS 26+) structured WeeklyReview; fallback: GLM proxy (Cloud+) or template pool; free 1×/month, Plus unlimited, cached | Pixel Post letter + history list | WeeklyReview cache rows | Never appears before user has ≥3 days data; tone warm, no guilt |
| 30 | GLM monthly deep report (Cloud+) | Stats → "Monthly Deep Report" → generate | Month summary stats | GLMCloudService → proxy → glm-5.3-flash (thinking low, max_tokens 8192, system: data-driven analyst, 200 words, cite numbers) | Report text + saved archive | Report cache row | Requires Cloud+ active; 429 → friendly message; report saved and viewable offline |
| 31 | Photo habit logging (Cloud+) | Habit detail → camera icon → snap (gym board/book page/treadmill) | JPEG base64 | GLM vision: "Habit: X. Extract today's completed amount as a number only." → result sheet → user confirms/edits → completion written | Confirm sheet with parsed number | Completion after confirm | User confirm step mandatory (never auto-write); graceful error on bad photo |
| 32 | StoreKit 2 IAP | Settings → Store / Paywall | Purchase | PurchaseManager: plus.lifetime (non-consumable), cloud.monthly (auto-renew); Transaction.updates listener; restore | Entitlements isPlus/isCloudPlus | StoreKit 2 + local cache | Launch price $14.99→$24.99 handled via ASC sale, not code; paywall has privacy+terms links + auto-renew disclosure |
| 33 | Yearly mosaic 4K export (Plus) | Stats → share button | — | ImageRenderer renders 52-week mosaic at 4K + watermark `habibling.app` | ShareSheet with PNG | — | Plus-gated; watermark always present |
| 34 | JSON/CSV import+export | Settings → Data | File pick/save | JSON: full lossless round-trip; CSV: completions table; import dedupes via unique keys | Exported files / imported data | All models | Free: JSON export; Plus: CSV + import; import never duplicates rows |
| 35 | Voice note with on-device transcription | Habit detail day editor → mic → speak → transcribe | Audio | Speech framework on-device transcription → note text (user can edit before save) | Note text on completion | Completion.note | Parity with competitor; no cloud audio upload |
| 36 | Settings hub | Settings tab from Today/Pet/Stats toolbar | — | Sync status, Day Starts At, AI status, Store, Data, About (acknowledges Kadō MIT), version from Bundle.main (never hardcoded) | Settings list | Various | All ≤2 taps from any tab; about page credits Kadō |
| 37 | Localization | — | — | EN base + ES PT FR DE JA via xcstrings; pet dialogue stays EN at launch (8-bit tone) | Localized UI | xcstrings | 6 languages compile; no missing-key warnings |
| 38 | Themes & app icons (Plus) | Settings → Appearance | Selection | Alternative accent palettes + alternate app icons (Plus-gated) | Theme applied globally | UserDefaults | Free: default; Plus: all palettes/icons |
| 39 | Reduce Motion & Accessibility | System setting | — | All animations respect `accessibilityReduceMotion`; VoiceOver labels everywhere; Dynamic Type to XXXL; mosaic has text alternative | — | — | VoiceOver can complete full check-in flow |

### Sub-Features & Detail Interactions

| # | Parent | Sub-Feature | Detail | Interaction |
|---|--------|-------------|--------|-------------|
| 3.1 | Check-in | Berry burst particles | 6-10 pixel fragments explode from tile, ≤300ms, spring response 0.35 | Automatic on tap |
| 3.2 | Check-in | Pet chirp | Procedural 8-bit chirp (square wave, 120ms); silent if system silent | Automatic |
| 5.1 | Negative habit | Limit editor | Target = daily max; progress shows "2/5 — under limit" | Stepper in editor |
| 10.1 | Rescue | Multi-habit rescue | ≤3 cards stacked, each rescues independently | Tap per card |
| 15.1 | Pet | Seasonal outfits | spring/summer/fall/winter/holiday by current month (holiday = Dec 15-31); outfit per stage | Automatic by date |
| 15.2 | Pet | Sleepy nap animation | Blanket over body, slow 4fps breathing frames, "Zzz" pixel particles | Mood=sleepy |
| 15.3 | Pet | Color tinting | Pet picks up tint of most-checked habit color over time (visualize "you are what you do") | Derived from data |
| 22.1 | Notifications | Smart copy variants | Warm pool of ≥10 lines per habit, chosen per-day; iOS 26 uses AI variant when Plus | On schedule |
| 23.1 | Widget | Interactive check-in | WidgetKit Button → AppIntent writes through shared container (iOS 17 interactive widgets) | Tap tile in widget |
| 28.1 | AI pet line | Regeneration | Plus users tap dialogue to regenerate; free users see "Plus" hint | Tap bubble |
| 30.1 | Deep report | Archive | Past reports listable and re-readable | Stats → Reports |
| 36.1 | Settings | Sync honesty | States: Synced {time} / Syncing… / Failed: {reason} with retry | Auto + manual retry |

### Cross-Feature Dependencies

| Dependency | Source | Target | Data Passed | Trigger |
|------------|--------|--------|-------------|---------|
| Check-in → pet reaction | CheckInService | PetDeriver/render | Updated DailyScores | Every completion write |
| Check-in → widget refresh | CheckInService | SnapshotBuilder → WidgetCenter | New snapshot JSON + reloadAllTimelines | Every completion write |
| Rescue → recalc | RescueCard | Score cache invalidation | dayBucket edited | Rescue tap / calendar edit |
| Evolution detection | PetDeriver | Evolution animation | prevStage vs newStage | Stage threshold crossing |
| Notification Done → write | UNNotificationCategory action | CheckInIntent → CheckInService | habitID + dayBucket | Lock-screen Done tap |
| Purchase → gating | PurchaseManager | Watch/LiveActivity/lock widgets/export/AI-unlimited | isPlus/isCloudPlus | Transaction.updates |
| AI plan → habits | Onboarding AI sheet | Habit creation | [HabitPlanItem] JSON | Confirm cards |
| Photo parse → completion | GLMCloudService | Confirm sheet → CheckInService | Parsed number | User confirm |
| Mood entry → pet page row | MoodRow | MoodEntry store | level + note | Mood tap |
| First check-in → notification permission | CheckInService | Permission prompt | Success moment | First-ever check-in |
| Cloud+ → GLM features | PurchaseManager | GLMCloudService gating | isCloudPlus | Report/photo actions |

**VERIFICATION**: Chinese guide features (§5 flows, §6 data flows, §7 code specs, §7.8 pricing, §9 IA) map to features 1-39 above. Guide's "全功能触达规则" (≤2 taps) covered by acceptance criteria. ✅

## ⚠️ Data Flow Diagram (MANDATORY — Every Feature's Data Lifecycle)

```
Feature: Daily Check-in (the heart — all other flows branch from it)
┌─────────────────────────────────────────────────────────────────┐
│ User Input                                                      │
│ └── Tap habit tile (Today) / widget Button / lockscreen Done /  │
│     Siri phrase / watch tap — ALL converge to CheckInIntent      │
│        │                                                        │
│ ViewModel/Service (CheckInService — single write path)          │
│ └── 1. Resolve habit by persistentID (fuzzy name for Siri)      │
│    2. Compute dayBucket = startOfDay(now, dayStartOffset)       │
│    3. Upsert Completion (unique habitID+dayBucket)              │
│       ├─ exists → value += increment (counter) / value = target │
│       └─ new → insert with sourceRaw, updatedAt=now             │
│    4. Invalidate score cache from dayBucket                     │
│    5. HabitScoreCalculator.recalc(habit) → DailyScore cache     │
│    6. SnapshotBuilder.rebuild() → App Group JSON                │
│    7. WidgetCenter.reloadAllTimelines()                         │
│    8. Trigger UI feedback: berry burst + haptic + chirp         │
│        │                                                        │
│ Model/Persistence                                               │
│ └── SwiftData: Completion row (unique constraint guards dupes)  │
│     CloudKit sync (automatic, LWW, idempotent)                  │
│     DailyScore cache table (recomputable, never source of truth)│
│        │                                                        │
│ Display Output                                                  │
│ └── Today tile lit + progress ring; PetDeriver recomputes       │
│     PetState → pet animates (chirp/wag/evolve check);           │
│     mosaic cell opacity updates; Vibe ring animates             │
│        │                                                        │
│ Cross-Feature Output                                            │
│ └── Widget/Watch/LiveActivity read new snapshot;                │
│     Evolution detector compares stage;                          │
│     Rescue card disappears if yesterday was the bucket          │
└─────────────────────────────────────────────────────────────────┘

Feature: Pet State Derivation (zero persistence — the "never corrupts" guarantee)
┌─────────────────────────────────────────────────────────────────┐
│ Input: [DailyScore] (all habits mean per day), Season(now),     │
│        petCreatedAt, now                                        │
│ Processing: PetDeriver.derive() — PURE FUNCTION                 │
│ └── daysKept = count(score ≥ 0.5)                               │
│     stage: <3 egg / <14 hatchling / <30 juvenile / ≥30 adult    │
│     mood: 7-day avg ≥0.6 joyful / ≥0.25 content / else sleepy   │
│     outfit: season.assetName(for: stage)                        │
│     progression: min(1, daysKept/30)                            │
│ Output: PetState → PixelPetView (16×16 Canvas, 8fps Timeline)   │
│ Persistence: NONE. Survives restore/sync/reinstall-by-iCloud.   │
└─────────────────────────────────────────────────────────────────┘

Feature: GLM Cloud AI (deep report / photo logging)
┌─────────────────────────────────────────────────────────────────┐
│ Gate: isCloudPlus (StoreKit) → else paywall hint                │
│ Input: month summary string / JPEG base64 + habit name          │
│ Client (GLMCloudService):                                       │
│ └── userId = Keychain UUID (first-launch generated)             │
│     POST https://cramjam-api.calcs.top                          │
│     body: {appId:"habibling", userId,                           │
│            devKey (DEBUG) | appTransaction (release),           │
│            payload:{model:"glm-5.3-flash", messages,            │
│            thinking:{level:"low"}, max_tokens: 4096|8192,       │
│            [response_format:json_object]}}                      │
│ Response: choices[0].message.content (ignore reasoning_content) │
│ Errors: 429→friendly rate-limit copy; 401→restore purchase;     │
│         400→log client bug                                      │
│ Output: report text archived / parsed number → USER CONFIRMS →  │
│         CheckInService.upsert (never auto-write)                │
└─────────────────────────────────────────────────────────────────┘

Feature: Notifications (28-day rolling)
┌─────────────────────────────────────────────────────────────────┐
│ Trigger: habit created/edited; BGTask weekly refresh; app launch│
│ Processing: ReminderScheduler                                   │
│ └── For next 28 days where schedule.isDue(day):                 │
│     UNCalendarNotificationTrigger(dateComponents of hour+min,   │
│     repeats: false) — DST-safe per-date triggers                │
│     content: warm copy variant; category = HABIBLING_REMINDER   │
│     (actions: Done → CheckInIntent, Snooze 1h)                  │
│ Persistence: UNUserNotificationCenter; BGTask scheduler re-news │
│ Output: lockscreen notifications; Done writes completion        │
│         without opening app (goes through same CheckInService)  │
└─────────────────────────────────────────────────────────────────┘

Feature: StoreKit 2 Entitlements
┌─────────────────────────────────────────────────────────────────┐
│ Load: Product.products(for: [plusID, cloudID])                  │
│ Purchase → Transaction result → verify → finish → update flags  │
│ Transaction.updates listener (foreground + launch)              │
│ Flags: isPlus, isCloudPlus (cached in App Group for extensions) │
│ Consumers: Watch/LiveActivity/lock widgets/4K export/import/    │
│            unlimited AI (Plus); GLM features (CloudPlus)        │
└─────────────────────────────────────────────────────────────────┘
```

**VERIFICATION**: every primary feature's data path terminates in a persisted model or a pure derivation from persisted data. No orphan views. ✅

## Implementation Flow

1. **Scaffold**: xcodegen `project.yml` — App target (com.zzoutuo.Habibling) + Widgets extension + Watch app; entitlements: iCloud CloudKit container `iCloud.com.zzoutuo.Habibling`, App Group `group.com.zzoutuo.Habibling`, Push for CK; DEVELOPMENT_TEAM baked; first green build with placeholder entry view
2. **Models + Schema**: Habit/Completion/MoodEntry @Model per CloudKit shape rules; `#Unique` constraints; VersionedSchema V1 + migration plan
3. **Core algorithms (test-first)**: HabitScoreCalculator (EMA α=0.05, negative reverse scoring, partial credit, schedule-aware) + StreakCalculator; Swift Testing suite: perfect-30d > 0.75, miss-1-after-perfect barely drops, miss-10 drops, recovery climbs, DST/timezone robust, backfill recompute
4. **Pet engine**: PetDeriver pure function (+ tests) → SpriteSheet JSON atlas renderer (Canvas nearest-neighbor) → launch sprite set: 2 stages (egg, hatchling) × 3 moods × 2 seasons × 2 frames = 24 frames procedural/pixel assets → PixelPetView with TimelineView 8fps → berry burst + chirp + haptic check-in loop
5. **Today page**: habit tiles, partial/negative/timer interactions, rescue card, Vibe ring + explain popover, mood row
6. **History editing**: habit detail month calendar (tap any day), mosaic view, streaks
7. **Notifications**: ReminderScheduler 28-day rolling + BGTask + Done/Snooze categories + warm copy pool
8. **Snapshot + Widgets**: SnapshotBuilder (pet state, tiles, vibe into App Group JSON) → PetWidget (interactive check-in) + lock-screen widgets + ActivityAttributes for Live Activity
9. **Watch app**: snapshot read + CheckInIntent round-trip
10. **AI layer**: OnDeviceAICoach (FoundationModels, @available iOS 26; pet line, habit plan, weekly review) with rule-engine fallback pools; GLMCloudService proxy client (devKey DEBUG / appTransaction release, thinking low, generous max_tokens, error copy)
11. **IAP**: PurchaseManager (plus.lifetime, cloud.monthly), entitlement gating map, PaywallView with legal links + honest 3-tier table
12. **Share & data**: yearly mosaic ImageRenderer 4K + watermark; evolution share card; JSON/CSV import+export with dedupe
13. **Settings + About**: sync status (honest), Day Starts At, AI status, Store, data, About with Kadō MIT acknowledgement, dynamic version
14. **Polish**: localization 6 languages, Dynamic Type/VoiceOver/Reduce Motion pass, dark mode audit, launch sprite QA
15. **Build & test**: iPhone + iPad sim build/run green; unit tests pass; widget timeline refresh verified

## UI/UX Design Specifications

- **Structure**: 3 tabs — **Pet / Today / Stats** (Today is default launch tab). One screen one job; every function ≤2 taps.
- **Today (default)**: pet zone top (~40% height: animated pet + dialogue bubble in pixel font + Vibe ring) → rescue cards (conditional) → today habit tiles (tap=check-in, long-press=edit amount/note/multi-check) → bottom tab bar
- **Pet page**: large pet + name (tappable rename) + evolution progress bar → dex grid (locked items = silhouettes) → mood pixel row → Pixel Post archive
- **Habit detail**: mosaic top + Vibe % (tap → explain popover) → month calendar (tap any day) → streak stats → actions (edit/archive/export)
- **Stats**: overall Vibe trend, category breakdown, yearly mosaic + share (Plus), reports (Cloud+)
- **Color system**: one primary color per habit; pixels at 5 opacity levels (0.07/0.15/0.36/0.58/1.0 by score band); pet tints toward most-checked habit color; system backgrounds elsewhere
- **Motion**: check-in burst ≤300ms spring(0.35, 0.6); evolution = one-time full-screen particle convergence; sleepy nap = slow breathing loop; ALL gated by Reduce Motion
- **Typography**: SF Pro everywhere; pixel font ONLY for pet dialogue; Dynamic Type to XXXL supported
- **Empty states**: no habits → starter cards; day with zero data → encouraging one-liner, never a guilt message

## Code Generation Rules

- One feature per module, high cohesion low coupling; single write path through CheckInService
- Semantic naming; no comments in code unless logic is non-obvious
- Apple-native only; ZERO third-party dependencies
- Version strings always read from `Bundle.main.infoDictionary`
- Extensions never import SwiftData — App Group JSON snapshot only
- `@available(iOS 26, *)` gates all FoundationModels usage; runtime capability check before showing AI buttons
- All AI outputs land behind user confirmation when they write data
- Never persist pet state; never add free-generation counters; never show fake sync success
- Test-first for Core algorithms (Swift Testing)

## Build & Deployment Checklist

1. xcodegen generate → build sim green (iPhone + iPad)
2. Unit tests (score/streak/pet/snapshot) green
3. Widget extension timelines refresh verified
4. StoreKit configuration file (Habibling.storekit) with both products for local testing
5. Capabilities on: iCloud (CloudKit), Push Notifications, App Groups, Background Modes (BGTask/processing)
6. Entitlements team-signed; archive builds for all 3 targets
7. GLM proxy end-to-end call verified from app (devKey mode)
8. Localization files complete for 6 languages
9. app_review_info.md written (AI fallback behavior + demo notes)
10. TestFlight → App Store metadata per locked values (title/subtitle/keywords/promo from §Executive Summary)
