# Olsztyn Public Transport — interactive map

Interactive, poster-grade map of the public transport network of **Olsztyn**:
33 bus lines and the five tram lines of the network that opened in 2015 — the
first new tram system built in Poland since the war. 317 stops, 917 km.

## Live

Local build on port 8171 (`npm run serve`).

Everything comes from ONE feed published by **ZDZiT Olsztyn**. ZDZiT posts
DATED files on its own `/gtfs/` page rather than one stable URL, so
`download.sh` resolves the newest from the listing; the Mobility Database
mirror of this feed (mdb-1175) is a year stale and is not used.

| mode | route_type | graph |
|---|---|---|
| buses | 3 | OSM roadways |
| trams | 0 | `railway=tram` |

**The feed ships no shapes at all** — there is no `shapes.txt` in the file. The
engine falls back to pseudo-matching, where the ordered stop sequence IS the
observation the HMM rides, exactly as in Grodzisk and the Rybnik county feeds.
That is why the weighted mean error here (5.32 m) is the highest of this batch:
with no shape to follow, the line is reconstructed from the poles alone.

Cut deliberately: **Z-1 … Z-5**, the tram-replacement buses. They ran for six
days in July 2026 while the track was closed, they duplicate the tram
corridors, and the trams themselves run across the whole feed period — the
calendar proves it, and Budapest's *pótló* rule settles it.

## Pipeline

`npm run download` fetches the feed and cuts the OSM extract. **The OSM
data comes from Geofabrik, not Overpass** — the public mirrors were answering
504 to every request on the day this map was built, even for a single small
city box — so `pipeline/pbf-tiles.py` (needs `pip3 install --user osmium`)
clips the tiles out of `warminsko-mazurskie-latest.osm.pbf`, writing exactly the JSON shape Overpass would
have returned, node ids included.

`npm run build` map-matches every line (HMM/Viterbi on the OSM graph) and
writes GeoJSON to `data/out/`; `npm run lines` adds the line-by-line view.
`npm run serve` hosts the map at <http://localhost:8171>.

Data: ZDZiT Olsztyn ·
base map © OpenFreeMap / OpenMapTiles / OpenStreetMap contributors.
