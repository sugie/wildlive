# Game Master v0.3 → runtime data

How a number in the design workbook becomes a number on the Simulator
screen, and how to change one.

## The one path

```
docs/game-design/build_master_v0_3.py          canonical source (Python literals)
        │
        ├─→ WildLive-Game-Master-Draft-v0.3.xlsx     human review artifact
        │       (built by the same script; never read at runtime)
        │
        └─→ database/master/game-master-v0.3.json    runtime artifact
                │   (built by export_master_json.py, which imports the same module)
                │
                └─→ Database\Seeders\GameMasterSeeder
                        │
                        └─→ PostgreSQL master tables
                                │
                                └─→ API resources → iOS Domain types → screen
```

There is no second path. **The application never opens the .xlsx** — not in
a controller, not in a seeder, not in a command. The workbook is for humans;
the JSON is for the machine; both come from the same Python literals, so
they cannot disagree without that shared source changing first.

CI enforces it:

```bash
python3 docs/game-design/export_master_json.py --check
```

fails if the committed JSON differs from what the current Python would
produce. `tests/Feature/GameMasterDataTest.php` then checks the other half —
that what the seeder puts in PostgreSQL matches the JSON row for row.

## Changing a game value

1. Edit `docs/game-design/build_master_v0_3.py`.
2. `python3 docs/game-design/build_master_v0_3.py` — rebuilds the workbook
   (byte-deterministic, so the diff is only what you changed).
3. `python3 docs/game-design/export_master_json.py` — rebuilds the JSON.
4. `docker compose exec app php artisan db:seed --force` — upserts by Game
   Master id, so existing players' expeditions and animals survive.
5. Commit all three artifacts together.

Never hand-edit `database/master/game-master-v0.3.json`. It says so at the
top of the file.

## Sheet → table → API field

| Game Master sheet | PostgreSQL table | Primary key | Reaches the client as |
|---|---|---|---|
| Biomes | `biomes` | `biome_id` | `map.biome_id`, `hunter.preferred_biome_id` |
| Rarities | `rarities` | `rarity_id` | `animal.rarity.{id,name_en,sort_order}` |
| Maps | `maps` | `map_id` | `GET /api/players/{p}/maps` |
| Animals | `animals` | `animal_id` | `map.animals[].animal`, `zoo_animal.species` |
| Hunters | `hunters` | `hunter_id` | `GET /api/hunters` |
| MapAnimals | `map_animals` | `map_animal_id` | `map.animals[]` on the detail endpoint |
| HunterSkills | — | — | not seeded: documentation of what the numeric columns mean |
| ExpeditionRules | — | — | not seeded: copied into `App\Domain\Game\ExpeditionBalance` |
| Review | — | — | design-process artifact, no runtime meaning |

Master tables keep the Game Master's own string ids as primary keys
(`map_kenyan_savanna_001`, `animal_impala_001`, `hunter_susumu_019`) rather
than surrogate integers, so a row can be traced by eye from spreadsheet cell
to API payload without a lookup table.

### Why ExpeditionRules is not a table

The thirteen ExpeditionRules rows are *rules*, not data: the base success
rate and the biome affinity bonus appear inside the capture formula, not
beside it. They live in `App\Domain\Game\ExpeditionBalance` as documented
constants so an operator cannot retune capture odds with an environment
variable. Each constant names the rule id it came from.

## Values the vertical slice had to invent

Game Master v0.3 does not fix everything the formula needs. Where it is
silent, the slice chose a value, labelled it, and left it as an open
question rather than quietly promoting it to a decision.

| Value | Used for | Where | Status |
|---|---|---|---|
| `-8` capture % per point of `Map.difficulty` above 1 | capture chance | `ExpeditionBalance::DIFFICULTY_PENALTY_PER_POINT` | **not in v0.3** — slice constant |
| `-8` capture % per point of `Animal.capture_difficulty` above 1 | capture chance | `ExpeditionBalance::ANIMAL_DIFFICULTY_PENALTY_PER_POINT` | **not in v0.3** — slice constant |
| `[5, 95]` capture clamp | capture chance | `ExpeditionBalance::MIN/MAX_CAPTURE_PERCENT` | **not in v0.3** — slice constant |
| `1000` starting G | new player | `config/wildlive.php` | **not in v0.3** — slice constant |
| Zoo value = Σ `Animal.base_zoo_value` | map unlocking | `EloquentZooAnimalRepository::zooValue` | **interpretation** — `Rarity.base_multiplier` is deliberately not applied |

The last one deserves a note: `base_zoo_value` already scales with rarity in
the workbook (Impala 10, African Lion 45), so multiplying by
`Rarity.base_multiplier` as well would double-count. Whether the multiplier
is meant for zoo value, visitor income, or something else is a game-design
question, and stacking them would have been an economy decision the workbook
has not made.

## Rules the runtime enforces structurally

Some Game Master decisions are enforced by the shape of the data rather than
by a check that could be forgotten:

- **The Northern White Rhinoceros is not a normal spawn.** It has no
  `map_animals` row, and `EncounterTable` can only draw from that table, so
  no code path can produce one. Asserted in `GameMasterDataTest` and again
  across every released map in `GameCatalogTest`.
- **Hunters are contracted, not owned.** There is no `player_hunters` table
  and no ownership field in any API response. The contract exists only as
  `expeditions.hunter_id` + `contract_cost_g` on the one expedition.
- **`rare_find_bonus` never affects capture success.** It appears in
  `EncounterTable` and nowhere else; `CaptureResolver` does not read it.
  `CaptureResolverTest` asserts the chance is identical across the whole
  −20…+30 range.
- **Release pays nothing.** `DecideCapturedAnimal` has no balance movement
  in the release branch at all.
- **Canonical `expedition_minutes` is never shortened.** The development
  shortcut collapses `ends_at` onto `started_at` and records the real
  duration in `planned_duration_minutes`; the master value is untouched and
  is echoed in the API and shown on screen.

## Africa-first roster, as seeded

6 biomes · 5 rarities · 54 animals · 18 hunters · 15 maps · 72 spawn rows.

Of those, **9 maps** are `initial_africa` and playable; the 6
`future_expansion` maps are seeded for fidelity with the workbook and
filtered out of every player-facing query.

| Map | Biome | Difficulty | Canonical minutes | Cost | Unlocks at |
|---|---|---|---|---|---|
| Kenyan Savanna | Savanna | 1 | 10 | 50 G | always |
| Serengeti Plains | Savanna | 2 | 20 | 90 G | Zoo value 100 |
| Okavango Delta | Wetland | 2 | 40 | 180 G | Zoo value 500 |
| Namib Desert | Desert | 3 | 60 | 240 G | Zoo value 800 |
| Atlas Mountains | Mountain | 3 | 120 | 360 G | Zoo value 1500 |
| Kilimanjaro Slopes | Mountain | 3 | 240 | 600 G | Zoo value 2000 |
| Ethiopian Highlands | Mountain | 4 | 180 | 500 G | Zoo value 3000 |
| Congo Rainforest | Rainforest | 4 | 360 | 900 G | Zoo value 5000 |
| Virunga Highlands | Mountain | 4 | 300 | 800 G | Zoo value 6000 |
