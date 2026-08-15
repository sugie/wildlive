# WildLive Game Master

Human-review workbooks for the WildLive master data — Maps, Animals, Hunters, and the tables that support them. Each workbook is a **draft** produced from `docs/adr/0002-game-system-foundation.md` and the game design notes in `docs/GAME_DESIGN.md`. Nothing here is a final balance decision or a DB / API specification.

Three versions live here side-by-side. **v0.1 and v0.2 stay as historical baselines; v0.3 is the current review target.**

## Files

```
docs/game-design/
├── README.md                                        (this file)
├── WildLive-Game-Master-Draft-v0.1.xlsx             (v0.1 — historical baseline, do not modify)
├── build_master_v0_1.py                             (v0.1 builder — kept alongside its xlsx)
├── WildLive-Game-Master-Draft-v0.2.xlsx             (v0.2 — historical baseline, do not modify)
├── build_master_v0_2.py                             (v0.2 builder — kept alongside its xlsx)
├── WildLive-Game-Master-Draft-v0.3.xlsx             (v0.3 — current review target)
└── build_master_v0_3.py                             (v0.3 builder)
```

Each builder is the source of truth for its version. When a human edits the xlsx, the edit lives only in the xlsx until an AI (on human instruction) mirrors it back into the Python source.

### Reproducibility

Regenerating an xlsx from its builder produces **byte-identical output** across runs and across machines (same Python + openpyxl + source). The builders normalise the two run-varying pieces openpyxl adds by default:

- `docProps/core.xml` — `dcterms:created` / `dcterms:modified` are rewritten to a fixed canonical timestamp (`2000-01-01T00:00:00Z`).
- ZIP entry `date_time` — every part is re-packed with the same canonical timestamp, in alphabetically-sorted entry order.

Cell values, formulas, IDs, FK relations — the actual game data — are not touched by that normalisation. Only the OOXML packaging metadata is canonicalised.

`sha256sum` of a freshly regenerated file will match `sha256sum` of the committed file on the same commit. If it does not, either (a) the builder source was edited, (b) the xlsx was edited in Excel and not mirrored back, or (c) the environment (openpyxl version) drifted.

The v0.1 / v0.2 / v0.3 workbooks that were originally committed at [`748ff99`, `59d6d66`, `3e35974`] used openpyxl's default (non-deterministic) save path and therefore had wall-clock timestamps baked in. The subsequent maintenance commit ("`chore(game): make master workbook generation byte-deterministic`") re-emitted all three from the same design source under the new deterministic save — game data unchanged, only packaging metadata normalised. The pre-normalisation bytes are still recoverable from git history for anyone auditing the paper trail.

## Regenerate

```bash
# v0.3 (current target)
python3 docs/game-design/build_master_v0_3.py

# v0.2 (historical — regenerate only if the file was lost)
python3 docs/game-design/build_master_v0_2.py

# v0.1 (historical — regenerate only if the file was lost)
python3 docs/game-design/build_master_v0_1.py
```

Prerequisite: `pip install openpyxl` (tested against openpyxl 3.1.5). All scripts run validation before writing and refuse to write if anything is broken.

---

## v0.3 — Current

Human + ChatGPT reviewed v0.2 and asked for a focused set of refinements to the Africa-first fauna, the Hunter roster, and the Map progression column. v0.3 applies them all. **All v0.2 design pivots (1..12) still hold** — v0.3 layers on top, it does not overturn them.

### Design refinements (v0.3)

| # | Change | v0.3 rule |
|---|---|---|
| 1 | **Ethiopian Highlands endemic fauna** | Added `Gelada` (`animal_gelada_051`) and `Walia Ibex` (`animal_walia_ibex_052`) — both real Ethiopian endemics — so the Map has a distinct highland-primate + cliff-dwelling-ungulate identity, not just "another montane forest with an Ethiopian Wolf". |
| 2 | **Virunga Highlands endemic fauna** | Added `Golden Monkey` (`animal_golden_monkey_053`) — real Virungas endemic — so the Map is not a Mountain-Gorilla-only sink. |
| 3 | **Correct East African baboon** | Added `Olive Baboon` (`animal_olive_baboon_054`) — the actual East African baboon. v0.2 had used `Chacma Baboon` (a Southern African species) as a proxy on 4 East African Maps with `needs_review=1`. v0.3 replaces those 4 proxy rows with Olive Baboon and keeps Chacma only on Okavango Delta (real Southern African range). Net result: **`MapAnimals.needs_review = 0` across all 72 rows.** |
| 4 | **New desert-specialist Hunter** | Added `hunter_susumu_019` (Susumu / 進, Gold rank, `preferred_biome_id = biome_desert`, `capture_bonus = +15`). Closes the v0.2 gap where no Hunter had `preferred_biome_id = biome_desert` despite two desert Maps existing. |
| 5 | **New montane-speed Hunter** | Added `hunter_yuto_020` (Yu-to / 雄斗, Silver rank, `preferred_biome_id = biome_mountain`, `speed_bonus = +20`). Reinforces the Ethiopian / Virunga / Kilimanjaro / Atlas Highlands cluster. |
| 6 | **Reduced "any"-biome Hunter count** | Removed `hunter_yuki_nakamura_008` and `hunter_chen_wei_014` (both had `preferred_biome_id = any` with unremarkable stats). Total Hunters remain 18. "any" count drops from 6 → 4 so preferred-biome specialisation is a meaningful roster axis, not a majority. |
| 7 | **`Maps.map_role` column** | New column: `starter` / `general` / `specialist` / `long_expedition`. Documents each Map's intended role in the progression curve without changing any unlock rule. Kenyan Savanna = `starter`; Congo Rainforest = `long_expedition`; the two v0.3-added Highlands = `specialist`; the rest = `general`. |
| 8 | **`Hunters.name_ja` column** | New column with the Japanese display name for each Hunter (kanji for the two v0.3 Hunters, katakana for the rest). Mirrors the bilingual policy already used on Maps and Animals. |
| 9 | **Legendary Hunter descriptions cleaned** | Removed "Only one player may hold her contract at a time" language from `hunter_aiko_tanabe_009` and `hunter_malik_osei_012`. Reason: MMO-scarcity contract semantics are a full separate design decision (server-authoritative arbitration, queue behaviour, availability windows) and were not in scope for the v0.3 refinement. Flagged as `review_031`. |
| 10 | **`rare_find_bonus` semantics tightened** | `HunterSkills` description clarifies: this bias operates on encounter probability, **independent of** capture success. Prevents future readers from stacking it into a capture-success formula by mistake. |

### Sheet counts (v0.3)

| Sheet | Purpose | Rows | Δ vs v0.2 |
|---|---|---|---|
| **Biomes** | Controlled vocabulary for biome tags. | 6 | — |
| **Rarities** | 5 in-game rarity tiers, Common → Legendary. | 5 | — |
| **Maps** | Regions the player can dispatch a Hunter to. Now with `map_role`. | 15 (9 initial_africa + 6 future_expansion) | +`map_role` column |
| **Animals** | Real wild species. | 54 (36 initial_africa + 17 future_region + 1 special_event) | +4 (Gelada, Walia Ibex, Golden Monkey, Olive Baboon) |
| **Hunters** | Contract-able Hunters. Now with `name_ja`. | 18 | +Susumu, +Yu-to, −Yuki Nakamura, −Chen Wei (net 0) |
| **MapAnimals** | Spawn table. **`needs_review = 0` everywhere.** | 72 | +4 (new endemics + Olive Baboon replacing 4 Chacma proxies on East African Maps; net +4 due to added rows on the two Highlands Maps) |
| **HunterSkills** | Data dictionary for the numeric columns on the Hunters sheet. | 4 | Description of `rare_find_bonus` tightened |
| **ExpeditionRules** | Numeric knobs. | 13 | — |
| **Review** | 29 v0.2 items with updated decisions applied + 7 new v0.3 items. | 36 | +7 v0.3 items |

### New Review items (v0.3)

| ID | Topic | Status |
|---|---|---|
| `review_030` | Expedition resolution order when a player has multiple expired-but-unresolved expeditions (FIFO? player choice? lazy-on-touch?) | open |
| `review_031` | MMO-scarce Hunter contract semantics — the language removed from Aiko / Dr. Osei needs a proper server-authoritative design | open |
| `review_032` | Ethiopian Highlands fauna additions — human confirmation Gelada / Walia Ibex / Olive Baboon are the right shortlist for v0.3 | draft-applied |
| `review_033` | Virunga Highlands specialist — Golden Monkey addition | draft-applied |
| `review_034` | Any-biome Hunter cap — should we hold "any" at ≤4, or drive it further down? | open |
| `review_035` | Desert Hunter placement — is Susumu enough, or do we need a second Africa-desert profile before shipping? | open |
| `review_036` | `montane_forest` sub-biome — currently rolled into `mountain`; should Virunga / Ethiopian Highlands get their own biome id? | open |

### Reference: v0.3 initial African Map roster (with `map_role`)

1. Kenyan Savanna — `starter`, `unlock_rule = always`
2. Serengeti Plains — `general`, `zoo_value ≥ 100`
3. Okavango Delta — `general`, `zoo_value ≥ 500`
4. Namib Desert — `general`, `zoo_value ≥ 800`
5. Kilimanjaro Slopes — `general`, `zoo_value ≥ 2000`
6. Atlas Mountains — `general`, `zoo_value ≥ 1500`
7. Ethiopian Highlands — `specialist`, `zoo_value ≥ 3000`
8. Virunga Highlands — `specialist`, `zoo_value ≥ 6000`
9. Congo Rainforest — `long_expedition`, `zoo_value ≥ 5000`

### Non-goals (v0.3)

- Laravel code changes
- PostgreSQL migrations / seeders
- iOS code changes
- API endpoints
- RevenueCat integration
- Server-authoritative MMO-scarce contract mechanic (`review_031` — DEFERRED)
- Sub-biome vocabulary (`review_036` — DEFERRED)
- G economy final numbers (still DEFERRED, was `review_010` / `review_023`)
- Zoo Value final formula (still DEFERRED, was `review_011` / `review_024`)

---

## v0.2 — Historical baseline

**Game data kept unchanged for the paper trail.** v0.2 was the first Africa-first draft (see design pivots below). v0.3 refines fauna and Hunter roster on top; the design pivots recorded here still hold. (The packaging metadata was normalised once by the deterministic-build maintenance commit — see *Reproducibility* — but no cell values, IDs, or FK links moved.)

Human + ChatGPT reviewed v0.1 and asked for the following changes. v0.2 applied them all.

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
Human review of v0.3  (edit v0.3 xlsx, fill Review.decision)
    ↓
AI mirrors decisions back into build_master_v0_3.py → v0.4
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

**Game data kept unchanged for the paper trail.** The v0.1 file and its builder are still in this directory; do not modify the design. (The packaging metadata was normalised once by the deterministic-build maintenance commit — see the *Reproducibility* section above — but no cell values, IDs, or FK links moved.) If a decision recorded in v0.2's Review sheet ever needs to be re-argued, v0.1 is the record of what the argument was against.

Original v0.1 scope: 12 maps (7 African + 5 global) / 50 animals / 18 hunters. It placed several out-of-range species on convenient Maps as "game abstractions" (Kakapo on Borneo, Saola on Borneo, Mountain Gorilla on Kilimanjaro, etc.). Human review rejected that approach — v0.2 encodes the fix.
