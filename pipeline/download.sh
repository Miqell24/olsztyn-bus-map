#!/usr/bin/env bash
# Downloads input data: the ZDZiT Olsztyn GTFS, the OSM extract, MapLibre GL.
# Everything is cached — re-running only fetches what is missing.
#
# ZDZiT publishes DATED files on its own /gtfs/ page rather than one stable
# URL, so the newest is resolved from the listing (the Mobility Database
# mirror of this feed, mdb-1175, is a year stale).
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p data/gtfs data/osm/tiles web/vendor

# pyosmium does the cutting; it is the one dependency outside Node here.
need_osmium () {
  python3 -c "import osmium" 2>/dev/null && return 0
  echo "brak pakietu osmium — zainstaluj: pip3 install --user osmium" >&2
  return 1
}

# 1) GTFS
if [ ! -f data/gtfs/routes.txt ]; then
  echo "== ZDZiT Olsztyn: resolving the newest GTFS file =="
  URL=$(curl -fsSL --max-time 60 -A "Mozilla/5.0" "https://zdzit.olsztyn.eu/gtfs/" \
    | python3 -c 'import sys,re
z=sorted(set(re.findall(r"https://zdzit\.olsztyn\.eu/wp-content/uploads/[0-9/]+/GTFS_[0-9_]+\.zip", sys.stdin.read())))
if not z: raise SystemExit("no GTFS file on the ZDZiT page")
print(z[-1])')
  echo "-- $URL"
  curl -fL --retry 3 --max-time 600 -A "Mozilla/5.0" -o data/olsztyn-gtfs.zip "$URL"
  unzip -o data/olsztyn-gtfs.zip -d data/gtfs
fi

# 2) OSM — from the Geofabrik extract, not Overpass.
#    2 x 2 road tiles plus the tram network, out of the Geofabrik
#    warminsko-mazurskie extract.
#    pipeline/pbf-tiles.py cuts the tiles out of the .pbf and writes exactly the
#    JSON shape Overpass would have returned (ways with tags, NODE IDS and
#    geometry — buildGraph silently drops ways without el.nodes).
if [ ! -f data/osm/tiles/t4.json ] || [ ! -f data/osm/olsztyn-rail.json ]; then
  need_osmium
  if [ ! -f data/warminsko-mazurskie-latest.osm.pbf ]; then
    echo "== Geofabrik warminsko-mazurskie-latest.osm.pbf =="
    curl -fL --retry 5 --retry-delay 5 -C - --max-time 3600 -o data/warminsko-mazurskie-latest.osm.pbf \
      "https://download.geofabrik.de/europe/poland/warminsko-mazurskie-latest.osm.pbf"
  fi
  echo "== cutting OSM tiles out of the extract =="
  python3 pipeline/pbf-tiles.py
fi

# 3) MapLibre GL (vendored, no CDN at runtime)
if [ ! -f web/vendor/maplibre-gl.js ]; then
  echo "== MapLibre GL =="
  curl -fL --retry 3 -o web/vendor/maplibre-gl.js  https://unpkg.com/maplibre-gl@5.6.1/dist/maplibre-gl.js
  curl -fL --retry 3 -o web/vendor/maplibre-gl.css https://unpkg.com/maplibre-gl@5.6.1/dist/maplibre-gl.css
fi

echo "OK — data ready:"
du -sh data/gtfs data/osm 2>/dev/null || true
