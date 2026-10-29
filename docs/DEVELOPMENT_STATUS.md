# Development status — October 29, 2026

## Current increment: Twin Cities pilot and trusted-data boundaries

Product scope follows `docs/PRODUCT_DECISIONS.md`. The launch pilot is **Twin Cities, Minnesota**, confirmed by the product owner. No real waters or access points have been enabled yet.

### Implemented

- Home and preferences identify the selected pilot area without claiming verified coverage. The resting button is a dominant 232-point neutral circle with a restrained halo and press response. Both outcomes share the fish-eye zoom-out and hook reveal; only then does the fish get caught and lifted, or escape while the hook stays behind. The rejected ping-pong artwork has been removed. Transition budgets are 1.12 seconds for catch and 1.04 seconds for escape; Reduce Motion bypasses the sequence.
- Map previews and Apple Maps handoff require both a non-demo plan and a non-demo, verified access record. Verification must include an HTTPS source, a check date, a future review deadline, confirmation of public access, the supported fishing access modes, the pilot-region ID, and valid coordinates. The handoff rechecks eligibility when tapped. Review deadlines are supplied by record curators, not inferred from a coordinate.
- Fictional samples cannot launch navigation. The result explains that verified access is unavailable instead of displaying a real-world map of a fictional destination.
- Share summaries carry the demo disclaimer, an absolute plan date and window in Minnesota time, weather context, target species, and the score interpretation. They omit unverified access names and the unsupported `fishornot://` link. Exact-plan links remain deferred until routing and plan restoration exist.
- Result, preferences, gear, coverage, recommendation explanations, and share copy use English / Simplified Chinese String Catalog entries. Temperature and wind units follow the locale. User-entered gear names are preserved.
- Access, species, and access-point types use stable IDs. Legacy English access/species values remain readable so existing preferences and gear do not need to be discarded.
- Window dates are anchored when the recommendation is created; time ranges are formatted from structured hours/minutes in `America/Chicago` rather than hard-coded English time strings.

## Validation

- Core recommendation, persistence, migration, navigation eligibility, share formatting, and the shared reveal/timing contract: 12 tests passed.
- iOS simulator build passed. All 4 UI tests passed on the iPhone 17 / iOS 27.0 simulator: Chinese home/result, preference persistence and no-match fallback, repeated return/tap, and the positive catch ending.
- The first attempt to launch the updated UI suite stalled in the simulator test service. Restarting only the selected test device and running the already-built test products resolved it.
- The String Catalog contains 92 bilingual entries, checked for matching format placeholders.
- Earlier MapKit demo pins and their coordinates are **fictional fixtures**, not verified public access records. Earlier verification of a visible navigation button did not establish the validity of those destinations; this increment deliberately removes that behavior.

## Next data milestone

Curate a small initial set of Twin Cities waters. For each, record a stable water ID, species sources, an actual practical public access point, compatible shore/boat use, source URL, check date, and review deadline. Validate coordinates against the source and check current access restrictions before enabling any real destination. Integrate real forecasts separately; selecting a pilot area does not turn demo conditions into live recommendations.

No accounts, social feed, Fish Camera, ice-thickness prediction, or separate article library are introduced in this increment.
