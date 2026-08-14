#!/usr/bin/env python3
"""WildLive Public AI Development Archive — session-record validator.

Stdlib-only linter for a task directory under `docs/ai-sessions/`. Verifies:

  1. `metadata.json` parses and matches the fields declared in
     `docs/ai-sessions/schema.json` (a minimal in-code schema check —
     no third-party JSON Schema library is used or required).
  2. `prompt.en.md` and `transcript.en.md` exist at the paths declared
     in the manifest.
  3. No file in the task directory contains obvious credential
     patterns.
  4. No file uses the banned phrase "verbatim original prompt" — that
     phrase would misrepresent a faithful translation as an original.
  5. Every relative link in the task `README.md` resolves on disk.

CLI:

    python3 scripts/ai/validate_session.py docs/ai-sessions/task-005-public-ai-session-archive/

Exit codes: 0 = OK, 1 = validation error, 2 = usage / IO error.

Never touches the network. Never asks for a secret. Never prints one.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from typing import Any, Callable, Dict, List, Optional, Tuple

# --- Constants ---------------------------------------------------------------

REQUIRED_TOP_LEVEL_FIELDS: Tuple[str, ...] = (
    "schema_version",
    "task",
    "slug",
    "title",
    "agent",
    "source_language",
    "published_language",
    "translation_policy",
    "human_directed",
    "prompt_path",
    "transcript_path",
    "repository",
    "branch",
    "base_commit",
)

NULLABLE_POST_MERGE_FIELDS: Tuple[str, ...] = (
    "pr_number",
    "pr_url",
    "merge_commit",
    "ci_status",
    "post_merge_ci_status",
)

OPTIONAL_FIELDS: Tuple[str, ...] = NULLABLE_POST_MERGE_FIELDS + (
    "report_en",
    "report_ja",
    "x_manifest",
    "notes",
)

ALLOWED_FIELDS = set(REQUIRED_TOP_LEVEL_FIELDS + OPTIONAL_FIELDS)

VALID_SOURCE_LANGUAGES = frozenset({"Japanese", "English", "mixed"})
VALID_PUBLISHED_LANGUAGES = frozenset({"English"})
VALID_CI_CONCLUSIONS = frozenset(
    {"success", "failure", "cancelled", "skipped", "neutral"}
)

TASK_RE = re.compile(r"^Task [0-9]{3,}$")
SLUG_RE = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")
BRANCH_RE = re.compile(r"^ai/[0-9]{3}-[a-z0-9-]+$")
REPO_RE = re.compile(r"^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$")
BASE_COMMIT_RE = re.compile(r"^[0-9a-f]{7,40}$")
PR_URL_RE = re.compile(
    r"^https://github\.com/[A-Za-z0-9._-]+/[A-Za-z0-9._-]+/pull/[0-9]+$"
)

# Common credential patterns. Deliberately conservative: false positives are
# cheaper than a leaked token. Verify with a human before overriding.
_CRED_PATTERNS: Tuple[Tuple[str, "re.Pattern[str]"], ...] = (
    ("GitHub PAT (ghp_)",           re.compile(r"\bghp_[A-Za-z0-9]{20,}\b")),
    ("GitHub OAuth token (gho_)",   re.compile(r"\bgho_[A-Za-z0-9]{20,}\b")),
    ("GitHub server-to-server (ghs_)", re.compile(r"\bghs_[A-Za-z0-9]{20,}\b")),
    ("GitHub user-to-server (ghu_)",   re.compile(r"\bghu_[A-Za-z0-9]{20,}\b")),
    ("OpenAI-style key (sk-)",      re.compile(r"\bsk-[A-Za-z0-9]{20,}\b")),
    ("AWS access key (AKIA/ASIA)",  re.compile(r"\b(?:AKIA|ASIA)[0-9A-Z]{16}\b")),
    ("Slack bot token (xox[bapsr])", re.compile(r"\bxox[bapsr]-[A-Za-z0-9-]{10,}\b")),
    ("PEM private key header",      re.compile(r"-----BEGIN [A-Z ]*PRIVATE KEY-----")),
    ("Bearer/authorization header", re.compile(r"(?i)Authorization:\s*Bearer\s+[A-Za-z0-9._-]+")),
    ("password= assignment",        re.compile(r"(?i)\bpassword\s*=\s*['\"][^'\"]{4,}['\"]")),
    ("secret= assignment",          re.compile(r"(?i)\bsecret\s*=\s*['\"][^'\"]{6,}['\"]")),
)

BANNED_PHRASES: Tuple[str, ...] = (
    "verbatim original prompt",
)

RELATIVE_LINK_RE = re.compile(r"\[[^\]]+\]\(([^)#][^)]*)\)")


# --- Errors ------------------------------------------------------------------


class ValidationError(Exception):
    """Raised for any check failure. Messages must be safe to print."""


# --- Metadata schema check ---------------------------------------------------


def load_manifest(path: str) -> Dict[str, Any]:
    try:
        with open(path, "r", encoding="utf-8") as fh:
            return json.load(fh)
    except FileNotFoundError as exc:
        raise ValidationError(f"metadata.json not found at {path}") from exc
    except json.JSONDecodeError as exc:
        raise ValidationError(f"metadata.json ({path}) is not valid JSON: {exc}") from exc


def validate_manifest(meta: Any) -> None:
    if not isinstance(meta, dict):
        raise ValidationError("metadata.json: root must be a JSON object")

    missing = [k for k in REQUIRED_TOP_LEVEL_FIELDS if k not in meta]
    if missing:
        raise ValidationError(f"metadata.json: missing required fields: {', '.join(missing)}")

    unknown = [k for k in meta if k not in ALLOWED_FIELDS]
    if unknown:
        raise ValidationError(f"metadata.json: unknown fields: {', '.join(unknown)}")

    if meta["schema_version"] != 1:
        raise ValidationError(
            f"metadata.json: schema_version must be 1, got {meta['schema_version']!r}"
        )

    _check_str_pattern(meta, "task", TASK_RE)
    _check_str_pattern(meta, "slug", SLUG_RE)
    _check_str_pattern(meta, "branch", BRANCH_RE)
    _check_str_pattern(meta, "repository", REPO_RE)
    _check_str_pattern(meta, "base_commit", BASE_COMMIT_RE)

    for k in ("title", "agent", "translation_policy"):
        v = meta[k]
        if not isinstance(v, str) or not v.strip():
            raise ValidationError(f"metadata.json: {k} must be a non-empty string")

    if meta["source_language"] not in VALID_SOURCE_LANGUAGES:
        raise ValidationError(
            f"metadata.json: source_language must be one of "
            f"{sorted(VALID_SOURCE_LANGUAGES)}, got {meta['source_language']!r}"
        )
    if meta["published_language"] not in VALID_PUBLISHED_LANGUAGES:
        raise ValidationError(
            f"metadata.json: published_language must be one of "
            f"{sorted(VALID_PUBLISHED_LANGUAGES)}, got {meta['published_language']!r}"
        )

    if not isinstance(meta["human_directed"], bool):
        raise ValidationError("metadata.json: human_directed must be a boolean")

    if meta["prompt_path"] != "prompt.en.md":
        raise ValidationError(
            f"metadata.json: prompt_path must be 'prompt.en.md', got {meta['prompt_path']!r}"
        )
    if meta["transcript_path"] != "transcript.en.md":
        raise ValidationError(
            f"metadata.json: transcript_path must be 'transcript.en.md', "
            f"got {meta['transcript_path']!r}"
        )

    # Optional / nullable fields.
    if meta.get("pr_number") is not None:
        n = meta["pr_number"]
        if not (isinstance(n, int) and not isinstance(n, bool) and n >= 1):
            raise ValidationError(f"metadata.json: pr_number must be a positive int, got {n!r}")
    if meta.get("pr_url") is not None:
        u = meta["pr_url"]
        if not (isinstance(u, str) and PR_URL_RE.match(u)):
            raise ValidationError(f"metadata.json: pr_url does not look like a PR URL: {u!r}")
    if meta.get("merge_commit") is not None:
        c = meta["merge_commit"]
        if not (isinstance(c, str) and BASE_COMMIT_RE.match(c)):
            raise ValidationError(f"metadata.json: merge_commit must be a hex SHA, got {c!r}")
    for k in ("ci_status", "post_merge_ci_status"):
        v = meta.get(k)
        if v is not None and v not in VALID_CI_CONCLUSIONS:
            raise ValidationError(
                f"metadata.json: {k} must be one of {sorted(VALID_CI_CONCLUSIONS)} or null, "
                f"got {v!r}"
            )
    for k in ("report_en", "report_ja", "x_manifest", "notes"):
        v = meta.get(k)
        if v is not None and not isinstance(v, str):
            raise ValidationError(f"metadata.json: {k} must be a string or null, got {v!r}")


def _check_str_pattern(meta: Dict[str, Any], key: str, pattern: "re.Pattern[str]") -> None:
    v = meta[key]
    if not (isinstance(v, str) and pattern.match(v)):
        raise ValidationError(
            f"metadata.json: {key} must match pattern {pattern.pattern!r}, got {v!r}"
        )


# --- File presence -----------------------------------------------------------


def check_referenced_files(task_dir: str, meta: Dict[str, Any]) -> None:
    for key in ("prompt_path", "transcript_path"):
        rel = meta[key]
        path = os.path.join(task_dir, rel)
        if not os.path.isfile(path):
            raise ValidationError(f"file referenced by {key} not found: {path}")


# --- Secret scan -------------------------------------------------------------


def scan_for_credentials(task_dir: str) -> None:
    """Fail if any file in the task directory contains an obvious secret."""
    for fname in sorted(os.listdir(task_dir)):
        fpath = os.path.join(task_dir, fname)
        if not os.path.isfile(fpath):
            continue
        try:
            with open(fpath, "r", encoding="utf-8") as fh:
                text = fh.read()
        except (OSError, UnicodeDecodeError):
            # Binary or unreadable file — skip silently; secrets in binaries
            # are out of scope for this stdlib linter.
            continue
        for label, pattern in _CRED_PATTERNS:
            if pattern.search(text):
                raise ValidationError(
                    f"credential-like pattern detected in {fpath}: {label}. "
                    f"Replace with [REDACTED] before committing."
                )


# --- Banned phrases ----------------------------------------------------------


def scan_for_banned_phrases(task_dir: str) -> None:
    for fname in sorted(os.listdir(task_dir)):
        fpath = os.path.join(task_dir, fname)
        if not os.path.isfile(fpath):
            continue
        try:
            with open(fpath, "r", encoding="utf-8") as fh:
                text = fh.read().lower()
        except (OSError, UnicodeDecodeError):
            continue
        for phrase in BANNED_PHRASES:
            if phrase in text:
                raise ValidationError(
                    f"banned phrase in {fpath}: {phrase!r}. "
                    f"The archive must state that a translation is a translation."
                )


# --- Relative-link check on the per-task README ------------------------------


def check_readme_relative_links(task_dir: str) -> None:
    readme = os.path.join(task_dir, "README.md")
    if not os.path.isfile(readme):
        raise ValidationError(f"missing per-task README.md at {readme}")
    with open(readme, "r", encoding="utf-8") as fh:
        text = fh.read()
    for match in RELATIVE_LINK_RE.finditer(text):
        target = match.group(1).strip()
        if target.startswith(("http://", "https://", "mailto:")):
            continue
        # Strip any anchor fragment before existence-checking the path.
        # `../README.md#security` and `../README.md` both point at the
        # same file on disk.
        file_part = target.split("#", 1)[0]
        if not file_part:
            # Bare in-page anchor like `(#navigation-links)` — RELATIVE_LINK_RE
            # already excludes these at the first character, but be defensive.
            continue
        resolved = os.path.normpath(os.path.join(task_dir, file_part))
        if not os.path.exists(resolved):
            raise ValidationError(
                f"README.md link does not resolve: {target!r} → {resolved}"
            )


# --- Orchestration -----------------------------------------------------------


def validate_task_dir(task_dir: str) -> None:
    """Run every check for one task directory. Raises ValidationError on failure."""
    if not os.path.isdir(task_dir):
        raise ValidationError(f"task directory does not exist: {task_dir}")

    meta_path = os.path.join(task_dir, "metadata.json")
    meta = load_manifest(meta_path)
    validate_manifest(meta)
    check_referenced_files(task_dir, meta)
    scan_for_credentials(task_dir)
    scan_for_banned_phrases(task_dir)
    check_readme_relative_links(task_dir)


def _parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        prog="validate_session.py",
        description="Lint one WildLive AI development-session archive directory.",
    )
    p.add_argument(
        "task_dir",
        help="Path to a docs/ai-sessions/task-NNN-<slug>/ directory.",
    )
    return p


def main(argv: Optional[List[str]] = None) -> int:
    args = _parser().parse_args(argv)
    try:
        validate_task_dir(args.task_dir)
    except ValidationError as exc:
        print(f"validation error: {exc}", file=sys.stderr)
        return 1
    except OSError as exc:
        print(f"IO error: {exc}", file=sys.stderr)
        return 2
    print(f"OK: {args.task_dir}")
    return 0


if __name__ == "__main__":  # pragma: no cover
    sys.exit(main())
