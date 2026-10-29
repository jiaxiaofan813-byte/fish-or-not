# Fish or Not

**One question. Your next fishing plan.**

An iPhone app that helps you decide **whether to fish, when to go, where to go, what to target, and what to bring**—based on the next few days of weather, nearby waters, fish species, and the gear you already own.

> **FISH OR NOT?**
>
> Find your best fishing window.

**Status:** Product planning. This repository establishes the product vision and MVP scope; the iOS app is not implemented yet.

## Product Vision

Turn a simple question—“Should I go fishing?”—into a clear, practical plan. Fish or Not starts with a recommendation, then explains the conditions behind it so anglers can make their own call.

The first release will focus on short freshwater trips in a limited launch area, with a curated set of waters and species. The exact launch area is still to be selected.

## Core Experience

1. **Open the app.** A large **FISH OR NOT?** button is the center of the home screen. Small **My Gear** and **Preferences** entries support the main action.
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
- [ ] **2 · Prototype the core flow:** Build the large-button home screen and result screen using clearly labeled sample data.
- [ ] **3 · Connect real inputs:** Add preferences, gear storage, location, maps, and forecasts.
- [ ] **4 · Build and validate recommendations:** Implement local ranking, explanations, backup plans, and missing-data behavior; compare results with field feedback.
- [ ] **5 · Test the MVP:** Refine accessibility, permission flows, forecast attribution, and trip usability, then prepare a TestFlight beta.

Milestones describe planned work, not release commitments. No build or installation steps are available until the app project is added.

## 简短中文说明

**Fish or Not** 是一款计划中的 iPhone 钓鱼决策助手。首页只有一个醒目的 **FISH OR NOT?** 主按钮，点击后根据未来几天天气、附近钓点、鱼种、个人偏好和已有装备，回答：**去不去、什么时候去、去哪、钓什么、带什么**。

第一版从有限区域的淡水钓鱼场景开始，采用 SwiftUI、MapKit、WeatherKit，以及本地数据与可解释的推荐引擎。当前仓库处于产品规划阶段，尚未包含可运行的 App。
