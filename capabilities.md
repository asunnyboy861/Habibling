# Capabilities Configuration

## Analysis
Based on us.md + Chinese guide keyword scan (iCloud sync/CloudKit, widget, watch, notification, live activity/dynamic island, camera photo logging, voice transcription, Siri, StoreKit 2 IAP):

## Project Structure (auto-created via xcodegen 2.44.1)
- `Habibling.xcodeproj` — 3 targets:
  - **Habibling** (iOS app, com.zzoutuo.Habibling, iOS 17.0+, iPhone+iPad)
  - **HabiblingWidgets** (widget extension, com.zzoutuo.Habibling.Widgets)
  - **HabiblingWatch** (watchOS app, com.zzoutuo.Habibling.watchkitapp, watchOS 10.0+)
- Shared snapshot code in `Shared/` compiled into all three targets (App Group JSON pattern — extensions never touch SwiftData)

## Auto-Configured Capabilities
| Capability | Status | Method |
|------------|--------|--------|
| iCloud (CloudKit, container `iCloud.com.zzoutuo.Habibling`) | ✅ Configured (entitlements) | project.yml entitlements + automatic signing |
| App Groups (`group.com.zzoutuo.Habibling`) | ✅ Configured (all 3 targets) | entitlements files |
| Push Notifications (aps-environment, required for CloudKit subscriptions) | ✅ Configured | entitlements (development) |
| Background Modes (processing + remote-notification for BGTask/CK) | ✅ Configured | Info.plist properties |
| BGTaskSchedulerPermittedIdentifiers (`com.zzoutuo.Habibling.refresh`) | ✅ Configured | Info.plist properties |
| Camera / Microphone / Speech Recognition usage descriptions | ✅ Configured | Info.plist properties |
| WidgetKit extension | ✅ Configured | app-extension target with `com.apple.widgetkit-extension` point |
| Watch App (companion, WKApplication + WKCompanionAppBundleIdentifier) | ✅ Configured | watchOS application target embedded in iOS app |
| In-App Purchase (StoreKit 2) | ✅ No entitlement needed on iOS | products configured in PHASE 3/8.5 (App Store Connect) |
| Privacy manifests (PrivacyInfo.xcprivacy) | ✅ All 3 targets covered | UserDefaults CA92.1 (+ FileTimestamp C617.1 in app) |

## Manual Configuration Required
| Capability | Status | Steps |
|------------|--------|-------|
| CloudKit container registration in Apple Developer portal | ⏳ Auto-registered on first device build/archive IF the Apple ID with team JP4TN5PTS3 is logged into Xcode (automatic signing + `-allowProvisioningUpdates` was already used successfully — signing identity resolved). If portal registration is ever needed: developer.apple.com → Certificates, IDs & Profiles → Identifiers → iCloud container `iCloud.com.zzoutuo.Habibling` → attach to App ID | Only if a device build reports "no iCloud container" |
| App Store Connect: IAP products (plus.lifetime $24.99, cloud.monthly $1.99/mo) | ⏳ Pending ASC setup | Created during App Store metadata phase / launch checklist |
| App Store Connect: CloudKit schema deploy to production | ⏳ Pending | After first device run: CloudKit Dashboard → Deploy Schema Changes to Production |

## No Configuration Needed
- HealthKit, Location, Sign in with Apple — not in guide scope
- Siri entitlement — App Intents framework requires no special entitlement

## Verification
- Build succeeded after configuration: ✅ (sim build 8.5s, BUILD SUCCEEDED)
- All entitlements correct: ✅
- Signing verification (generic/platform=iOS): ✅ PASSED — all targets signed "Apple Development: he zhou (VX3Q75X27B)", BUILD SUCCEEDED with `-allowProvisioningUpdates`
- DEVELOPMENT_TEAM: JP4TN5PTS3 baked at project level (inherited by all targets)
- PrivacyInfo.xcprivacy: App + Widgets + Watch (all targets)
