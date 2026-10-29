#!/usr/bin/env python3
"""Recheck existing DNR records. Dry-run by default; --write renews matching records only."""
import argparse
import concurrent.futures
import datetime
import json
from pathlib import Path
import subprocess
from urllib.parse import urlparse

CATALOG = Path(__file__).resolve().parents[1] / 'FishOrNot/Core/Resources/TwinCitiesWaters.json'
COUNTIES = {'Anoka', 'Carver', 'Dakota', 'Hennepin', 'Ramsey', 'Scott', 'Washington'}
SITE_TYPES = {'Fishing Pier': 'fishing_pier', 'Shore Fishing Site': 'shore_access',
              'Breakwater Fishing Site': 'breakwater'}


def check(pair):
    water, point = pair
    url = point['verification']['sourceURL']
    parsed = urlparse(url)
    if parsed.scheme != 'https' or parsed.hostname != 'enterprise.gisdata.mn.gov' or not parsed.path.startswith('/aghost/rest/services/us_mn_state_dnr/'):
        raise ValueError(f"Unexpected source: {point['id']}")
    response = subprocess.run(['curl', '--fail', '--location', '--retry', '2', '--max-time', '45',
                               '--silent', '--show-error', url], capture_output=True, text=True, check=True)
    records = json.loads(response.stdout).get('features', [])
    if len(records) != 1:
        raise ValueError(f"Missing or ambiguous source: {point['id']}")
    record = records[0]
    properties, geometry = record['attributes'], record['geometry']
    boat = point['type'] == 'boat_launch'
    guid = properties['stable_prod_guid' if boat else 'fc_prod_facility_pt_id'].strip('{}').lower()
    lake = properties['dow_lake_id' if boat else 'dow_lake_number']
    if guid != point['id'] or lake != water['lakeNumber'] or properties['county_name'] not in COUNTIES:
        raise ValueError(f"Source identity/region changed: {point['id']}")
    expected_type = 'boat_launch' if boat else SITE_TYPES.get(properties['fishing_site_type'])
    if expected_type != point['type'] or (boat and (properties['launch_type'] != 'Trailer Launch' or str(properties.get('alerts') or '').strip())):
        raise ValueError(f"Access type/alert needs manual review: {point['id']}")
    name = properties['access_name' if boat else 'facility_name']
    if name != point['name']:
        raise ValueError(f"Facility name changed; review before renewing: {point['id']}")
    if abs(geometry['x'] - point['longitude']) > 1e-6 or abs(geometry['y'] - point['latitude']) > 1e-6:
        raise ValueError(f"Coordinates changed; review before renewing: {point['id']}")
    if set(point['verification']['supportedAccess']) != {'boat' if boat else 'shore'}:
        raise ValueError(f"Unexpected access modes: {point['id']}")
    return point


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true', help='Renew check/review dates only after all selected records match')
    parser.add_argument('--water-id', action='append', help='Check selected stable water IDs; omit to check the entire catalog')
    args = parser.parse_args()
    catalog = json.loads(CATALOG.read_text())
    wanted = set(args.water_id or [w['id'] for w in catalog['waters']])
    waters = [w for w in catalog['waters'] if w['id'] in wanted]
    if {w['id'] for w in waters} != wanted:
        parser.error('Unknown water ID')
    pairs = [(water, point) for water in waters for point in water['accessPoints']]
    # Any failure stops the run before dates or files are changed.
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as executor:
        points = list(executor.map(check, pairs))
    now = datetime.datetime.now(datetime.timezone.utc).replace(microsecond=0)
    if args.write:
        for point in points:
            point['verification']['checkedAt'] = now.isoformat().replace('+00:00', 'Z')
            point['verification']['reviewBy'] = (now + datetime.timedelta(days=90)).isoformat().replace('+00:00', 'Z')
        temporary = CATALOG.with_suffix('.json.tmp')
        temporary.write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + '\n')
        temporary.replace(CATALOG)
    print(f"Matched {len(waters)} waters / {len(points)} official records. " + ('Dates renewed.' if args.write else 'Dry run; catalog unchanged.'))


if __name__ == '__main__':
    main()
