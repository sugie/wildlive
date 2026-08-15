#!/usr/bin/env python3
"""Export the canonical Game Master v0.3 tables to runtime JSON.

WildLive has exactly ONE source-to-runtime path for game master data:

    docs/game-design/build_master_v0_3.py     (canonical Python source)
        │
        ├─→ WildLive-Game-Master-Draft-v0.3.xlsx   (human review artifact)
        │
        └─→ database/master/game-master-v0.3.json  (runtime artifact, this script)
                │
                └─→ Database\\Seeders\\GameMasterSeeder → PostgreSQL → API → iOS

The runtime application never opens the .xlsx. This script imports the same
Python module the workbook builder uses, so the JSON cannot drift from the
workbook without the shared source changing first.

Only the sheets the runtime needs are exported. `Review` (open design
questions) is deliberately excluded — it is a design-process artifact with
no runtime meaning.

Usage:

    python3 docs/game-design/export_master_json.py            # write
    python3 docs/game-design/export_master_json.py --check    # verify only

`--check` exits non-zero when the committed JSON differs from what the
current Python source would produce.
"""

from __future__ import annotations

import argparse
import importlib.util
import json
import sys
from pathlib import Path
from typing import Any, Dict, List

MASTER_VERSION = "v0.3"
HERE = Path(__file__).resolve().parent
REPO_ROOT = HERE.parent.parent
SOURCE_MODULE = HERE / "build_master_v0_3.py"
OUTPUT_PATH = REPO_ROOT / "database" / "master" / f"game-master-{MASTER_VERSION}.json"


def _load_source_module():
    """Import build_master_v0_3.py without executing its main()."""
    spec = importlib.util.spec_from_file_location("wildlive_master_v0_3", SOURCE_MODULE)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load {SOURCE_MODULE}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _pick(row: Dict[str, Any], keys: List[str]) -> Dict[str, Any]:
    return {k: row.get(k, "") for k in keys}


def build_payload() -> Dict[str, Any]:
    src = _load_source_module()

    ok, problems = src.validate()
    if not ok:
        hard = [p for p in problems if not p.startswith("NOTICE")]
        raise SystemExit(
            "refusing to export: canonical source failed validation:\n  "
            + "\n  ".join(hard)
        )

    biomes = [
        _pick(b, ["biome_id", "name_en", "name_ja", "description_en", "description_ja"])
        for b in src.BIOMES
    ]

    rarities = [
        _pick(r, ["rarity_id", "name_en", "name_ja", "sort_order", "base_multiplier", "description"])
        for r in src.RARITIES
    ]

    maps = [
        _pick(m, [
            "map_id", "name_en", "name_ja", "region", "biome_id",
            "availability_phase", "map_role", "unlock_rule", "unlock_value",
            "recommended_hunter_rank", "minimum_hunter_rank_gate",
            "difficulty", "expedition_minutes", "base_cost_g", "risk_level",
            "description_en", "description_ja",
        ])
        for m in src.MAPS
    ]

    animals = [
        _pick(a, [
            "animal_id", "name_en", "name_ja", "category", "rarity_id",
            "availability_phase", "placement_note", "base_zoo_value",
            "capture_difficulty", "growth_rate", "visitor_appeal",
            "habitat_biome_id", "size", "active_time",
            "description_en", "description_ja",
        ])
        for a in src.ANIMALS
    ]

    hunters = [
        _pick(h, [
            "hunter_id", "name", "name_ja", "rank", "level", "specialty",
            "preferred_biome_id", "capture_bonus", "rare_find_bonus",
            "speed_bonus", "contract_cost_g", "personality", "description",
        ])
        for h in src.HUNTERS
    ]

    map_animals = []
    for i, ma in enumerate(src.MAP_ANIMALS_RAW, start=1):
        row = {"map_animal_id": f"map_animal_{i:03d}"}
        row.update(_pick(ma, ["map_id", "animal_id", "spawn_weight", "capture_modifier", "notes"]))
        row["needs_review"] = bool(ma.get("needs_review", False))
        map_animals.append(row)

    hunter_skills = [
        _pick(s, ["skill_id", "name_en", "name_ja", "effect_type", "effect_min", "effect_max", "description"])
        for s in src.HUNTER_SKILLS
    ]

    expedition_rules = [
        _pick(r, ["rule_id", "rule_name", "value", "unit", "description"])
        for r in src.EXPEDITION_RULES
    ]

    return {
        "master_version": MASTER_VERSION,
        "generated_from": "docs/game-design/build_master_v0_3.py",
        "generator": "docs/game-design/export_master_json.py",
        "note": (
            "Runtime master data for WildLive. Generated — do not hand-edit. "
            "Change docs/game-design/build_master_v0_3.py and re-run the generator."
        ),
        "biomes": biomes,
        "rarities": rarities,
        "maps": maps,
        "animals": animals,
        "hunters": hunters,
        "map_animals": map_animals,
        "hunter_skills": hunter_skills,
        "expedition_rules": expedition_rules,
    }


def render(payload: Dict[str, Any]) -> str:
    return json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=False) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true",
                        help="verify the committed JSON matches the canonical source; do not write")
    args = parser.parse_args()

    rendered = render(build_payload())

    if args.check:
        if not OUTPUT_PATH.exists():
            print(f"[!] {OUTPUT_PATH} does not exist — run without --check to generate it.")
            return 1
        current = OUTPUT_PATH.read_text(encoding="utf-8")
        if current != rendered:
            print(f"[!] {OUTPUT_PATH.relative_to(REPO_ROOT)} is out of date with "
                  f"{SOURCE_MODULE.relative_to(REPO_ROOT)}.")
            print("    Re-run: python3 docs/game-design/export_master_json.py")
            return 1
        print(f"ok — {OUTPUT_PATH.relative_to(REPO_ROOT)} matches the canonical source.")
        return 0

    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_PATH.write_text(rendered, encoding="utf-8")

    payload = json.loads(rendered)
    print(f"wrote {OUTPUT_PATH.relative_to(REPO_ROOT)}")
    for key in ("biomes", "rarities", "maps", "animals", "hunters",
                "map_animals", "hunter_skills", "expedition_rules"):
        print(f"    {key:18} {len(payload[key])}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
