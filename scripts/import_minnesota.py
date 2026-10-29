#!/usr/bin/env python3
"""Validate statewide LakeFinder. --write publishes after all 87 counties/GIS pages validate; --resume reuses downloads under one hour old."""
import concurrent.futures as futures
import datetime as dt
import hashlib
import sys
import time
import json
from pathlib import Path
import subprocess
from urllib.parse import urlencode

ROOT = Path(__file__).resolve().parents[1]
RES = ROOT / 'FishOrNot/Core/Resources'
CACHE = Path('/tmp/fish-or-not-statewide-import')
CACHE.mkdir(exist_ok=True)
COUNTY_URL = 'https://maps.dnr.state.mn.us/cgi-bin/gazetteer/gazetteer2.cgi?type=county'
SEARCH = 'https://maps.dnr.state.mn.us/cgi-bin/lakefinder/search.cgi'
GIS = 'https://enterprise.gisdata.mn.gov/aghost/rest/services/us_mn_state_dnr/'

def fetch(url):
    cached = CACHE / (hashlib.sha256(url.encode()).hexdigest()+'.json')
    if '--resume' in sys.argv and cached.exists() and time.time()-cached.stat().st_mtime < 3600:
        return json.loads(cached.read_text())
    raw = subprocess.check_output(['curl', '-fLsS', '--retry', '3', '--max-time', '90', url])
    obj = json.loads(raw)
    if 'error' in obj: raise ValueError(obj['error'])
    (CACHE / (hashlib.sha256(url.encode()).hexdigest()+'.json')).write_bytes(raw)
    return obj

def county(c):
    url = SEARCH+'?'+urlencode({'county':c['id']})
    d = fetch(url)
    if d.get('results') is None and d.get('status') == 'ERROR' and d.get('message') == 'Search returned no results.':
        d['results'] = []
    assert isinstance(d.get('results'), list), c
    rows=d['results']
    assert all(str(r['county_id'])==str(c['id']) for r in rows), c
    print(c['name'], len(rows), flush=True)
    return c, rows

def gis(layer):
    base=GIS+layer+'/FeatureServer/0/query?'
    ids=fetch(base+urlencode({'where':'1=1','returnIdsOnly':'true','f':'json'}))['objectIds']
    allrows=[]
    for i in range(0,len(ids),200):
        page=fetch(base+urlencode({'objectIds':','.join(map(str,ids[i:i+200])),'outFields':'*','outSR':4326,'f':'json'}))
        assert not page.get('exceededTransferLimit'), layer
        allrows+=page['features']
    assert {f['attributes']['objectid'] for f in allrows}==set(ids)
    return allrows

def main():
    counties=fetch(COUNTY_URL)['results']
    assert len(counties)==87 and len({c['id'] for c in counties})==87
    with futures.ThreadPoolExecutor(max_workers=4) as pool: groups=list(pool.map(county,counties))
    records={}
    for c,rows in groups:
        for r in rows:
            assert len(r['id'])==8 and r['id'].isdigit() and r['name'] and r['county']
            if r['id'] in records and records[r['id']] != r:
                canonical = fetch('https://services.dnr.state.mn.us/api/lakefinder/by_id/v1?id='+r['id'])['results']
                assert canonical and all(a['id']==r['id'] for a in canonical)
                assert all({k:v for k,v in a.items() if k!='name'}=={k:v for k,v in canonical[0].items() if k!='name'} for a in canonical)
                r=dict(canonical[0]); r['name']=' / '.join(sorted({a['name'] for a in canonical}))
            records[r['id']]=r
    now=dt.datetime.now(dt.timezone.utc).replace(microsecond=0)
    stamp=now.isoformat().replace('+00:00','Z');review=(now+dt.timedelta(days=90)).isoformat().replace('+00:00','Z')
    points={};excluded={};seen=set()
    def skip(reason):excluded[reason]=excluded.get(reason,0)+1
    for layer,boat in [('struc_water_access_sites',True),('struc_fishing_sites_in_minnesota',False)]:
        for f in gis(layer):
            a=f['attributes'];g=f.get('geometry') or {}
            lake=a.get('dow_lake_id' if boat else 'dow_lake_number')
            if lake not in records:skip('no_exact_lakefinder_id');continue
            typ='boat_launch' if boat else {'Fishing Pier':'fishing_pier','Shore Fishing Site':'shore_access','Breakwater Fishing Site':'breakwater'}.get(a.get('fishing_site_type'))
            if not typ or (boat and (a.get('launch_type')!='Trailer Launch' or str(a.get('alerts') or '').strip())):skip('type_or_alert');continue
            if not (43.4<=g.get('y',0)<=49.5 and -97.3<=g.get('x',0)<=-89.4):skip('invalid_coordinate');continue
            key='stable_prod_guid' if boat else 'fc_prod_facility_pt_id'
            uid=(a.get(key) or '').strip('{}').lower()
            if not uid or uid in seen:skip('duplicate_or_missing_id');continue
            if not a.get('access_name' if boat else 'facility_name'):skip('missing_access_name');continue
            seen.add(uid)
            source=GIS+layer+'/FeatureServer/0/query?'+urlencode({'where':key+" = '"+a[key]+"'",'outFields':'*','outSR':4326,'f':'pjson'})
            points.setdefault(lake,[]).append({'id':uid,'name':a['access_name' if boat else 'facility_name'],'type':typ,'latitude':g['y'],'longitude':g['x'],'note':a.get('directions'),'isDemo':False,'verification':{'sourceURL':source,'checkedAt':stamp,'reviewBy':review,'publicAccessConfirmed':True,'supportedAccess':['boat' if boat else 'shore'],'regionID':'us_mn'}})
    waters=[];species=[]
    for lake,r in sorted(records.items()):
        m=r.get('morphology') or {}
        waters.append({'id':'mn-'+lake,'name':r['name'],'county':r['county'],'lakeNumber':lake,'lakeFinderURL':'https://www.dnr.state.mn.us/lakefind/lake.html?id='+lake,'accessPoints':points.get(lake,[]),'sourceCheckedAt':stamp,'areaAcres':m.get('area') or None,'maxDepthFeet':m.get('max_depth') or None,'availableReports':sorted(k for k,v in r.get('resources',{}).items() if v),'metadataSourceURL':SEARCH+'?county='+str(r['county_id'])})
        species.append({'lakeNumber':lake,'recordedNames':sorted({n.strip().lower() for group in r.get('fishSpecies',[]) for n in group.split(',') if n.strip()}),'sourceURL':'https://services.dnr.state.mn.us/api/lakefinder/by_id/v1?id='+lake,'checkedAt':stamp,'surveyYear':None})
    assert len(waters)>4500
    manifest={'checkedAt':stamp,'countySource':COUNTY_URL,'countyCounts':{c['name']:len(rows) for c,rows in groups},'waters':len(waters),'withSpecies':sum(bool(s['recordedNames']) for s in species),'withAccess':sum(bool(w['accessPoints']) for w in waters),'accessPoints':sum(map(len,points.values())),'excludedAccess':excluded,'scope':'All records returned by LakeFinder county searches, including reservoirs and river records; not all Minnesota water bodies.'}
    if '--write' not in sys.argv:
        print(json.dumps(manifest,indent=2));print('Dry run. Use --write to publish.');return
    for name,data in [('MinnesotaWaters.json',{'schemaVersion':1,'regionID':'us_mn','waters':waters}),('SpeciesEvidence.json',species),('MinnesotaImportManifest.json',manifest)]:
        path=RES/name;tmp=path.with_suffix('.tmp');tmp.write_text(json.dumps(data,ensure_ascii=False,separators=(',',':'))+'\n');tmp.replace(path)
    print(json.dumps(manifest,indent=2))

if __name__=='__main__':main()
