# Live trip planning — Twin Cities pilot

The normal iPhone app uses live inputs. Demonstration windows are available only through explicit DEBUG UI-test scenarios. Missing routes or weather never fall back to fictional data.

## Starting point and driving time

- Tap **Choose starting point**. Use Core Location with When In Use permission, or search a city/address with MapKit. Permission is requested only when **Use current location** is tapped. Denied, unavailable, inaccurate or stale GPS fixes lead to the manual option.
- A selected city/address is saved on this iPhone. GPS fixes are session-only and must be refreshed after 30 minutes. **Clear starting point** removes the saved origin. There is no account or app backend.
- Apple receives the origin and destination for local search/directions. NWS receives public access coordinates, never the origin. Only public lake weather is cached on disk; driving estimates stay in memory for at most five minutes.
- Eligible waters require a current, compatible public-access record and recorded supported species. Candidate order uses straight-line distance. For each water, use the closest eligible access point by straight-line distance; this does not guarantee the fastest of every possible entrance.
- Home scope is **All waters**, a straight-line mile radius from the origin to the chosen access, one county, or saved favorite water IDs. All eligible waters in that scope are compared, up to the 50-water catalog. The result reports evaluated waters, successful routes, waters inside the drive limit and successful forecasts, including partial failures. It never claims a global optimum over unexamined waters.
- `MKDirections.calculateETA` calculates actual automobile travel time and distance, with a 20-second timeout and sequential requests. Unavailable routes are excluded; no distance-to-minutes conversion is used. The selected drive limit is enforced against the returned time, rounded up to minutes.
- ETA is for departure around the time of evaluation. It is not future-day traffic prediction. Manual-origin navigation opens Apple Maps with that starting point; GPS-origin navigation lets Maps use the current location. Navigation rechecks destination eligibility at the time of the tap.

## Hourly weather

The pilot uses the official [NOAA/National Weather Service API](https://www.weather.gov/documentation/services-web-api), which provides US hourly forecasts without an API key. `ForecastProviding` isolates the provider so WeatherKit can be added after Apple service provisioning; this version does not silently request WeatherKit credentials.

1. Resolve `/points/{latitude},{longitude}` to an NWS hourly grid URL.
2. Fetch hourly temperature, sustained wind, precipitation probability, summary and NWS day/night flags. Wind ranges use the maximum. Celsius is converted before scoring. Unknown temperature, precipitation, wind, invalid units and incomplete hourly intervals are excluded, rather than treated as zero.
3. Reuse a grid mapping for 24 hours and a forecast for 30 minutes. On a request failure, a cached forecast can be used only if fetched within **3 hours**, issued within **6 hours**, and containing future hours. Future-dated invalid cache records are rejected. Cached results are labeled; issuance and fetch timestamps and the NWS source link appear in the result.
4. Evaluate available hours in the next five Minnesota calendar days, including today. The arrival time is the current time plus the returned driving time and 15 minutes of preparation. Windows must be contiguous and fit the selected 1–4-hour duration, entirely in daylight and before the five-day boundary. Missing hours never bridge a gap. The result shows the forecast's available end time; an incomplete forecast does not become a complete five-day claim.

NWS availability and issuance latency can vary. This version does not consume water temperature, water level, wave height, severe-weather alert feeds, live closure reports, ice measurements or predicted fish activity. Those omissions limit the advice. Recheck conditions before traveling.

## Transparent weather-comfort ranking

These are initial product heuristics, **not a scientifically calibrated bite model or a safety forecast**. There is no moon/solunar score, machine learning or invented catch probability.

Exclude windows containing darkness, thunder, snow, sleet, freezing precipitation, air temperature below 35°F, sustained wind above 22 mph from shore or 15 mph by boat, or precipitation probability above 80%. Then require a score of at least 65:

```
score = clamp(100
    - 1.4 × maximum wind (mph)
    - 0.35 × maximum precipitation probability (%)
    - 1.5 × max(0, 45 - average air temperature (°F))
    - 1.5 × max(0, average air temperature (°F) - 80), 0, 100)
```

Rank by score, then earlier start, then shorter drive. The backup uses another water or calendar day. **YES** means the best window is today; **NOT TODAY** gives the best later window. **NO WINDOW YET** explains when no evaluated window fits. Errors retrieving all routes or all reachable forecasts are shown separately with retry. Air temperature is not used to infer ice absence, thickness or safe access.

## Species evidence

`SpeciesEvidence.json` contains **50 lake-ID-matched profiles** from the official [DNR LakeFinder by-ID API](https://services.dnr.state.mn.us/api/lakefinder/by_id/v1/usage.html), queried on October 29, 2026. **49 profiles have species listings**. Lake Vadnais (`62001000`) has no species listing in that response, so it remains browsable but does not receive a species recommendation.

- Bluegill requires `bluegill`; crappie requires `black crappie` or `white crappie`; bass requires `largemouth bass` or `smallmouth bass`. Rock bass is not mapped to this bass target.
- A requested target must occur in the water's record. With Any Species, prefer a recorded target for which the user has more explicitly classified gear. Ties follow the stable supported-species order, with no biological claim.
- Preserve the DNR species names as published. Dates reflect the API source check, **not the date of a fish survey**. This listing does not supply a survey year; `surveyYear` stays null and the UI says so. Presence is historical evidence, not a live abundance or bite report.
- Source links are individual lake API records. Water details show supported targets and source provenance. No harvest eligibility is calculated; current DNR regulations remain linked for the user to check.

Recheck with `python3 scripts/review_species_records.py` (dry run). Inspect changes before using `--write` and committing a new snapshot. Access records have their separate source review policy in `WATER_SOURCES.md`.

## Gear advice

Gear items retain their name and packed state, and add a category and optional target species. Existing free-text gear migrates to Unclassified, with no name-based compatibility inference. Users can classify existing items or classify while adding them. A category and explicit target are required for a match; Any Species matches general tools only. Packed state is an independent checklist, not a compatibility signal.

For the chosen recorded species, show compatible owned items separately from generic missing categories. This version does not infer rod power, line strength or lure weight from arbitrary names and does not claim equipment optimization.

Guidance sources:

- [DNR bluegill profile](https://www.dnr.state.mn.us/minnaqua/speciesprofile/bluegill.html): light tackle, 6 lb line and small hooks with worm pieces.
- [DNR crappie guidance](https://www.dnr.state.mn.us/mcvmagazine/issues/2021/may-jun/crappie.html): small jigs with plastic/bait and optional slip-float presentation.
- [DNR fishing equipment](https://www.dnr.state.mn.us/fishing/fin/equipment.html): general rod/line matching and artificial lure guidance, including crankbaits for bass.

## Validation and test fixtures

Core tests cover catalog/species joins, supported-species matching, explicit scope, driving limits, source failures, arrival time, five-day boundary, daylight, weather exclusions, continuity, gear migration/classification, origin persistence, cancellation, wind/unit parsing and cache freshness. `FISH_OR_NOT_NETWORK_TEST=1 swift test` also fetches a real NWS forecast and verifies cache reuse.

DEBUG UI tests set an isolated `FISH_OR_NOT_TEST_PROFILE` and an explicit `FISH_OR_NOT_TEST_SCENARIO`. `demo`/`today` retain legacy animation regression fixtures. `live-success`, `live-weather-error`, `live-no-window` use deterministic protocol implementations over the real catalog. `live-no-origin` exercises manual MapKit search and persistence. `live-network` uses production MapKit and NWS services from a public Minneapolis starting point. Normal launches and Release builds use live services; they never seed an origin or show fixture recommendations.


### Scope and waiting interaction update

Users choose all catalog waters, a mile radius, a county, or favorites before tapping. Favorite IDs, radius and county persist with existing preferences; the legacy compare-all flag is decoded for migration but no longer limits scope to 12 waters. The shared press/eye/fish/hook reveal starts immediately, then holds with a small worm on the hook while inputs load. Only the catch/lift or hesitate/turn/escape ending waits for the verdict. Escape flips the fish to face left before it swims left. Reduce Motion continues to skip decorative motion, and cancellation resets the scene.
