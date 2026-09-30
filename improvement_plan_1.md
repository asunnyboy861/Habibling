# Habibling — Improvement Plan #1 (QA Iteration, Step 11)

**Date**: 2026-09-30 · **Scope**: PHASE 4+5 full codebase QA (before GitHub push)
**Build**: ✅ Build succeeded · **Tests**: ✅ 12/12 passed · **Smoke test**: ✅ launched on simulator, onboarding renders correctly (screenshot verified)

## 7-Dimension Score

| # | Dimension | Score | Notes |
|---|-----------|:-----:|-------|
| 1 | Feature Completeness | 9.0 | All 39 blueprint features implemented. 3 marketing/impl mismatches in price.md found & fixed this round. |
| 2 | Code Quality | 8.5 | Clean MVVM + service layer; 12 non-blocking warnings remain (Swift 6 isolation, deprecations, unused results). |
| 3 | UI / UX | 9.0 | Pixel aesthetic consistent across app/widgets/watch/Live Activity; onboarding verified visually; paywall has no dark patterns. |
| 4 | Performance | 8.5 | EMA scoring is O(days); widget refresh 30 min, BGTask 4 h; snapshot-passing keeps widget/watch cheap. |
| 5 | Security & Privacy | 9.5 | No secrets in Release (devKey is `#if DEBUG` only), zero data collection, no 3rd-party SDKs, on-device-first AI. |
| 6 | App Store Compliance | 9.5 | Paywall + legal links + auto-renew disclosure present; **camera permission removed** (declared-but-unused = 5.1.1 rejection risk). |
| 7 | Test Coverage | 8.0 | 12 XCTest cases cover pet derivation, scoring, schedules, streaks, day buckets, snapshots, intent mapping. No UI tests yet. |
| | **Weighted overall** | **8.9 / 10** | Ship-ready after P0 fixes below. |

## Issues Found & Fixes

### P0 — Fixed this round (blocking, all resolved)

1. **`NSCameraUsageDescription` declared with no camera feature** — Info.plist + project.yml. Apple Guideline 5.1.1 rejects apps declaring purpose strings for APIs they never call. **Fix**: removed from both `Habibling/Info.plist` and `project.yml` (regenerate-safe). Microphone + Speech strings kept (both genuinely used by NoteSheet dictation).
2. **Negative-habit scoring mismatch** — `HabitScoreCalculator.scoreHistory` used `1 - value/target` partial credit, but the product semantic (and test) is "a day with logged use ≤ target budget is a full success day". **Fix**: negative type now scores binary (`value <= target ? 1 : 0`). `testNegativeHabitScoring` now passes → 12/12.
3. **price.md promised unimplemented Cloud+ features** — "Photo habit logging (GLM vision)" and "Pet long-term memory (cloud)" had no code. Shipping metadata that promises nonexistent features invites 2.1 rejection and refunds. **Fix**: price.md Cloud+ column now lists only shipped entitlements (GLM monthly deep report, GLM weekly Pixel Post, GLM encouragement lines).

### P1 — Recommended before submission (non-blocking, quick wins)

4. **`PurchaseManager.syncSnapshotFlags` is a no-op round-trip** — `var updated = snapshot; updated.save()` loads and re-saves unchanged data. **Plan**: drop the load/save block, keep the App Group defaults writes.
5. **Deprecated APIs (12 warnings total)**:
   - `onChange(of:perform:)` ×2 (BerryBurst, SettingsView) → migrate to two-parameter closure.
   - `requestRecordPermission` (SpeechService) → `AVAudioApplication.requestRecordPermission`.
   - 6 × unused-result on `upsert/complete` → `_ =` or handle the returned feedback.
6. **Swift 6 readiness**: `CheckInService.shared` static + `SpeechService.requestPermissions` statics warn under MainActor isolation. Fine for Swift 5.9 mode; annotate `@MainActor` on the statics when enabling Swift 6.

### P2 — Post-launch backlog

7. UI tests for onboarding → check-in → widget flow (XCUITest).
8. iPad layout pass (today grid currently reflows via adaptive stacks; verify at regular + large sizes).
9. Watch app offline queue dedup (duplicate check-in if sendMessage succeeds after transferUserInfo fallback fires).
10. Cloud AI request timeout backoff (currently single retry on fallback URL only).

## Verification After P0 Fixes

- `xcodebuild build` → ✅ succeeded (3.0s)
- `xcodebuild test` → ✅ 12/12 passed (0 failed, 0 skipped)
- Simulator launch → ✅ onboarding screen renders: pixel pet sprite, "Habibling" title, tagline, Continue CTA

## Decision

Proceed to PHASE 6 (GitHub push) with P0 fixed. P1 items may be batched before the first TestFlight build.
