# WildLive Game Master

Human-review workbooks for the WildLive master data — Maps, Animals, Hunters, and the tables that support them. Each workbook is a **draft** produced from `docs/adr/0002-game-system-foundation.md` and the game design notes in `docs/GAME_DESIGN.md`. Nothing here is a final balance decision or a DB / API specification.

Two versions live here side-by-side. **v0.1 stays as a historical baseline; v0.2 is the current review target.**

## Files

```
docs/game-design/
├── README.md                                        (this file)
├── WildLive-Game-Master-Draft-v0.1.xlsx             (v0.1 — historical baseline, do not modify)
├── build_master_v0_1.py                             (v0.1 builder — kept alongside its xlsx)
├── WildLive-Game-Master-Draft-v0.2.xlsx             (v0.2 — current review target)
└── build_master_v0_2.py                             (v0.2 builder)
```

Each builder is the source of truth for its version. When a human edits the xlsx, the edit lives only in the xlsx until an AI (on human instruction) mirrors it back into the Python source. Regenerating the xlsx from the builder always reproduces the same bytes given the same inputs.

## Regenerate

```bash
# v0.2 (current target)
python3 docs/game-design/build_master_v0_2.py

# v0.1 (historical — regenerate only if the file was lost)
python3 docs/game-design/build_master_v0_1.py
```

Prerequisite: `pip install openpyxl`. Both scripts run validation before writing and refuse to write if anything is broken.

---

## v0.2 — Current

Human + ChatGPT reviewed v0.1 and asked for the following changes. v0.2 applies them all.

### Design pivots

| # | Change | v0.2 rule |
|---|---|---|
| 1 | **Africa-first** | Initial playable roster is Africa-only. Non-African Maps stay in the workbook tagged `availability_phase = future_expansion`. |
| 2 | **Real habitat** | Every MapAnimals row respects the species' real biogeographic range. Species with no v0.2 home are tagged `availability_phase = future_region` and have **no** MapAnimals row until the required expansion Map ships. |
| 3 | **Map access = progression driver** | "New Animals require new Regions." Region unlock replaces v0.1's per-Hunter-rank gate. |
| 4 | **Northern White Rhinoceros** | Removed from normal spawn. Tagged `availability_phase = special_event`. No MapAnimals row. Reserved for a future Conservation / Special Event surface. |
| 5 | **Hunter is not owned** | Hunter is contracted from the Guild pool per expedition. `hire_cost_g` renamed to `contract_cost_g` for clarity. |
| 6 | **Map unlock ⊥ Hunter rank** | New columns `unlock_rule` / `unlock_value` / `recommended_hunter_rank`. `minimum_hunter_rank_gate = 0` everywhere — access permitted, risk high. |
| 7 | **Biomes master** | New `Biomes` sheet. `Maps.biome_id`, `Animals.habitat_biome_id`, `Hunters.preferred_biome_id` all reference it under FK validation. |
| 8 | **Rarity = in-game rarity** | Explicitly not IUCN status. Real-world conservation status is left as a future `conservation_status` column (see `Review.review_020`). |
| 9 | **Release reward = 0 G** | Deliberate. Non-G rewards left as `Review.review_025`. |
| 10 | **No G penalty on capture failure** | Only the sunk dispatch + contract cost. |
| 11 | **Two new Africa Maps** | `Ethiopian Highlands` (home to Ethiopian Wolf) and `Virunga Highlands` (home to Mountain Gorilla) added so those species can live in their real ranges. |
| 12 | **Fictional Hunter names** | 4 v0.1 names that mapped too closely to specific real people were rewritten (see `Review.review_027`). |

### Sheets (v0.2)

| Sheet | Purpose | Rows |
|---|---|---|
| **Biomes** *(new)* | Controlled vocabulary for biome tags. FK target for Maps, Animals, Hunters. | 6 |
| **Rarities** | 5 in-game rarity tiers, Common → Legendary. Multipliers still draft. | 5 |
| **Maps** | Regions the player can dispatch a Hunter to. `availability_phase`, `unlock_rule`, `unlock_value`, `recommended_hunter_rank`, `biome_id`. | 15 (9 initial_africa + 6 future_expansion) |
| **Animals** | Real wild species. `availability_phase`, `placement_note`, `habitat_biome_id`. | 50 (32 initial_africa + 17 future_region + 1 special_event) |
| **Hunters** | Contract-able Hunters. `contract_cost_g` (renamed), `preferred_biome_id` FK. | 18 |
| **MapAnimals** | Spawn table. `needs_review` column flags proxy pairings. | 68 |
| **HunterSkills** | Data dictionary for the numeric columns on the Hunters sheet. | 4 |
| **ExpeditionRules** | Numeric knobs. Failure penalty / release reward / hunter rank gate all filled in per v0.2 decisions. | 13 |
| **Review** | 17 v0.1 items with decisions applied + 12 new v0.2 items. Empty `decision` column for open questions. | 29 |

### `availability_phase` — decoded

| Value | Where it appears | Meaning |
|---|---|---|
| `initial_africa` | Maps, Animals | Ships in the v0.2 first-Phase playable set. |
| `future_expansion` | Maps only | Map exists in data but is locked until the corresponding Region expansion ships. |
| `future_region` | Animals only | Species is real but has no v0.2 Map home yet. Waits for the required expansion Map. |
| `special_event` | Animals only | Removed from normal spawn. Reserved for a future event surface. |

### Map unlock (v0.2 draft)

`unlock_rule` can be:

- `always` — starter Map (`Kenyan Savanna` only, `unlock_value = 0`).
- `zoo_value` — unlock when the Player's Zoo Value crosses `unlock_value`.
- `future_expansion` — Map is not accessible in v0.2 at all.

The draft `zoo_value` thresholds are placeholders — see `Review.review_022` for the human decision on the unlock mechanic itself.

### Reference: v0.2 initial African Map roster

1. Kenyan Savanna (starter, `unlock_rule=always`)
2. Serengeti Plains (`zoo_value ≥ 100`)
3. Okavango Delta (`zoo_value ≥ 500`)
4. Namib Desert (`zoo_value ≥ 800`)
5. Atlas Mountains (`zoo_value ≥ 1500`)
6. Ethiopian Highlands *(new)* (`zoo_value ≥ 3000`)
7. Virunga Highlands *(new)* (`zoo_value ≥ 6000`)
8. Kilimanjaro Slopes (`zoo_value ≥ 2000`)
9. Congo Rainforest (`zoo_value ≥ 5000`)

### Rarity clarification (v0.2)

**Rarity in this workbook is the in-game encounter/capture rarity. It is not IUCN conservation status.**

A future `conservation_status` column (LC / NT / VU / EN / CR / EW / EX) is proposed in `Review.review_020` for the real-world axis. Two axes are deliberately separated to prevent the game's balance conversation and the conservation-awareness conversation from contaminating each other.

### Non-goals (v0.2)

- Laravel code changes
- PostgreSQL migrations / seeders
- iOS code changes
- API endpoints
- RevenueCat integration
- Production connections
- X Development Live media
- G economy final numbers (`review_010`, `review_023` — DEFERRED)
- Zoo Value final formula (`review_011`, `review_024` — DEFERRED)

## Bilingual policy

Player-visible strings have separate `name_ja` + `name_en` columns (and `description_ja` + `description_en` where present). IDs and category tags are English-only. Matches the bilingual policy of `docs/reports/`.

## ID naming rules

| Kind | Pattern | Example |
|---|---|---|
| Biome | `biome_<name>` | `biome_rainforest` |
| Rarity | `rarity_<name>` | `rarity_legendary` |
| Map | `map_<slug>_<###>` | `map_virunga_highlands_007` |
| Animal | `animal_<slug>_<###>` | `animal_okapi_049` |
| Hunter | `hunter_<given>_<family>_<###>` | `hunter_nima_kirat_007` |
| MapAnimal | `map_animal_<###>` | `map_animal_001` |
| Hunter Skill | `skill_<name>` | `skill_capture_bonus` |
| Expedition Rule | `expedition_rule_<name>` | `expedition_rule_base_success_rate` |
| Review item | `review_<###>` | `review_022` |

IDs are case-sensitive, ASCII, snake_case, and expensive to rename once downstream code depends on them. Any renaming decision goes through Review.

## Layer boundary — where the workbook meets the rest of the repo

- `docs/adr/0002-game-system-foundation.md` — **binding design decisions**. If this workbook contradicts ADR-0002, ADR-0002 wins.
- `docs/GAME_DESIGN.md`, `docs/DOMAIN_MODEL.md` — narrative + working notes.
- `docs/ER_MODEL.md` — the minimal ER model this workbook will eventually seed.
- `docs/DECISIONS_PENDING.md` — the open-questions ledger. Every Review item that survives review should be reflected there.

## Workflow — where this fits

```text
Human review of v0.2  (edit v0.2 xlsx, fill Review.decision)
    ↓
AI mirrors decisions back into build_master_v0_2.py → v0.3
    ↓
Once decisions are stable enough:
    → DB schema design (alongside docs/ER_MODEL.md)
    → Laravel migrations + seeders (workbook = seed data)
    → API endpoints (Guild / Map / Expedition)
    → iOS client wires real screens to real data
```

Nothing between the workbook and Laravel is authorised by this task; each next step is its own future task and needs its own human GO.

---

## v0.1 — Historical baseline

**Kept unchanged for the paper trail.** The v0.1 file and its builder are still in this directory; do not modify them. If a decision recorded in v0.2's Review sheet ever needs to be re-argued, v0.1 is the record of what the argument was against.

Original v0.1 scope: 12 maps (7 African + 5 global) / 50 animals / 18 hunters. It placed several out-of-range species on convenient Maps as "game abstractions" (Kakapo on Borneo, Saola on Borneo, Mountain Gorilla on Kilimanjaro, etc.). Human review rejected that approach — v0.2 encodes the fix.
