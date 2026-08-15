#!/usr/bin/env python3
"""Add Swift source files to WildLive.xcodeproj/project.pbxproj.

The project file is hand-maintained with readable, predictable object ids
rather than Xcode's random 24-hex ones. That is worth keeping — the diffs
stay reviewable — but it means a new file needs four coordinated edits:
a PBXFileReference, a PBXBuildFile, a PBXGroup child, and an entry in the
target's PBXSourcesBuildPhase.

This script makes those four edits atomically so a half-added file (which
builds locally but fails in CI, or vice versa) is not possible.

Usage:

    python3 apps/ios/Scripts/add_sources_to_pbxproj.py \
        --target WildLive Domain/GameWorld.swift Presentation/HomeViewModel.swift

Paths are relative to the target's group directory (WildLive/,
WildLiveTests/, WildLiveUITests/). Files already present are skipped, so
the script is safe to re-run.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path
from typing import Dict, List, Tuple

PROJECT = Path(__file__).resolve().parent.parent / "WildLive.xcodeproj" / "project.pbxproj"

# Per-target: the group object id, the sources build-phase object id, and the
# id prefix new objects get. Prefixes are chosen to not collide with the
# existing A1/A2/A3/A4/A5 families.
TARGETS: Dict[str, Dict[str, str]] = {
    "WildLive": {
        "group": "A10000000000000000000004",
        "sources": "A10000000000000000000021",
        "prefix": "A6",
    },
    "WildLiveTests": {
        "group": "A10000000000000000000006",
        "sources": "A40000000000000000000021",
        "prefix": "A7",
    },
    "WildLiveUITests": {
        "group": "A10000000000000000000005",
        "sources": "A10000000000000000000071",
        "prefix": "A8",
    },
}


def _next_index(text: str, prefix: str) -> int:
    """Highest index already used by this prefix family, plus one."""
    used = [int(m, 16) for m in re.findall(rf"{prefix}0000000000000000FF([0-9A-F]{{2}})", text)]
    return (max(used) + 1) if used else 1


def add_files(target: str, rel_paths: List[str]) -> Tuple[int, int]:
    if target not in TARGETS:
        raise SystemExit(f"unknown target {target!r}; expected one of {sorted(TARGETS)}")

    cfg = TARGETS[target]
    text = PROJECT.read_text(encoding="utf-8")
    index = _next_index(text, cfg["prefix"])

    added = 0
    skipped = 0

    for rel in rel_paths:
        name = Path(rel).name

        if f"path = {rel};" in text:
            print(f"  skip (already in project): {rel}")
            skipped += 1
            continue

        file_ref = f"{cfg['prefix']}0000000000000000FF{index:02X}"
        build_ref = f"{cfg['prefix']}0000000000000000BB{index:02X}"
        index += 1

        # 1. PBXFileReference
        text = text.replace(
            "/* End PBXFileReference section */",
            f"\t\t{file_ref} /* {name} */ = {{isa = PBXFileReference; "
            f"lastKnownFileType = sourcecode.swift; path = {rel}; sourceTree = \"<group>\"; }};\n"
            "/* End PBXFileReference section */",
            1,
        )

        # 2. PBXBuildFile
        text = text.replace(
            "/* End PBXBuildFile section */",
            f"\t\t{build_ref} /* {name} in Sources */ = {{isa = PBXBuildFile; "
            f"fileRef = {file_ref} /* {name} */; }};\n"
            "/* End PBXBuildFile section */",
            1,
        )

        # 3. Group membership.
        #
        # Anchor on the DEFINITION (`<id> /* Name */ = {`), not the first
        # mention: every group and build phase is also listed by id inside
        # its parent earlier in the file, and anchoring there silently
        # inserts into whatever list happens to come next.
        group_start = re.search(rf"{cfg['group']} /\* [^*]*\*/ = \{{", text).start()
        children_start = text.index("children = (", group_start)
        text = (
            text[: children_start + len("children = (")]
            + f"\n\t\t\t\t{file_ref} /* {name} */,"
            + text[children_start + len("children = (") :]
        )

        # 4. Sources build phase (same anchoring rule as above).
        phase_start = re.search(rf"{cfg['sources']} /\* Sources \*/ = \{{", text).start()
        files_start = text.index("files = (", phase_start)
        text = (
            text[: files_start + len("files = (")]
            + f"\n\t\t\t\t{build_ref} /* {name} in Sources */,"
            + text[files_start + len("files = (") :]
        )

        print(f"  added: {rel}  ({file_ref})")
        added += 1

    PROJECT.write_text(text, encoding="utf-8")
    return added, skipped


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--target", required=True, choices=sorted(TARGETS))
    parser.add_argument("paths", nargs="+", help="paths relative to the target's group directory")
    args = parser.parse_args()

    added, skipped = add_files(args.target, args.paths)
    print(f"{args.target}: {added} added, {skipped} skipped")
    return 0


if __name__ == "__main__":
    sys.exit(main())
