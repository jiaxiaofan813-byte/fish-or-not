#!/usr/bin/env python3
"""Fetch DNR species listings for the catalog. Dry-run first; --write replaces only after every ID validates."""
import argparse
import concurrent.futures
import datetime
import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]
TARGET = ROOT / 'FishOrNot/Core/Resources/SpeciesEvidence.json'


def fetch(water):
    lake = water['lakeNumber']
    url = 'https://services.dnr.state.mn.us/api/lakefinder/by_id/v1?id=' + lake
    response = subprocess.run(['curl', '--fail', '--location', '--retry', '2', '--max-time', '40',
                               '--silent', '--show-error', url], capture_output=True, text=True, check=True)
    data = json.loads(response.stdout)
    records = data.get('results', [])
    if data.get('status') != 'OK' or len(records) != 1 or records[0]['id'] != lake:
        raise ValueError('Missing or mismatched DNR lake ID: ' + lake)
    names = sorted({name.strip().lower() for group in records[0].get('fishSpecies', [])
                    for name in group.split(',') if name.strip()})
    return dict(lakeNumber=lake, recordedNames=names, sourceURL=url,
                checkedAt=datetime.datetime.now(datetime.timezone.utc).replace(microsecond=0).isoformat().replace('+00:00', 'Z'),
                surveyYear=None)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    waters = json.loads((ROOT / 'FishOrNot/Core/Resources/TwinCitiesWaters.json').read_text())['waters']
    old = {p['lakeNumber']: p for p in json.loads(TARGET.read_text())} if TARGET.exists() else {}
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
        profiles = list(pool.map(fetch, waters))
    for profile in profiles:
        previous = old.get(profile['lakeNumber'], {}).get('recordedNames')
        if previous != profile['recordedNames']:
            print(profile['lakeNumber'], 'species changed:', previous, '->', profile['recordedNames'])
    if args.write:
        temporary = TARGET.with_suffix('.json.tmp')
        temporary.write_text(json.dumps(profiles, ensure_ascii=False, indent=2) + '\n')
        temporary.replace(TARGET)
    print(f"{len(profiles)} profiles; {sum(bool(p['recordedNames']) for p in profiles)} with listings. " +
          ('Species snapshot written; inspect the diff before committing.' if args.write else 'Dry run; no files changed.'))


if __name__ == '__main__':
    main()
