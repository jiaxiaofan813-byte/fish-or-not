# Development status — October 29, 2026

## Current increment: connected live trip planning

The primary decision button now uses **a real origin, actual driving estimates, hourly weather, source-backed species and classified gear**. The 50-water / 91-access-point Twin Cities catalog supports the result directly. There is no fictional fallback in normal launches.

### Implemented

- Current-location permission on demand, with manual MapKit city/address search and clear denied/unavailable states. Manual origin persists; GPS stays session-only and requires refresh after 30 minutes. Origin can be cleared.
- Actual MapKit automobile ETA to one nearby eligible public access per candidate water. The home screen offers all waters, mile radius, county or favorites before the tap. Star controls in the catalog and water detail persist favorite IDs on this iPhone. Driving limits, timeout, cancellation, retry and per-stage comparison counts are visible.
- Official NWS point/grid hourly forecasts over the next five Minnesota calendar days. Validate temperature, wind, rain, daylight, continuity, freshness and source host. Explicit recent-cache labeling and stale-data rejection; missing fields are never treated as favorable zero values.
- Explainable local weather-comfort ranking, 1–4-hour daylight windows, arrival/preparation time, weather exclusions, a best window and a different-water/day backup. Query time counts toward departure readiness. No-window, source errors and partial evaluations are distinct states.
- 50 lake-ID-matched DNR species profiles, 49 with listings. Missing species are excluded; rock bass is not mistaken for the bass target. Survey year remains unknown because the listing does not supply it. Results and water details link to official records and show check dates.
- Gear category and target classification for new and existing inventory, backward-compatible decoding, packed checklists and persistence. Classified compatible items appear separately from generic missing setup categories. Source-linked bluegill, crappie and bass guidance.
- Result map and verified-access navigation, source provenance, weather timestamps, transparent score rules, native plan sharing and official regulation links. Manual-origin navigation passes that origin to Maps. Destination eligibility is checked again when tapped.
- English and Simplified Chinese UI, locale-sensitive units/dates, Minnesota trip time, stable stored IDs, and localized location-permission copy. Source place names and raw DNR species names stay in English.
- Preserved the neutral circle → eye → fish → hook → catch/escape interaction, Reduce Motion, duplicate-tap protection and safe cancellation/restart. The branded animation follows actual data loading.

## Verification

- **31 core tests passed**, including an opt-in request to the real NWS hourly endpoint and cache reuse. Covers species/catalog joins, 12/all scope, actual-route constraints, window boundaries and continuity, weather exclusions, missing/stale data, offline cache rejection, classification/migration, origin persistence and cancellation.
- **15 distinct UI tests passed** across the regression and live suites, including the final gear/all-water persistence rerun. Simulator flows cover the legacy animation/localization regressions, live success, no-window, forecast failure/retry, cancellation/restart, manual MapKit search and saved origin, gear classification/persistence, all-water scope, source links and verified Maps handoff.
- Real network integration from a public Minneapolis starting point returned **12 real routes and 12 usable forecasts for 12 evaluated waters**. A later run returned 11 routes/forecasts out of 12 candidates and visibly disclosed the partial evaluation. These are observed smoke-test results, not permanent service-availability claims.
- Debug test build and Release simulator build succeeded. Exported screenshots are inspected for English/Chinese results, sources, access, no-data states and gear.
- Catalog sources were previously checked against all 91 individual DNR access records. Species snapshots were fetched for all 50 lake IDs. The dry-run-first tools support future access and species review.

## Practical limits and remaining work

- The score is an initial **trip-weather-comfort heuristic**, not field-validated catch prediction. Field feedback and calibration are still needed.
- Scope limits are explicit before the tap; distance is straight-line miles to the selected access. Each water uses one nearby access point, so comparisons do not establish the fastest entrance to every lake.
- NWS supplies US weather without a key. WeatherKit remains a provider option after Apple provisioning; it is not used in this build.
- Access records are historical source checks, not live opening reports. Current closures, ice, water temperature/levels, waves, severe-alert feeds and harvest eligibility are not modeled. The UI identifies open-water scope and links current DNR rules.
- No survey year or current abundance is fabricated. Generic gear advice does not infer exact rod/line/lure specifications from free text.
- Remaining beta work includes device field tests, recommendation calibration, catalog maintenance/update delivery, app icon/store/privacy preparation and TestFlight distribution. Exact-plan restoration links, contextual knot walkthroughs and later product features remain separate work.

No accounts, social feed, Fish Camera or modeled ice-thickness claims are added. See `LIVE_RECOMMENDATIONS.md` for provider details, policies and sources, and `WATER_SOURCES.md` for the access catalog.


### Scope and waiting interaction update

Users choose all catalog waters, a mile radius, a county, or favorites before tapping. Favorite IDs, radius and county persist with existing preferences; the legacy compare-all flag is decoded for migration but no longer limits scope to 12 waters. The shared press/eye/fish/hook reveal starts immediately, then holds with a small worm on the hook while inputs load. Only the catch/lift or hesitate/turn/escape ending waits for the verdict. Escape flips the fish to face left before it swims left. Reduce Motion continues to skip decorative motion, and cancellation resets the scene.

## Species and tackle expansion

Six supported groups: bluegill, crappie, bass, yellow perch, walleye and northern pike. Home filters combine species and typical species-size group with geographic scope. Size is not a measured lake population or guaranteed catch length. The water browser also filters official species records. All 50 DNR profiles were refreshed; 49 have species listings.

Results list supported recorded species with hook, natural bait and artificial lure suggestions. A general beginner approach order highlights the simplest starting option, not a validated catch probability. Waters with fewer than five supported groups disclose the gap and link to the full six-group guide. Hook sizes are starting suggestions; select for actual bait, tackle and local rules. Sources: https://www.dnr.state.mn.us/fishing/fin/equipment.html, https://www.dnr.state.mn.us/gofishing/how-catch-walleye.html, https://www.dnr.state.mn.us/gofishing/how-catch-northern-pike.html, https://www.dnr.state.mn.us/minnaqua/speciesprofile/yellowperch.html.

Waiting animation keeps separation between fish and hook, gently bobs the fish, and respects Reduce Motion. Existing ending phases close the gap before the catch or turn away before escape.
