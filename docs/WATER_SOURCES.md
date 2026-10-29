# Twin Cities water catalog — October 29, 2026

The shipped catalog contains **10 distinct waters and 18 public access points**: 10 shore-fishing sites/piers and 8 separate trailer-launch sites. These are real places, available independently of the fictional weather/recommendation demo.

## Sources and method

- [Minnesota DNR public fishing sites](https://enterprise.gisdata.mn.gov/aghost/rest/services/us_mn_state_dnr/struc_fishing_sites_in_minnesota/FeatureServer/0): point coordinates, lake numbers, fishing-site types, public facility names, and managing agencies.
- [Minnesota DNR public water access sites](https://enterprise.gisdata.mn.gov/aghost/rest/services/us_mn_state_dnr/struc_water_access_sites/FeatureServer/0): trailer-launch points, stable site IDs, lake numbers, and published alerts.
- [DNR fishing pier overview](https://www.dnr.state.mn.us/fishing_piers/index.html) and [water-access status guidance](https://www.dnr.state.mn.us/water_access/index.html).

The curated resource is `FishOrNot/Core/Resources/TwinCitiesWaters.json`. Coordinates were requested directly from the official services with `outSR=4326` (longitude/latitude). Each of the 18 individual record queries was fetched and checked for a single matching record and the same coordinates. Lake numbers were matched between shore and launch records. Selected launch records had no published alert in the retrieved response; **a null alert is not a live confirmation that a facility is open**.

Stable source GUIDs, exact individual source query URLs, the source-check timestamp, and a review deadline are included with each access point. Legacy Calhoun facility names are retained as source names under the water's current Bde Maka Ska name. Search also recognizes Calhoun. No species populations, catch forecasts, travel times, fee exemptions, or current opening status have been inferred from these points.

## Included waters

Coordinates below identify the primary fishing access point, not a lake centroid. Additional launch coordinates are in the resource.

| Water | DNR lake number | County | Access points | Primary fishing access (lat, lon) | Water information |
| --- | --- | --- | ---: | --- | --- |
| Lake Harriet | 27001600 | Hennepin | 2 | 44.928173, -93.306156 | [DNR LakeFinder](https://www.dnr.state.mn.us/lakefind/lake.html?id=27001600) |
| Lake Nokomis | 27001900 | Hennepin | 2 | 44.901981, -93.244615 | [DNR LakeFinder](https://www.dnr.state.mn.us/lakefind/lake.html?id=27001900) |
| Bde Maka Ska | 27003100 | Hennepin | 2 | 44.937432, -93.304600 | [DNR LakeFinder](https://www.dnr.state.mn.us/lakefind/lake.html?id=27003100) |
| Medicine Lake | 27010400 | Hennepin | 2 | 44.999973, -93.428513 | [DNR LakeFinder](https://www.dnr.state.mn.us/lakefind/lake.html?id=27010400) |
| Lake Phalen | 62001300 | Ramsey | 1 | 44.990444, -93.057273 | [DNR LakeFinder](https://www.dnr.state.mn.us/lakefind/lake.html?id=62001300) |
| Como Lake | 62005500 | Ramsey | 1 | 44.976166, -93.137122 | [DNR LakeFinder](https://www.dnr.state.mn.us/lakefind/lake.html?id=62005500) |
| Lake Josephine | 62005700 | Ramsey | 2 | 45.034798, -93.149192 | [DNR LakeFinder](https://www.dnr.state.mn.us/lakefind/lake.html?id=62005700) |
| Lake Johanna | 62007800 | Ramsey | 2 | 45.047110, -93.176355 | [DNR LakeFinder](https://www.dnr.state.mn.us/lakefind/lake.html?id=62007800) |
| Bald Eagle Lake | 62000200 | Ramsey | 2 | 45.113923, -93.001978 | [DNR LakeFinder](https://www.dnr.state.mn.us/lakefind/lake.html?id=62000200) |
| White Bear Lake | 82016700 | Ramsey | 2 | 45.073828, -93.014861 | [DNR LakeFinder](https://www.dnr.state.mn.us/lakefind/lake.html?id=82016700) |

## Navigation and review policy

- Shore and boat access remain separate. A trailer-launch listing does not imply permission to fish from its dock. Waters without a sourced launch are omitted from the boat filter.
- A selected access point is revalidated when navigation is tapped. Invalid, unknown, incompatible, or overdue records cannot produce a route destination.
- Apple Maps receives the access point coordinate and name, using driving directions. Its road routing may end near the site; follow posted parking signs and walk the remaining section. These are not surveyed parking-space coordinates.
- Source checks are desk checks against official records, not field inspections or live opening/ice reports. The app links to the exact access record and DNR LakeFinder for current conditions.
- The bundled catalog works offline for browsing and source metadata. Map tiles, source websites, and Apple Maps routing require their respective network services.
- This initial catalog uses a **90-day editorial review window** from the recorded check timestamp. This is an app maintenance policy, not a DNR guarantee. Expired records remain inspectable but lose navigation until reviewed and updated in a subsequent app version.
- Before renewing a record, re-query its stable GUID, compare its lake ID, coordinates, type and public-use description, inspect available alerts, and check the managing agency's current restrictions. Never renew a date without rechecking its source.
