# WildLive Game Master Draft v0.1

Human-review workbook for the initial WildLive master data — Maps, Animals, Hunters, and the tables that support them. Everything here is a **draft** produced from `docs/adr/0002-game-system-foundation.md` and the game design notes in `docs/GAME_DESIGN.md`. Nothing here is a final balance decision.

## Files

- **`WildLive-Game-Master-Draft-v0.1.xlsx`** — the workbook a human reviews and edits.
- **`build_master_v0_1.py`** — the source-of-truth script that generates the workbook. All row data is authored in Python lists inside the script; the xlsx is a rendered view. When a human edits the xlsx, that edit lives only in the xlsx until an AI (on human instruction) mirrors it back into the Python source.
- **`README.md`** — this file.

## Regenerate

```bash
python3 docs/game-design/build_master_v0_1.py
```

Prerequisite: `pip install openpyxl` (already installed if you followed the initial session). The script also runs validation (ID uniqueness, foreign keys, numeric ranges, required fields) and refuses to write the xlsx if anything is broken.

## Sheets

| Sheet | Purpose | Rows in v0.1 |
|---|---|---|
| **Rarities** | The 5 rarity tiers (Common → Legendary) + their Zoo Value multipliers. | 5 |
| **Maps** | Regions the player can dispatch a Hunter to. Difficulty, unlock rank, expedition minutes, dispatch cost. | 12 |
| **Animals** | Real wild species available for capture. Rarity link, capture difficulty, base Zoo Value, visitor appeal. | 50 |
| **Hunters** | Contract-able Hunters. Rank, specialty, three per-Hunter skill bonuses, hire cost. | 18 |
| **MapAnimals** | Which Animals appear on which Maps, with spawn weights and per-pair capture modifiers. | 76 |
| **HunterSkills** | Data dictionary for the numeric skill columns on Hunters (`capture_bonus`, `rare_find_bonus`, `speed_bonus`, `biome_affinity`). | 4 |
| **ExpeditionRules** | Numeric knobs for the dispatch → wait → resolve flow (base success rate, minimum/maximum minutes, penalties, biome bonuses). | 10 |
| **Review** | Points the human is asked to decide, right inside Excel. Empty `decision` column per row. | 17 |

Every sheet has a bold header row, a freeze pane at row 2, an AutoFilter over the header row, and hand-tuned column widths.

## ID naming rules

| Kind | Pattern | Example |
|---|---|---|
| Rarity | `rarity_<name>` | `rarity_legendary` |
| Map | `map_<slug>_<###>` | `map_kenyan_savanna_001` |
| Animal | `animal_<slug>_<###>` | `animal_snow_leopard_036` |
| Hunter | `hunter_<given>_<family>_<###>` | `hunter_aiko_fujimori_017` |
| MapAnimal | `map_animal_<###>` | `map_animal_001` |
| Hunter Skill | `skill_<name>` | `skill_capture_bonus` |
| Expedition Rule | `expedition_rule_<name>` | `expedition_rule_base_success_rate` |
| Review item | `review_<###>` | `review_004` |

IDs are case-sensitive, ASCII, snake_case. Once a row lands in the xlsx it's expensive to rename its ID — later Laravel migrations, seeders, and iOS Preview data will reference these strings.

## What "Draft" means here

- **All numbers are proposals**, chosen to make the shape of the game legible. Base success rate 60%, Legendary multiplier ×12, Kenyan Savanna dispatch cost 50G — every one of these is a placeholder that the human explicitly reviews on the **Review** sheet.
- **No final Zoo Value formula.** ADR-0002 §12 requires diminishing returns on repeated identical Animals; that formula isn't in this draft.
- **No final G economy.** ADR-0002 §13 leaves the Visitor → G formula open; this draft only records `visitor_appeal` per Animal so the balance conversation can happen.
- **No final expedition-outcome model.** ADR-0002 §10 fixes only `capture success` / `no capture`. Whether partial success, injury, or cancellation exist is `Review.review_013`.
- **Species placements are pragmatic**, not strictly biogeographic. Where a Legendary species has no matching Map (e.g. Kakapo is a New Zealand endemic; Vaquita is coastal), the workbook flags the placement as a "game abstraction" in the `notes` column and raises `Review.review_004` for the human decision.

## Inherited from ADR-0002 (unchanged)

- Real wildlife only. No fantasy.
- Hunter terminology (not Explorer).
- Currency is `G`.
- Guild-owned shared Hunter pool. Basic Hunters always available.
- Coarse expedition outcome = `capture success` or `no capture`.
- No power inflation — new content is rarer, not stronger.
- African-inspired working assumption for regions (7 of 12 maps are African).

## Newly proposed in this draft (marked for human review)

Everything below appears somewhere in the **Review** sheet:

- **12 Maps / 50 Animals / 18 Hunters** as the initial size (`review_001`).
- **5 rarity tiers, no Mythic** (`review_002`).
- **Africa-heavy but not Africa-only** region mix (`review_003`).
- **Placing several Legendary species outside their real range** so v0.1 has a home for them (`review_004`).
- **6-step Hunter rank system** with per-Hunter level 1..10 (`review_005`).
- **Hunter skills as columns on the Hunters sheet**, not a separate join sheet — with a `HunterSkills` data-dictionary sheet documenting each column (`review_007`).
- **Map unlock model** = minimum Hunter rank (Hunter-driven progression, not Player-level or story-based) (`review_008`).
- **Dispatch cost gradient** 50G → 2400G across the 12 Maps (`review_010`).
- **Legendary base Zoo Value ≈ 20-26× a Common** (`review_011`).
- **No G penalty on capture failure** beyond the sunk dispatch cost (`review_013`).
- **No G refund on Release** (`review_014`).
- **One-off contract cost model** for Hunters — no upkeep (`review_015`).
- **Including the Northern White Rhinoceros** despite its functionally-extinct real-world status (`review_016`).

Where an entry on Maps/Animals/Hunters mentions a specific numeric value or a specific placement, it corresponds to one of the Review points above.

## Workflow — where this fits

```text
Human review of v0.1  (edit xlsx directly, fill Review.decision)
    ↓
AI mirrors decisions back into build_master_v0_1.py → v0.2
    ↓
DB schema design (from v0.2, alongside docs/ER_MODEL.md)
    ↓
Laravel migrations + seeders (v0.2 becomes seed data)
    ↓
API endpoints (Guild / Map / Expedition)
    ↓
iOS client wires HomeView / GuildView / RegionPickerView to real data
```

Nothing between the workbook and Laravel is authorised by this task; each next step is its own future task, and each needs its own human GO.

## Non-goals for this task

- Laravel code changes
- PostgreSQL migrations / seeders
- iOS code changes
- API endpoints
- RevenueCat integration
- Production connections
- X Development Live media

## Layer boundary — where the workbook meets the rest of the repo

- `docs/adr/0002-game-system-foundation.md` — **binding design decisions**. If this workbook contradicts ADR-0002, ADR-0002 wins.
- `docs/GAME_DESIGN.md`, `docs/DOMAIN_MODEL.md` — narrative + working notes.
- `docs/ER_MODEL.md` — the minimal ER model this workbook will eventually seed.
- `docs/DECISIONS_PENDING.md` — the open-questions ledger. Every Review item that survives review should be reflected there.

## Bilingual policy

Player-visible strings have separate `name_ja` + `name_en` columns (and `description_ja` + `description_en` where present). Non-player-visible fields (IDs, category tags, etc.) are English-only. Matches the bilingual policy of `docs/reports/`.
