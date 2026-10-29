# Fish reference photographs

75 selectable fish species/group entries are backed by 66 bundled real photographs (about 6.4 MB). Any species retains a neutral icon. Photos appear in the fish picker, recommendation rows, fish guides and water species lists. Full cards and the Fish photos & credits screen provide photographer attribution and links to the observation and the exact photo's license page.

Source: iNaturalist research-grade observations, retrieved 2026-10-29. Only photo-level CC0 or CC BY licenses were accepted; an observation's license alone is not sufficient. Exact source metadata, credited author string, download URL and file SHA-256 are recorded in `FishPhotoSources.json`. Images are bundled unmodified from the provider's medium-size rendition and displayed with aspect-fit. The API does not specify a Creative Commons version, so the app links to the original photo's license page instead of inventing one.

Broad entries (bass, crappie, suckers, redhorse, carpsucker, cisco species, sunfish and walleye/sauger) use explicitly labelled representative photographs. Hybrid sunfish shows bluegill × green sunfish. Silver-phase northern pike currently uses a labelled ordinary northern pike reference, not a verified photograph of that color phase. Bowfin uses Amia ocellicauda. Some rare fish are represented by juvenile specimens. These are visual references, not proof of a fish's presence in a particular lake or a substitute for identification.

## Maintenance

Run `python3 scripts/validate_fish_photos.py` after changing the species catalog or assets. Add a real photo with an eligible photo-level license, visually check that the fish is visible, preserve its bytes in an asset imageset, record its provenance in `FishPhotoSources.json`, then update `SpeciesPhotos.json`. Keep representative labels accurate. Do not replace photos with illustrations or reuse non-commercial-only material.
