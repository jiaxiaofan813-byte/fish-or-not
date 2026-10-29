# Twin Cities water catalog — October 29, 2026

The shipped catalog contains **50 distinct waters and 91 public access points**: 50 shore-fishing sites/piers/breakwaters and 41 separate trailer-launch sites. These are real places, available independently of the fictional weather/recommendation demo.

## Sources and method

- [Minnesota DNR public fishing sites](https://enterprise.gisdata.mn.gov/aghost/rest/services/us_mn_state_dnr/struc_fishing_sites_in_minnesota/FeatureServer/0): point coordinates, lake numbers, fishing-site types, public facility names, and managing agencies.
- [Minnesota DNR public water access sites](https://enterprise.gisdata.mn.gov/aghost/rest/services/us_mn_state_dnr/struc_water_access_sites/FeatureServer/0): trailer-launch points, stable site IDs, lake numbers, and published alerts.
- [DNR fishing pier overview](https://www.dnr.state.mn.us/fishing_piers/index.html) and [water-access status guidance](https://www.dnr.state.mn.us/water_access/index.html).

The curated resource is `FishOrNot/Core/Resources/TwinCitiesWaters.json`. Coordinates were requested directly from the official services with `outSR=4326` (longitude/latitude). Each of the 91 individual record queries was fetched and checked for a single matching record and the same coordinates. Lake numbers were matched between shore and launch records. Selected launch records had no published alert in the retrieved response; **a null alert is not a live confirmation that a facility is open**.

Stable source GUIDs, exact individual source query URLs, the source-check timestamp, and a review deadline are included with each access point. Legacy Calhoun facility names are retained as source names under the water's current Bde Maka Ska name. Search also recognizes Calhoun. No species populations, catch forecasts, travel times, fee exemptions, or current opening status have been inferred from these points.

## Included waters

Coordinates below identify the primary fishing access point, not a lake centroid. Additional launch coordinates are in the resource.

| Water | DNR lake number | County | Access points | Primary fishing access (lat, lon) | Water information |
| --- | --- | --- | ---: | --- | --- |
| Crooked Lake | 02008400 | Anoka | 2 | 45.209183, -93.339426 | [DNR LakeFinder](https://www.dnr.state.mn.us/lakefind/lake.html?id=02008400) |
| Golden Lake | 02004500 | Anoka | 2 | 45.137663, -93.152207 | [DNR LakeFinder](https://www.dnr.state.mn.us/lakefind/lake.html?id=02004500) |
| Ham Lake | 02005300 | Anoka | 2 | 45.253003, -93.223985 | [DNR LakeFinder](https://www.dnr.state.mn.us/lakefind/lake.html?id=02005300) |
| Linwood Lake | 02002600 | Anoka | 2 | 45.357119, -93.097500 | [DNR LakeFinder](https://www.dnr.state.mn.us/lakefind/lake.html?id=02002600) |
| Peltier Lake | 02000400 | Anoka | 2 | 45.172232, -93.068908 | [DNR LakeFinder](https://www.dnr.state.mn.us/lakefind/lake.html?id=02000400) |
| Ann Lake | 10001200 | Carver | 2 | 44.869640, -93.555990 | [DNR LakeFinder](https://www.dnr.state.mn.us/lakefind/lake.html?id=10001200) |
| Auburn Lake | 10004400 | Carver | 1 | 44.871205, -93.695594 | [DNR LakeFinder](https://www.dnr.state.mn.us/lakefind/lake.html?id=10004400) |
| Lake Susan | 10001300 | Carver | 2 | 44.853815, -93.541943 | [DNR LakeFinder](https://www.dnr.state.mn.us/lakefind/lake.html?id=10001300) |
| Minnewashta Lake | 10000900 | Carver | 2 | 44.878250, -93.619936 | [DNR LakeFinder](https://www.dnr.state.mn.us/lakefind/lake.html?id=10000900) |
| Steiger Lake | 10004500 | Carver | 2 | 44.865114, -93.657608 | [DNR LakeFinder](https://www.dnr.state.mn.us/lakefind/lake.html?id=10004500) |
| Waconia Lake | 10005900 | Carver | 2 | 44.852701, -93.792602 | [DNR LakeFinder](https://www.dnr.state.mn.us/lakefind/lake.html?id=10005900) |
| Blackhawk Lake | 19005900 | Dakota | 1 | 44.818574, -93.183115 | [DNR LakeFinder](https://www.dnr.state.mn.us/lakefind/lake.html?id=19005900) |
| Cobblestone Lake | 19045600 | Dakota | 1 | 44.721638, -93.166559 | [DNR LakeFinder](https://www.dnr.state.mn.us/lakefind/lake.html?id=19045600) |
| Crystal Lake | 19002700 | Dakota | 2 | 44.725177, -93.271854 | [DNR LakeFinder](https://www.dnr.state.mn.us/lakefind/lake.html?id=19002700) |
| Fish Lake | 19005700 | Dakota | 2 | 44.822546, -93.163685 | [DNR LakeFinder](https://www.dnr.state.mn.us/lakefind/lake.html?id=19005700) |
| Holland Lake | 19006500 | Dakota | 1 | 44.788976, -93.143781 | [DNR LakeFinder](https://www.dnr.state.mn.us/lakefind/lake.html?id=19006500) |
| Marion Lake | 19002600 | Dakota | 2 | 44.671539, -93.293049 | [DNR LakeFinder](https://www.dnr.state.mn.us/lakefind/lake.html?id=19002600) |
| Bde Maka Ska | 27003100 | Hennepin | 2 | 44.937432, -93.304600 | [DNR LakeFinder](https://www.dnr.state.mn.us/lakefind/lake.html?id=27003100) |
| Bryant Lake | 27006700 | Hennepin | 2 | 44.881577, -93.431155 | [DNR LakeFinder](https://www.dnr.state.mn.us/lakefind/lake.html?id=27006700) |
| Bush Lake | 27004700 | Hennepin | 2 | 44.831832, -93.381536 | [DNR LakeFinder](https://www.dnr.state.mn.us/lakefind/lake.html?id=27004700) |
| Fish Lake | 27011800 | Hennepin | 2 | 45.084685, -93.465625 | [DNR LakeFinder](https://www.dnr.state.mn.us/lakefind/lake.html?id=27011800) |
| Hyland Lake | 27004800 | Hennepin | 2 | 44.819244, -93.368118 | [DNR LakeFinder](https://www.dnr.state.mn.us/lakefind/lake.html?id=27004800) |
| Independence Lake | 27017600 | Hennepin | 2 | 45.019494, -93.644166 | [DNR LakeFinder](https://www.dnr.state.mn.us/lakefind/lake.html?id=27017600) |
| Lake Harriet | 27001600 | Hennepin | 2 | 44.928173, -93.306156 | [DNR LakeFinder](https://www.dnr.state.mn.us/lakefind/lake.html?id=27001600) |
| Lake Minnetonka | 27013300 | Hennepin | 2 | 44.897592, -93.668570 | [DNR LakeFinder](https://www.dnr.state.mn.us/lakefind/lake.html?id=27013300) |
| Lake Nokomis | 27001900 | Hennepin | 2 | 44.901981, -93.244615 | [DNR LakeFinder](https://www.dnr.state.mn.us/lakefind/lake.html?id=27001900) |
| Medicine Lake | 27010400 | Hennepin | 2 | 44.999973, -93.428513 | [DNR LakeFinder](https://www.dnr.state.mn.us/lakefind/lake.html?id=27010400) |
| Riley Lake | 10000200 | Hennepin | 2 | 44.836871, -93.512339 | [DNR LakeFinder](https://www.dnr.state.mn.us/lakefind/lake.html?id=10000200) |
| Round Lake | 27007100 | Hennepin | 2 | 44.868166, -93.490365 | [DNR LakeFinder](https://www.dnr.state.mn.us/lakefind/lake.html?id=27007100) |
| Weaver Lake | 27011700 | Hennepin | 2 | 45.107973, -93.497223 | [DNR LakeFinder](https://www.dnr.state.mn.us/lakefind/lake.html?id=27011700) |
| Wirth Lake | 27003700 | Hennepin | 2 | 44.983447, -93.320210 | [DNR LakeFinder](https://www.dnr.state.mn.us/lakefind/lake.html?id=27003700) |
| Bald Eagle Lake | 62000200 | Ramsey | 2 | 45.113923, -93.001978 | [DNR LakeFinder](https://www.dnr.state.mn.us/lakefind/lake.html?id=62000200) |
| Beaver Lake | 62001600 | Ramsey | 1 | 44.973466, -93.008203 | [DNR LakeFinder](https://www.dnr.state.mn.us/lakefind/lake.html?id=62001600) |
| Bennett Lake | 62004800 | Ramsey | 1 | 45.018682, -93.144697 | [DNR LakeFinder](https://www.dnr.state.mn.us/lakefind/lake.html?id=62004800) |
| Como Lake | 62005500 | Ramsey | 1 | 44.976166, -93.137122 | [DNR LakeFinder](https://www.dnr.state.mn.us/lakefind/lake.html?id=62005500) |
| Gervais Lake | 62000700 | Ramsey | 1 | 45.015108, -93.075672 | [DNR LakeFinder](https://www.dnr.state.mn.us/lakefind/lake.html?id=62000700) |
| Keller Lake | 62001000 | Ramsey | 2 | 45.012730, -93.063312 | [DNR LakeFinder](https://www.dnr.state.mn.us/lakefind/lake.html?id=62001000) |
| Lake Johanna | 62007800 | Ramsey | 2 | 45.047110, -93.176355 | [DNR LakeFinder](https://www.dnr.state.mn.us/lakefind/lake.html?id=62007800) |
| Lake Josephine | 62005700 | Ramsey | 2 | 45.034798, -93.149192 | [DNR LakeFinder](https://www.dnr.state.mn.us/lakefind/lake.html?id=62005700) |
| Lake Phalen | 62001300 | Ramsey | 1 | 44.990444, -93.057273 | [DNR LakeFinder](https://www.dnr.state.mn.us/lakefind/lake.html?id=62001300) |
| Silver Lake | 62000100 | Ramsey | 2 | 45.024039, -92.989599 | [DNR LakeFinder](https://www.dnr.state.mn.us/lakefind/lake.html?id=62000100) |
| White Bear Lake | 82016700 | Ramsey | 2 | 45.073828, -93.014861 | [DNR LakeFinder](https://www.dnr.state.mn.us/lakefind/lake.html?id=82016700) |
| Cedar Lake | 70009100 | Scott | 2 | 44.574143, -93.528328 | [DNR LakeFinder](https://www.dnr.state.mn.us/lakefind/lake.html?id=70009100) |
| Cleary Lake | 70002200 | Scott | 2 | 44.691187, -93.386265 | [DNR LakeFinder](https://www.dnr.state.mn.us/lakefind/lake.html?id=70002200) |
| Lower Prior Lake | 70002600 | Scott | 2 | 44.719260, -93.434998 | [DNR LakeFinder](https://www.dnr.state.mn.us/lakefind/lake.html?id=70002600) |
| O'Dowd Lake | 70009500 | Scott | 2 | 44.746450, -93.516429 | [DNR LakeFinder](https://www.dnr.state.mn.us/lakefind/lake.html?id=70009500) |
| Big Marine Lake | 82005200 | Washington | 2 | 45.205889, -92.872388 | [DNR LakeFinder](https://www.dnr.state.mn.us/lakefind/lake.html?id=82005200) |
| Elmo Lake | 82010600 | Washington | 2 | 44.980596, -92.888519 | [DNR LakeFinder](https://www.dnr.state.mn.us/lakefind/lake.html?id=82010600) |
| Square Lake | 82004600 | Washington | 2 | 45.154997, -92.795055 | [DNR LakeFinder](https://www.dnr.state.mn.us/lakefind/lake.html?id=82004600) |
| Tanners Lake | 82011500 | Washington | 2 | 44.952742, -92.979343 | [DNR LakeFinder](https://www.dnr.state.mn.us/lakefind/lake.html?id=82011500) |

### Seven-county coverage

| County | Waters |
| --- | ---: |
| Anoka | 5 |
| Carver | 6 |
| Dakota | 6 |
| Hennepin | 14 |
| Ramsey | 11 |
| Scott | 4 |
| Washington | 4 |

The original 10 waters and their stable access IDs remain in the catalog. The displayed county is the primary shore site’s county in the DNR record; cross-county lakes can have other access points in a neighboring county. Two different Fish Lakes are deliberately separate records: Dakota `19005700` and Hennepin `27011800`. Linwood is classified as a breakwater fishing site, matching its source rather than labeling it a pier.

## Navigation and review policy

- Shore and boat access remain separate. A trailer-launch listing does not imply permission to fish from its dock. Waters without a sourced launch are omitted from the boat filter.
- A selected access point is revalidated when navigation is tapped. Invalid, unknown, incompatible, or overdue records cannot produce a route destination.
- Apple Maps receives the access point coordinate and name, using driving directions. Its road routing may end near the site; follow posted parking signs and walk the remaining section. These are not surveyed parking-space coordinates.
- Source checks are desk checks against official records, not field inspections or live opening/ice reports. The app links to the exact access record and DNR LakeFinder for current conditions.
- The bundled catalog works offline for browsing and source metadata. Map tiles, source websites, and Apple Maps routing require their respective network services.
- This initial catalog uses a **90-day editorial review window** from the recorded check timestamp. This is an app maintenance policy, not a DNR guarantee. Expired records remain inspectable but lose navigation until reviewed and updated in a subsequent app version.
- Before renewing a record, re-query its stable GUID, compare its lake ID, coordinates, type and public-use description, inspect available alerts, and check the managing agency's current restrictions. Never renew a date without rechecking its source.

## Repeatable review tool

Run `python3 scripts/review_water_catalog.py` to check all individual source records without changing the catalog. It rejects a missing/ambiguous record, changed lake/site identity, facility name, coordinate, access type, unexpected region or nonempty launch alert. A failure prevents the file from being written.

Use `--water-id mn-02002600` to inspect one water, or repeat the flag for a subset. Only after source review, use `--write` to renew selected records' source-check timestamps and 90-day review deadlines. Names or coordinates that change upstream require manual review before renewal; they are not silently accepted by the tool. Water counts and the home-screen label are read from the bundled catalog rather than hard-coded in the UI.
