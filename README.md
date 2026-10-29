# Fish or Not

**One question. Your next fishing plan.**

An iPhone app that helps you decide **whether to fish, when to go, where to go, what to target, and what to bring**—based on the next few days of weather, nearby waters, fish species, and the gear you already own.

> **FISH OR NOT?**
>
> Find your best fishing window.

**Status:** Working SwiftUI prototype with offline demo recommendations. Live weather, maps, location, and real water coverage are not connected yet.

> **Development note:** Before changing product scope or core UX, read [`docs/PRODUCT_DECISIONS.md`](docs/PRODUCT_DECISIONS.md). It is the current source of truth for approved product decisions, scope guardrails, localization, sharing, maps, ice-fishing safety, knots, tips, and the planned Fish Camera.

## Run the Prototype

Open `FishOrNot.xcodeproj` in Xcode 16 or later, select the **FishOrNot** scheme and an iPhone simulator, then Run. The deployment target is **iOS 17+**. No API keys, account, or paid services are required for the demo. To run on a physical iPhone, select your own signing team and a unique bundle identifier in Xcode.

The prototype includes the neutral circular home button with a shared fish-eye reveal and catch-or-escape endings, a recommendation result, a no-match state, editable trip preferences, and a locally saved gear checklist. All weather, water names, scores, and drive times are fictional sample data. Dates are anchored when the plan is created, with times in Minnesota’s America/Chicago time zone. Gear you own is listed separately from general suggestions; tackle compatibility is not yet scored.

**Validation:** Run `swift test` for the local recommendation engine. In Xcode, use Product → Test to run the simulator flow and persistence checks. The core tests run independently of the iOS UI via the small Swift package in this repository.

## Product Vision

Turn a simple question—“Should I go fishing?”—into a clear, practical plan. Fish or Not starts with a recommendation, then explains the conditions behind it so anglers can make their own call.

The first release will focus on short freshwater trips in a limited launch area, with a curated set of waters and species. The launch pilot is the Twin Cities metropolitan area in Minnesota; its initial waters and access points still need to be verified.

## Core Experience

1. **Open the app.** Tap a neutral circular **Fish or Not** button. Only after the tap, a roughly one-second fish reveal and catch-or-escape ending leads into the plan; Reduce Motion skips the animation. Small **My Gear** and **Preferences** entries support the main action.
2. **Tap once.** Compare available fishing windows over the next five days with nearby locations, target species, and your preferences.
3. **Get a direct answer.** See **YES** or **NOT TODAY**, followed by the best available plan. If today looks poor, show the next better opportunity when one is available.
4. **Understand the plan.** See why the window ranks well, where to fish, what to target, what to bring, and a backup option when available.

### Example result

*Illustrative only; this is not a live forecast or a real location recommendation.*

> **YES. GO SATURDAY.**
>
> **Best window:** 6:40–9:10 AM
>
> **Where:** Example Lake · 18 min away
>
> **Target:** Crappie
>
> **Score:** 89 / 100
>
> **Bring:** Ultralight rod, small jigs, and your existing light tackle
>
> **Why:** A favorable morning window that fits your shore access and gear preferences.

The score will be a relative ranking of trip suitability, **not a probability of catching fish**. Results should explain their main factors and clearly identify missing or stale data. If the app cannot make a useful recommendation, it should say so.

## MVP Scope

- **Simple home screen:** One primary button and a short path from question to plan.
- **Local trip preferences:** Starting location, maximum drive time, shore or boat access, available trip duration, target fish, and bait preferences.
- **My Gear:** A small, manually maintained inventory of rods, tackle, and bait to inform practical suggestions.
- **Weather comparison:** Evaluate upcoming windows using available forecast conditions such as temperature, wind, precipitation, and daylight.
- **Nearby waters:** Start with curated location, access, and species records for the selected launch area, displayed with a map and travel context.
- **Local recommendation engine:** Rank compatible time, place, and species combinations with transparent rules and explainable scoring.
- **Actionable result:** Yes/No decision, best time window, recommended location, target species, score, gear checklist, supporting reasons, and a backup when available.
- **Useful fallback states:** Handle denied location access, unavailable forecasts, and insufficient local coverage; allow a manually selected starting location.

### Later, beyond the MVP

Catch logs, personalized learning, notifications, widgets, Apple Watch, Siri Shortcuts, broader geographic coverage, and richer species or tackle guidance. Social feeds, a marketplace, and a cloud account system are outside the initial scope.

## Planned Tech Stack

| Area | Planned approach |
| --- | --- |
| iPhone interface | Swift and SwiftUI |
| Maps and travel context | MapKit |
| Forecast data | WeatherKit, subject to service setup and availability |
| Location | Core Location, with a manual location fallback |
| Water and species data | Bundled, curated local records with source and update metadata |
| Preferences and gear | On-device persistence; storage choice to be finalized during prototyping |
| Recommendations | Local Swift rules and scoring engine with explainable factors |

Start with a native app and local data. Validate the recommendation flow before adding server infrastructure or more complex models. Map display alone will not establish fishing access or species coverage; those details need their own maintained records.

## Roadmap

- [x] Establish the project name, product vision, and repository homepage.
- [ ] **1 · Define the first trip:** Choose the launch area, initial waters and species, data sources, and scoring factors.
- [x] **2 · Prototype the core flow:** Build the large-button home screen and result screen using clearly labeled sample data, including local preferences and gear storage.
- [ ] **3 · Connect real inputs:** Add preferences, gear storage, location, maps, and forecasts.
- [ ] **4 · Build and validate recommendations:** Implement local ranking, explanations, backup plans, and missing-data behavior; compare results with field feedback.
- [ ] **5 · Test the MVP:** Refine accessibility, permission flows, forecast attribution, and trip usability, then prepare a TestFlight beta.

Milestones describe planned work, not release commitments. The current build is an offline prototype; it is not ready to make real fishing recommendations.

## 简短中文说明

**Fish or Not** 是一款计划中的 iPhone 钓鱼决策助手。首页只有一个醒目的 **FISH OR NOT?** 主按钮，点击后根据未来几天天气、附近钓点、鱼种、个人偏好和已有装备，回答：**去不去、什么时候去、去哪、钓什么、带什么**。

第一版计划从有限区域的淡水钓鱼场景开始，采用 SwiftUI、MapKit、WeatherKit，以及本地数据与可解释的推荐引擎。当前已包含可运行的 SwiftUI 原型：大按钮首页、推荐结果、空结果、装备清单和偏好设置；真实天气、地图及钓点尚未接入。用 Xcode 打开 `FishOrNot.xcodeproj`，选择 iPhone 模拟器即可运行。

## October 29, 2026 development increment

- Native SwiftUI signature interaction: a large neutral glowing circle compresses, shrinks into a fish eye, and reveals a fish and hook. Both results share this reveal; a positive result catches and lifts the fish, while a negative result lets it swim away (about 1.0–1.1 seconds).
- Repeated taps are disabled during the transition. Returning home or interrupting the app resets the interaction. Reduce Motion skips the decorative motion and delay.
- English / Simplified Chinese String Catalogs cover the home, results, settings, gear, and share summary. Dates and measurement units follow the locale; stored species and access IDs remain language-independent.
- The Twin Cities metropolitan area in Minnesota is the confirmed launch pilot. Data remains fictional; map previews and navigation require a non-demo plan plus a sourced, current, public, compatible access record.
- Shared demo plans include a demo disclaimer, an absolute date and time window, and a suitability-score explanation. No app links are emitted until exact-plan restoration is implemented.
- Simulator verification requires a full Xcode installation. Command Line Tools alone cannot build or run this iOS interface.
