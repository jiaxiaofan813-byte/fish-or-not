# Fish or Not — Product Decisions

> This document is the current product source of truth for design and feature-scope decisions. Read this before implementing new features or materially changing the user flow.
>
> Product principle: **keep the app simple, fast, practical, and memorable.** Do not add features merely because they are possible.

## 1. Core Product Promise

Fish or Not answers one practical question and turns it into an actionable fishing plan:

> **Is it worth going fishing, when should I go, where should I go, what should I target, and what should I bring?**

The core experience should remain short:

1. Open the app.
2. Tap **Fish or Not**.
3. See a brief branded transition animation.
4. Receive the best upcoming fishing window.
5. See the recommended place, target species, line/lure or bait guidance, and key reasoning.
6. Navigate to a practical fishing access point.
7. Optionally share the plan.

The app should not become a generic fishing social network, article library, or all-purpose outdoor app.

---

## 2. Brand and Naming

### English

**Fish or Not**

### Simplified Chinese

**钓鱼还是摸鱼**

The Chinese name is intentionally playful rather than a literal translation. “摸鱼” is a Chinese-language pun and should be treated as localized brand copy, not translated back literally.

---

## 3. Signature Home-Screen Interaction

The home screen should remain visually minimal. The primary **Fish or Not** control is integrated into a simple fish illustration: **the button functions visually as the fish's eye**.

### Tap transition

After the user taps the fish-eye button:

1. The eye/button reacts briefly to the tap.
2. A fishing line and hook appear from the top of the screen.
3. The hook catches the fish.
4. The fish gives a short, playful struggle/tail movement.
5. The fish is pulled off screen.
6. The next results interface is revealed.

Target duration: roughly **0.8–1.3 seconds**. The animation should feel like a branded transition, not a delay.

A future variation may allow the animation to reflect the recommendation result (for example, a successful bite on a strong fishing day and a missed bite on a poor day), but V1 should prioritize a polished, reliable transition over branching animation complexity.

Implementation preference: native SwiftUI animation where practical. Avoid introducing a game engine solely for this transition unless the visual design later requires it.

---

## 4. Recommendation Result

The result should answer the user's question quickly and then provide the minimum useful detail.

Priority information:

- Clear recommendation: e.g. **FISH / NOT TODAY** or equivalent localized copy.
- Fishing score or ranking indicator.
- Best upcoming time window.
- Recommended water/location.
- Target species.
- Suggested lure/bait and line/leader guidance when supported by the data.
- Short explanation of the most important conditions behind the recommendation.
- Navigation to a useful access point.
- Quick share action.

The score is a **relative trip-suitability score**, not a probability of catching a fish.

Avoid information overload. The first screen should give the decision; supporting details can progressively disclose below it.

---

## 5. Maps and Navigation — V1

Maps are part of the useful core experience, but Fish or Not should **not** build its own turn-by-turn navigation system.

### V1 behavior

- Show the recommended water in MapKit.
- Store and display practical fishing access points when possible, such as:
  - public boat launch
  - shore-fishing access
  - fishing pier
  - parking/access area
- Provide a **Navigate** action that hands the destination to Apple Maps.

### Important data rule

Do **not** navigate users to a generic pin placed in the middle of a lake. The useful destination is an actual legal/practical access point.

Therefore, the difficult part of this feature is not MapKit; it is maintaining trustworthy water + access-point data.

### Not V1

- custom turn-by-turn navigation
- live boat tracking
- social fishing-spot heatmaps
- community waypoint sharing
- full bathymetric/depth-map system

---

## 6. Sharing — V1; Accounts Later

### V1: no account required

Use the native iOS Share Sheet to share a compact fishing-plan card containing useful information such as:

- Fish or Not result / score
- date and best window
- location
- target species
- key weather context

Where practical, include a deep/universal link that can open the same fishing-plan context in Fish or Not.

The goal is a fast flow:

**Result → Share → Friend opens plan**

### Later: Fishing Buddies

A real friend system is deliberately postponed because it introduces accounts, identity, backend state, privacy, requests, blocking, moderation, synchronization, and other product complexity.

If social coordination is added later, the preferred concept is **Fishing Buddies**, potentially using Sign in with Apple, with a lightweight invitation action such as:

> **I'm In 🎣**

Do not build a generic social feed unless the product direction materially changes.

---

## 7. Localization Strategy

Fish or Not should be localization-ready **from day one**, while product development remains **English-first**.

### Engineering rules

- Do not hard-code user-visible strings throughout SwiftUI views.
- Use Apple's localization system / String Catalogs (`.xcstrings`).
- Use stable semantic identifiers in data models rather than English display names.
  - Good: `largemouth_bass`
  - Avoid using `Largemouth Bass` as the canonical database identifier.
- Localize units, dates, measurements, species names, result copy, sharing copy, and safety text.

### Workflow

1. Build and refine the core UX in English.
2. Keep Chinese strings available during development so layout/localization problems are found early.
3. Perform a dedicated Chinese copy/localization pass once V1 interactions stabilize.

The English and Chinese brand names may intentionally differ in tone:

- English: **Fish or Not**
- Chinese: **钓鱼还是摸鱼**

---

## 8. Ice Fishing

Ice fishing can fit the product because it answers the same core question in winter, but safety claims require special restraint.

### Do not provide a precise predicted ice thickness as a safety fact

Fish or Not should not display a weather-derived estimate such as “7.3 inches of ice” as though it were measured or sufficient to establish safe travel. Ice conditions can vary substantially across the same body of water.

### Preferred V1/V1.5 concept: Ice Conditions

Useful information may include:

- recent freezing/warming trend
- temperature history relevant to freezing conditions
- snow-cover context when reliable data exists
- recent verified/local ice reports when trustworthy data is available
- explicit indication when ice conditions are **unverified**

A fishing recommendation and ice-safety confidence must remain conceptually separate. A great bite forecast does not mean the ice is safe.

Preferred wording should be conservative, e.g.:

> **Ice conditions: Unverified**
>
> Verify ice locally before entering.

Never state **“Safe to fish”** based solely on modeled or remote conditions.

### Possible future feature

Allow recent point-specific ice-thickness measurements with location and timestamp. These should be presented as measurements at specific points, never as proof that the entire lake has the same thickness.

---

## 9. Contextual Fishing Tips — V1/V1.5

Fishing education is useful, but Fish or Not should **not** become an article/content portal.

Use short, contextual tips inside recommendations, for example:

> **Tip:** Overcast conditions can allow bass to roam farther from cover.

Tips should be tied to the current species, weather, presentation, gear, or technique whenever possible.

No separate article library is required for the initial product.

---

## 10. Knot Quick Reference — V1/V1.5

A lightweight knot reference fits the product because it helps users immediately execute the recommended setup.

Preferred behavior:

- Recommend a knot from the current line / leader / lure setup when possible.
- Tap **How to tie** to open a fast visual walkthrough.
- Keep knot instructions available offline if practical.

Initial knot set can remain small, for example:

- Palomar
- Improved Clinch
- Uni Knot
- Double Uni
- FG Knot
- Loop Knot
- Snell Knot

This should be integrated into gear recommendations instead of becoming a large standalone encyclopedia.

Example:

> 10 lb braid → 8 lb fluorocarbon leader  
> **Recommended knot: Double Uni**  
> **How to tie →**

---

## 11. Fish Camera — V2

This is a promising differentiating feature, but it should not delay the core product.

Long-term concept:

> **Point. Identify. Measure. Check the rules.**

Potential capabilities:

1. Detect / classify fish species from the camera.
2. Estimate or assist with fish-length measurement.
3. Look up applicable harvest regulations for the location, date, and species.

### Accuracy constraints

Species classification can use computer vision / Core ML, but it needs an appropriate fish dataset and confidence handling.

Fish length should not be presented as precise from an arbitrary single photo without scale information. More defensible approaches include:

- guided AR measurement
- explicit nose/tail measurement points
- a known-size reference object

### Harvest-rule constraints

“Can I keep it?” is not merely species + length. It can depend on:

- jurisdiction
- exact water body
- date/season
- species
- size limits / protected slots
- possession/daily limits
- special local regulations

Until the regulatory-data pipeline is trustworthy, prefer showing **current applicable rules** rather than making an unconditional legal decision.

This feature belongs in **V2**, not the initial MVP.

---

## 12. Scope Guardrails

The project should actively resist feature creep.

### Core / V1 direction

- Fish or Not primary decision
- weather-based upcoming fishing windows
- recommended water and practical access point
- target species
- basic tackle / bait / line guidance
- MapKit view + handoff to Apple Maps
- native sharing
- localization-ready English + Chinese architecture
- safety/fallback states

### V1 / V1.5 lightweight enhancements

- contextual fishing tips
- knot recommendation / quick reference
- ice-condition context when winter support is introduced

### V2

- Fish Camera
- fish identification
- guided measurement
- location-aware regulation lookup
- possibly Fishing Buddies if user demand justifies accounts/backend complexity

### Explicitly not a priority now

- social feed
- chat/messaging
- generic fishing community
- marketplace
- large article library
- custom navigation engine
- complex account system
- feature-heavy dashboard

---

## 13. Product Decision Filter

Before adding a new feature, ask:

1. Does it help answer **whether, when, where, what to target, or what to bring**?
2. Does it help the angler execute the recommendation immediately?
3. Can it be presented without making the core flow slower or more cluttered?
4. Is the underlying data trustworthy enough for the claim being made?
5. Could this feature wait until after the core recommendation is validated?

If the answer to #5 is yes, default to postponing it.

The product's competitive advantage should come from **useful recommendations, speed, trust, and memorable interaction**, not from having the largest feature list.

---

## 14. Initial Launch Geography

Confirmed by the product owner on October 29, 2026: **Minnesota, United States** is the initial launch region.

This sets the geographic direction; it does not imply statewide verified coverage. Select a small initial set of waters and confirm practical public access points, species records, source provenance, and update dates before enabling live recommendations or navigation. The initial city / subregion and specific waters remain to be selected.
