#!/usr/bin/env python3
"""Validate offline photo coverage, attribution, and unchanged downloaded bytes."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
resources = ROOT / 'FishOrNot/Core/Resources'
photos = json.loads((resources / 'SpeciesPhotos.json').read_text())
sources = json.loads((ROOT / 'docs/FishPhotoSources.json').read_text())
expected = {n for row in json.loads((resources / 'SpeciesEvidence.json').read_text()) for n in row['recordedNames']}
expected = (expected - {'yellow perch', 'northern pike'}) | {'perch', 'pike', 'bass'}
assert len(photos) == len({p['speciesID'] for p in photos})
assert {p['speciesID'] for p in photos} == expected
assets = ROOT / 'FishOrNot/Assets.xcassets/FishPhotos'
for source in sources.values():
    assert source['license'] in {'cc0', 'cc-by'}
    folder = assets / f"fish-photo-{source['photoID']}.imageset"
    config = json.loads((folder / 'Contents.json').read_text())
    data = (folder / config['images'][0]['filename']).read_bytes()
    assert hashlib.sha256(data).hexdigest() == source['sha256']
for photo in photos:
    assert (assets / (photo['assetName'] + '.imageset')).is_dir()
    assert photo['credit'] and photo['scientificName']
    assert photo['license'] in {'CC0', 'CC BY'}
    assert photo['sourceURL'].startswith('https://www.inaturalist.org/observations/')
    assert photo['licenseURL'].startswith('https://www.inaturalist.org/photos/')
assert next(p for p in photos if p['speciesID'] == 'northern pike (silver phase)')['representative']
print(f"Validated {len(photos)} choices and {len(sources)} licensed, bundled photographs.")
