# Habibling — 配置文档

生成时间：2026-09-30

---

## 一、⚠️ 手动配置（增强功能 — 不配置不影响基本使用）

> **重要说明**：以下配置项均为**增强功能**。App 下载后无需任何配置即可正常使用所有核心功能（习惯打卡、宠物成长、小组件、iCloud 同步等全部免费层功能开箱即用）。以下配置仅影响**付费产品销售**与**审核体验**。

### 🔵 IAP StoreKit 配置（必须 — 不创建则无法内购）

**影响功能**：不创建 IAP 产品，用户无法购买 Plus（$24.99 买断）和 Cloud+（$1.99/月订阅）。免费层功能完全不受影响。

**代码侧已全部完成**：`PurchaseManager.swift` 已内置正确 Product ID、StoreKit 2 交易监听、恢复购买；`Habibling.storekit` 本地测试文件已打包。

**你需要在 App Store Connect 手动创建产品**：

1. 打开 [App Store Connect](https://appstoreconnect.apple.com) → 我的 App → 选择 Habibling（需先创建 App 记录）→ **Features** → **In-App Purchases**
2. 点击 **Create** 创建第一个产品：

| 字段 | 产品 1 | 产品 2 |
|------|--------|--------|
| Type | Non-Consumable（非消耗型） | Auto-Renewable Subscription（自动续期订阅） |
| Reference Name | `Habibling Plus Lifetime` | `Habibling Cloud+ Monthly` |
| Product ID | `com.zzoutuo.Habibling.plus.lifetime` | `com.zzoutuo.Habibling.cloud.monthly` |
| 价格 | $24.99（一次性；首发 $14.99 用价格排期实现） | $1.99/月 |
| Display Name (EN) | `Habibling Plus` | `Habibling Cloud+` |
| Description (EN) | `Lifetime unlock: all Plus features, Family Sharing` | `Monthly GLM cloud AI deep reports, cancel anytime` |

3. 订阅产品创建时会提示创建**订阅组**：组名填 `Habibling Cloud`（Cloud+ 是该组唯一产品）
4. Plus 产品开启 **Family Sharing**
5. 两个产品都填写本地化为 English (U.S.)
6. ⚠️ Cloud+ 订阅组页面需要填 **Subscription Group 名称**与 **App Store 描述**；付费协议（Paid Apps Agreement）必须先签署，否则产品无法提交
7. 创建完成后用 TestFlight 或沙盒账号验证购买与 Restore Purchases

---

### 🟢 App Store Connect 审核信息配置（强烈建议 — 降低拒审风险）

**影响功能**：不配置可能导致审核员无法完整测试，增加 Guideline 2.1(a) 拒审概率。

**配置步骤**：

1. 在 App Store Connect → Habibling → **App Review Information**
2. **Notes 字段**：粘贴项目根目录 `app_review_info.md` 的第 1、2、9 节内容（App 概述、AI 三引擎披露、审核员测试步骤）。关键信息：
   - 无需账号，首启即可用全部功能
   - AI 功能有三引擎回退，审核环境（模拟器无 Apple Intelligence）下规则引擎免费产出同样内容，无任何功能被 AI 门槛挡住
   - StoreKit 配置文件 `Habibling.storekit` 已打包，可在模拟器直接测试购买
3. **Demo Account**：填 `Not applicable - no account system`
4. **Privacy Policy URL**：`https://asunnyboy861.github.io/Habibling/privacy.html` ✅（已上线，可访问）
5. **Support URL**：`https://asunnyboy861.github.io/Habibling/support.html` ✅
6. **Terms of Use (EULA) 链接**：⚠️ 有自动续期订阅时 App Store Connect 会在提交页要求填 EULA 链接 → `https://asunnyboy861.github.io/Habibling/terms.html`
7. **App Privacy（隐私营养标签）**：按 `app_review_info.md` 第 7 节填写 — **Collected: Nothing**（不收集任何数据；反馈表单和云 AI 均为用户主动触发且已披露）
8. **Content Rights / Export Compliance**：`ITSAppUsesNonExemptEncryption` 已在 Info.plist 设为 `false`，提交时出口合规问题答"仅使用标准加密"即可

---

### 🟡 CloudKit Schema 部署到生产环境（首次真机运行后）

**增强功能**：让 iCloud 同步对所有用户的生产环境生效。

**不配置的影响**：开发环境同步正常，但 TestFlight/正式版用户的 CloudKit 同步会失败（App 本地功能不受影响）。

**已自动完成**：entitlements 已声明容器 `iCloud.com.zzoutuo.Habibling`；自动签名验证通过（Team JP4TN5PTS3）。

**需要你手动做的**：

1. 用 Xcode 在**真机**上 Run 一次 Habibling（会自动把 Schema 推到 CloudKit Development 环境）
2. 打开 [CloudKit Dashboard](https://icloud.developer.apple.com) → 选择容器 `iCloud.com.zzoutuo.Habibling`
3. 左侧 **Deploy Schema Changes to Production...** → 确认部署
4. ⚠️ 提交 App Store 前务必完成，否则正式版无法同步

**仅当真机构建报 "no iCloud container" 时**：登录 [Apple Developer](https://developer.apple.com) → Certificates, Identifiers & Profiles → Identifiers → 找到 `com.zzoutuo.Habibling` → 勾选 iCloud → 勾选容器 `iCloud.com.zzoutuo.Habibling` → 保存后重新构建。（当前自动签名已通过，大概率不需要此步）

---

### 💡 无需配置的项目（避免误操作）

- **AI API Key**：App 不使用 BYO API Key 模式。Apple Intelligence 完全设备端、免费、无需配置；GLM 云 AI 走自建 Cloudflare Worker 代理（cramjam-api.calcs.top，备用 workers.dev），Release 构建内无任何密钥，订阅校验由 Worker 端完成。**不需要你提供或购买任何 API Key。**
- **联系支持后端**：`https://msg.calcs.top/api/feedback` 已部署并在代码中硬编码，含 mailto 回退，无需配置。
- **推送证书**：CloudKit 推送走 aps-environment entitlement（自动签名），无需手动建证书。

---

## 二、✅ 自动配置记录（已由系统完成，无需操作）

### Capabilities 自动配置

| Capability | 说明 | 状态 |
|------------|------|------|
| iCloud (CloudKit) | 容器 `iCloud.com.zzoutuo.Habibling`，private DB | ✅ 已配置（entitlements） |
| App Groups | `group.com.zzoutuo.Habibling`（3 个 target 全部） | ✅ 已配置 |
| Push Notifications | aps-environment（CloudKit 订阅推送所需） | ✅ 已配置 |
| Background Modes | processing + remote-notification | ✅ 已配置 |
| BGTaskScheduler | `com.zzoutuo.Habibling.refresh`（~4h 刷新快照） | ✅ 已配置 |
| 麦克风 / 语音识别 | 用途字符串已填（语音笔记，设备端转写） | ✅ 已配置 |
| WidgetKit 扩展 | 主屏 + 锁屏小组件 target | ✅ 已配置 |
| Watch App | watchOS 10+ 伴随 App（WCSession 同步） | ✅ 已配置 |
| In-App Purchase | StoreKit 2 无需 entitlement | ✅ 代码完成 |
| Privacy Manifest | PrivacyInfo.xcprivacy 覆盖 3 个 target | ✅ 已配置 |
| 出口合规 | ITSAppUsesNonExemptEncryption=false | ✅ 已配置 |

### 后端服务

| 服务 | 说明 | 状态 |
|------|------|------|
| GLM 云代理 | cramjam-api.calcs.top（Cloudflare Worker，备 workers.dev）；devKey 仅 #if DEBUG，Release 零密钥 | ✅ 已部署（PHASE 0 实测） |
| 联系支持后端 | msg.calcs.top/api/feedback + mailto 回退 | ✅ 已部署 |
| 政策页面 | GitHub Pages（workflow 部署，4 页全部 200） | ✅ 已上线 |
| ATS | HTTPS 出站，无例外域 | ✅ 已配置 |

### 代码生成与质量

| 模块 | 说明 | 状态 |
|------|------|------|
| 核心功能 | ~48 个 Swift 文件，SwiftUI + SwiftData + MVVM | ✅ 已完成 |
| 购买模块 | PurchaseManager（StoreKit 2，交易监听 + 恢复） | ✅ 已完成 |
| AI 三引擎 | AICoachService（Apple Intelligence）→ GLMCloudService → 规则引擎回退 | ✅ 已完成 |
| QA 迭代 | 构建通过、单测 12/12、iPhone/iPad 冒烟、P0 修复 | ✅ 已完成 |
| 本地化 | 纯英文（美国市场），无中文 UI | ✅ 已完成 |

### 部署

| 项目 | 说明 | 状态 |
|------|------|------|
| GitHub 仓库 | https://github.com/asunnyboy861/Habibling | ✅ 已推送 |
| GitHub Pages | 4 个政策页（Landing/Support/Privacy/Terms）workflow 部署成功 | ✅ 已上线 |
| App Store 元数据 | keytext.md 全部验证通过（副标题 25/30，关键词 99/100） | ✅ 已生成 |
| 定价配置 | price.md（Plus 买断 + Cloud+ 订阅，无免费生成计数） | ✅ 已生成 |

---

## 三、能力检测详情

> 以下为 PHASE 2 原始检测数据。"Auto-Configured Capabilities" 与 "Manual Configuration Required" 的内容已重组到上方 Section 一 和 Section 二。

### Analysis

Based on us.md + Chinese guide keyword scan (iCloud sync/CloudKit, widget, watch, notification, live activity/dynamic island, camera photo logging, voice transcription, Siri, StoreKit 2 IAP). Camera was later removed in PHASE 4+5 QA (no camera feature ships; NSCameraUsageDescription deleted from Info.plist and project.yml).

### Project Structure (auto-created via xcodegen 2.44.1)

- `Habibling.xcodeproj` — 3 targets:
  - **Habibling** (iOS app, com.zzoutuo.Habibling, iOS 17.0+, iPhone+iPad)
  - **HabiblingWidgets** (widget extension, com.zzoutuo.Habibling.Widgets)
  - **HabiblingWatch** (watchOS app, com.zzoutuo.Habibling.watchkitapp, watchOS 10.0+)
- Shared snapshot code in `Shared/` compiled into all three targets (App Group JSON pattern — extensions never touch SwiftData)

### No Configuration Needed

- HealthKit, Location, Sign in with Apple — not in guide scope
- Siri entitlement — App Intents framework requires no special entitlement

### Verification

- Build succeeded after configuration: ✅ (sim build, BUILD SUCCEEDED)
- All entitlements correct: ✅
- Signing verification (generic/platform=iOS): ✅ PASSED — all targets signed "Apple Development: he zhou (VX3Q75X27B)", BUILD SUCCEEDED with `-allowProvisioningUpdates`
- DEVELOPMENT_TEAM: JP4TN5PTS3 baked at project level (inherited by all targets)
- PrivacyInfo.xcprivacy: App + Widgets + Watch (all targets)
