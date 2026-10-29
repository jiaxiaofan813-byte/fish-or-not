# Development status — October 29, 2026

## Current increment: 50 real waters and Apple Maps navigation

The Twin Cities pilot now includes **50 real waters and 91 source-checked public access points**. The catalog is separate from the decision button's fictional weather and recommendation results.

### Implemented

- Home and result screens open **Explore 50 real waters**.
- Offline water list with multiword name/county/lake-number search and county plus shore/boat filters. All 50 waters have a public shore-fishing site, pier or breakwater; 41 also have a separately sourced trailer launch.
- Water details support access-point selection and an embedded MapKit preview pinned to the selected public access, rather than a lake centroid.
- Apple Maps driving handoff uses the selected access name and coordinates. Eligibility is rechecked on tap. Failed app handoffs show a retry message. The final approach can require walking from signed parking.
- Each access links to its exact DNR record and displays the source-check date. Each water links to DNR LakeFinder. Source checks are not field inspections or live opening reports.
- Real-water sharing includes the selected public access and an Apple Maps directions link, with current-condition context. It does not attach demo weather or scores to real waters.
- English and Simplified Chinese UI includes the list, county/mode filters, detail, source labels, navigation action, errors and sharing context. Official place/facility names stay in their source language for recognition on maps and signs.
- Bundled catalog loading fails visibly on missing or invalid data. Duplicate lake/site IDs, unexpected regions, non-DNR source hosts, invalid coordinates and malformed verification records fail validation. Unknown, mismatched or overdue points cannot produce navigation destinations.
- Source provenance, included waters and the 90-day editorial review policy are documented in `WATER_SOURCES.md`.

## Verification

- Queried all **91 individual DNR source records**, checked stable IDs and coordinates, and matched lake IDs between fishing sites and launches.
- **17 core tests passed**, including catalog resource loading, counts, shore/boat filtering, search, routing coordinates, expiry, and invalid-data handling, plus existing recommendation, persistence, migration and animation tests.
- **7 UI tests passed** on iPhone 18 Pro / iOS 27.0. The water tests cover Chinese search and shore-only details, county filtering and same-name/multiword search, 50/41/all filtering, launch selection, enabled navigation, actual Apple Maps foreground handoff and return to the app. Four existing tests cover localized decisions, saved preferences, repeated taps and the catch ending.
- Full simulator build and all UI tests succeeded; inspected the exported 50-water list and county/name-disambiguation screenshots.

- Added a dry-run-first source review tool, including checks for changed coordinates, names, lake IDs, access types and published alerts.

## Existing behavior retained

The large neutral circular button reveals a fish eye, full fish and hook before branching into a catch or escape. Reduce Motion skips decorative motion. Demo destinations remain blocked from real navigation. Existing preferences and gear remain local and compatible with the original English identifiers.

## Remaining work

- Real forecast integration, user-selected starting location and actual route-time comparison inside recommendations.
- Species-specific data and validated tackle guidance for the real-water catalog.
- Exact-plan restoration links; unsupported `fishornot://` links remain omitted.
- Periodic source review and eventual catalog update delivery. This release bundles source records checked on October 29, 2026; app navigation pauses for records that pass their individual review deadline.

No accounts, social feed, Fish Camera or modeled ice-thickness claims are added.
