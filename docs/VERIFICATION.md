# Verification — Mirpur 12 Flood Response

Godot 4.3 stable, Windows. All commands exited 0.

| Suite | Result |
|---|---|
| `CityTest.tscn` | `[CITY2D] PASS` — 1,500 buildings, **764 real roads**, 150 named roads, 1,098 amenities, 437 shelters, 84 flood segments |
| `EconomyTest.tscn` | `[ECON] PASS` — 15 operations, supplies, boats/pumps/medkits, XP/levels, skills, quests, save/reload |
| `run_all.ps1` | `[OP] ALL 15 OPERATIONS PASS` — every operation built the real city, spawned victims, rescued/sheltered people, deployed a pump, completed quests and ended successfully |

## Urban fidelity loop

1. Queried OpenStreetMap (Overpass API) for Mirpur 12 (23.8154–23.8354 N, 90.3597–90.3797 E): 764 highways, 20,025 buildings, 1,098 amenities.
2. Converted the extract to `assets/maps/mirpur12.json` and self-rendered `mirpur12_osm.png`.
3. Placed relief posts on named roads and used real clinic/school/pharmacy/water-point amenities as shelters.
4. Added flood overlays on deterministic real road segments; the minimap shows the flooded network.
5. Cleared leftover scripts/scenes from the previous game and fixed GDScript typing errors found on first run.
6. Fixed test property access so the deep suite exercises real rescue/shelter/pump interactions rather than counters.

## Gameplay checks

- All 15 operations passed through real `interact()` hooks: victim pickup, shelter delivery and pump deployment.
- Team skills, quests, XP/levels and supplies verified and persisted.
- Six real gameplay frames captured from the running game (menu, operation, team, quests, supplies, summary).
- Windows export built and launched successfully.

Made by S M Nazmuz Sakib. Map data © OpenStreetMap contributors (ODbL 1.0).
