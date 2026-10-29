# Fish or Not

**One question. Your next fishing plan.**

An iPhone app that helps you decide **whether to fish, when to go, where to go, what to target, and what to bring**—based on the next few days of weather, nearby waters, fish species, and the gear you already own.

> **FISH OR NOT?**
>
> Find your best fishing window.

**Status:** Runnable iOS 17+ pilot with live Apple Maps driving estimates, NOAA/NWS hourly forecasts, a transparent local recommendation engine, and DNR species records. Includes 50 Twin Cities waters and 91 source-checked public access points. Scores describe trip-weather comfort, not catch probability.

> **Development note:** Before changing product scope or core UX, read [`docs/PRODUCT_DECISIONS.md`](docs/PRODUCT_DECISIONS.md). It is the current source of truth for approved product decisions, scope guardrails, localization, sharing, maps, ice-fishing safety, knots, tips, and the planned Fish Camera.

## Run the Prototype

Open `FishOrNot.xcodeproj` in Xcode 16 or later, select the **FishOrNot** scheme and an iPhone simulator, then Run. The deployment target is **iOS 17+**. No API key or account is required. On a physical iPhone, select your signing team and a unique bundle identifier.

1. Choose a starting point using current location or a city/address search.
2. Set your maximum drive, shore/boat access, duration and target fish in **Preferences**. Optionally classify your gear.
3. Tap **FISH OR NOT?**. Choose **All waters**, a straight-line mile radius, a county, or **Favorites** on the home screen before tapping. Star waters in the catalog or detail screen. All eligible waters inside that scope are compared.
4. Review the best window, verified access, current drive estimate, recorded species and gear suggestions. Open Apple Maps or share the plan.

GPS is session-only; a manually selected origin, preferences and gear stay on this iPhone. Weather errors offer retry, with recent cached forecasts labeled explicitly. Empty results explain what could not fit. The result reports the comparison scope and links to its sources. Times use Minnesota's America/Chicago zone; units follow the locale. English and Simplified Chinese are included.

The neutral circular button still reveals a fish eye, full fish and hook, then catches or escapes after the live result is ready. Reduce Motion skips the decorative animation. There are no fictional recommendations in normal launches.

**Validation:** Run `swift test` for the core. Set `FISH_OR_NOT_NETWORK_TEST=1` to include the real NWS smoke test. Product → Test in Xcode runs simulator flows, localization, missing-data states, manual origin search and the real MapKit/NWS integration. With multiple Xcode installations, select the full developer directory first. See [`docs/LIVE_RECOMMENDATIONS.md`](docs/LIVE_RECOMMENDATIONS.md) for sources, score rules, freshness, comparison limits, privacy and test fixtures.

## Product Vision

Turn a simple question—“Should I go fishing?”—into a clear, practical plan. Fish or Not starts with a recommendation, then explains the conditions behind it so anglers can make their own call.

The first release will focus on short freshwater trips in a limited launch area, with a curated set of waters and species. The launch pilot is the Twin Cities metropolitan area in Minnesota; the 50-water / 91-access-point catalog is documented in [`docs/WATER_SOURCES.md`](docs/WATER_SOURCES.md).

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
- **Local trip preferences:** Starting location, maximum drive time, shore or boat access, available trip duration and target fish.
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
| Forecast data | NOAA/NWS hourly API for the US pilot; replaceable provider, WeatherKit planned after provisioning |
| Location | Core Location, with a manual location fallback |
| Water and species data | Bundled, curated local records with source and update metadata |
| Preferences and gear | On-device Codable profiles in UserDefaults; public weather cache in Caches |
| Recommendations | Local Swift rules and scoring engine with explainable factors |

Start with a native app and local data. Validate the recommendation flow before adding server infrastructure or more complex models. Map display alone will not establish fishing access or species coverage; those details need their own maintained records.

## Roadmap

- [x] Establish the project name, product vision, and repository homepage.
- [x] **1 · Define the first trip:** Twin Cities pilot, 50 waters, source-matched species and transparent initial weather factors.
- [x] **2 · Prototype the core flow:** Build the large-button home screen and result screen using clearly labeled sample data, including local preferences and gear storage.
- [x] **3 · Connect real inputs:** Local preferences/gear, GPS/manual origin, actual MapKit driving estimates and NWS forecasts.
- [ ] **4 · Field-validate recommendations:** Local ranking, explanations, backup plans and missing-data handling are implemented; calibrate the heuristics with real trip feedback.
- [ ] **5 · Test the MVP:** Refine accessibility, permission flows, forecast attribution, and trip usability, then prepare a TestFlight beta.

Milestones describe planned work, not release commitments. This is an open-water pilot: live inputs are connected, while field calibration, seasonal closure coverage and beta preparation remain.

## 简短中文说明

**Fish or Not（钓鱼还是摸鱼）** 是 iPhone 钓鱼出行助手，回答去不去、什么时候去、去哪、钓什么、带什么。当前版本已接通真实定位／手动出发点、Apple 地图车程、NOAA/NWS 未来五天逐小时天气，以及 50 个 Twin Cities 水域的入口与鱼种记录。点按前可选全部水域、英里半径、County 或收藏，并比较范围内全部符合条件的水域。装备支持分类与鱼种匹配，结果支持导航及分享。

用 Xcode 打开 `FishOrNot.xcodeproj` 即可运行，无需天气 API key。评分是透明规则计算的出行天气舒适度，不代表上鱼概率，也不判断冰面或水域安全。鱼种记录属于历史依据；49 个水域有记录，缺少记录的水域不会被猜测推荐。具体规则、来源及局限见 [`docs/LIVE_RECOMMENDATIONS.md`](docs/LIVE_RECOMMENDATIONS.md)。


### Scope and waiting interaction update

Users choose all catalog waters, a mile radius, a county, or favorites before tapping. Favorite IDs, radius and county persist with existing preferences; the legacy compare-all flag is decoded for migration but no longer limits scope to 12 waters. The shared press/eye/fish/hook reveal starts immediately, then holds with a small worm on the hook while inputs load. Only the catch/lift or hesitate/turn/escape ending waits for the verdict. Escape flips the fish to face left before it swims left. Reduce Motion continues to skip decorative motion, and cancellation resets the scene.


### Statewide Minnesota directory

The bundled LakeFinder snapshot now contains **7,788 unique water IDs** from searches of all **87 counties** (Red Lake County returns no records). It includes lakes, reservoirs and river records present in LakeFinder, rather than every physical water body in Minnesota. **2,842** have fish listings; **1,706** have matched public access, totaling **2,386** access records. Waters without a matched entrance remain searchable and favoritable but cannot generate navigation or trip recommendations. Lake details include available area/depth data and links to official surveys, maps and regulations.

Trip searches evaluate up to the **60 nearest eligible waters** within the chosen county, radius or favorites scope. The result discloses evaluated versus eligible counts; this is not an exhaustive statewide ranking. Old favorites retain their stable DNR IDs.

Refresh: `python3 scripts/import_minnesota.py` validates a new snapshot without saving; add `--write` to replace resources after validation. `--resume` reuses downloaded responses less than an hour old. Coverage counts and exclusions are recorded in `MinnesotaImportManifest.json`. Access review expires after 90 days; official status and site signs still apply.
