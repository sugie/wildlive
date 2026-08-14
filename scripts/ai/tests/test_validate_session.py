"""Tests for scripts/ai/validate_session.py.

Stdlib-only unittest. No network. No real secrets — dummy fixtures use
patterns that resemble credential shapes but are not valid values.
"""

from __future__ import annotations

import json
import os
import shutil
import sys
import tempfile
import textwrap
import unittest
from typing import Dict, Any

_HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(_HERE))

import validate_session as vs  # noqa: E402


def _valid_metadata(**overrides: Any) -> Dict[str, Any]:
    base = {
        "schema_version": 1,
        "task": "Task 999",
        "slug": "demo-slug",
        "title": "Demo task",
        "agent": "Claude Code (claude-opus-4-7[1m])",
        "source_language": "Japanese",
        "published_language": "English",
        "translation_policy": (
            "Faithful English translation. No summary or added requirements."
        ),
        "human_directed": True,
        "prompt_path": "prompt.en.md",
        "transcript_path": "transcript.en.md",
        "repository": "sugie/wildlive",
        "branch": "ai/999-demo-slug",
        "base_commit": "abcdef1",
    }
    base.update(overrides)
    return base


def _write_valid_task_dir(root: str) -> str:
    task_dir = os.path.join(root, "task-999-demo-slug")
    os.makedirs(task_dir)
    with open(os.path.join(task_dir, "prompt.en.md"), "w", encoding="utf-8") as fh:
        fh.write(
            "# Human Prompt\n\n"
            "Source language: Japanese\n"
            "Published language: English\n"
            "Translation: Faithful English translation.\n\n"
            "Do the thing.\n"
        )
    with open(os.path.join(task_dir, "transcript.en.md"), "w", encoding="utf-8") as fh:
        fh.write(
            "# AI Development Session\n\n"
            "## Human\nDo the thing.\n\n"
            "## AI\nDoing the thing.\n"
        )
    with open(os.path.join(task_dir, "README.md"), "w", encoding="utf-8") as fh:
        fh.write(
            "# Task 999\n\n"
            "- [View Prompt](prompt.en.md)\n"
            "- [View AI Conversation](transcript.en.md)\n"
            "- [PR](https://github.com/sugie/wildlive/pull/1)\n"
        )
    with open(os.path.join(task_dir, "metadata.json"), "w", encoding="utf-8") as fh:
        json.dump(_valid_metadata(), fh)
    return task_dir


class ManifestSchemaTests(unittest.TestCase):
    def test_valid_manifest_accepted(self) -> None:
        vs.validate_manifest(_valid_metadata())

    def test_missing_required_field_rejected(self) -> None:
        for key in vs.REQUIRED_TOP_LEVEL_FIELDS:
            with self.subTest(key=key):
                data = _valid_metadata()
                del data[key]
                with self.assertRaises(vs.ValidationError):
                    vs.validate_manifest(data)

    def test_unknown_field_rejected(self) -> None:
        data = _valid_metadata(extra="no")
        with self.assertRaises(vs.ValidationError):
            vs.validate_manifest(data)

    def test_task_pattern_enforced(self) -> None:
        for bad in ("task 999", "Task 99", "T 999", "Task 999 - Demo"):
            with self.subTest(bad=bad):
                data = _valid_metadata(task=bad)
                with self.assertRaises(vs.ValidationError):
                    vs.validate_manifest(data)

    def test_slug_kebab_only(self) -> None:
        for bad in ("Demo", "demo_slug", "-demo", "demo-"):
            with self.subTest(bad=bad):
                data = _valid_metadata(slug=bad)
                with self.assertRaises(vs.ValidationError):
                    vs.validate_manifest(data)

    def test_branch_pattern_enforced(self) -> None:
        for bad in ("main", "feature/x", "ai/1-demo", "ai/999-Demo"):
            with self.subTest(bad=bad):
                data = _valid_metadata(branch=bad)
                with self.assertRaises(vs.ValidationError):
                    vs.validate_manifest(data)

    def test_prompt_path_fixed(self) -> None:
        data = _valid_metadata(prompt_path="prompt.md")
        with self.assertRaises(vs.ValidationError):
            vs.validate_manifest(data)

    def test_transcript_path_fixed(self) -> None:
        data = _valid_metadata(transcript_path="transcript.md")
        with self.assertRaises(vs.ValidationError):
            vs.validate_manifest(data)

    def test_source_language_enum(self) -> None:
        data = _valid_metadata(source_language="Korean")
        with self.assertRaises(vs.ValidationError):
            vs.validate_manifest(data)

    def test_published_language_must_be_english(self) -> None:
        data = _valid_metadata(published_language="Japanese")
        with self.assertRaises(vs.ValidationError):
            vs.validate_manifest(data)

    def test_pr_url_pattern(self) -> None:
        data = _valid_metadata(pr_number=1, pr_url="https://example.com/x")
        with self.assertRaises(vs.ValidationError):
            vs.validate_manifest(data)

    def test_pr_number_positive(self) -> None:
        data = _valid_metadata(pr_number=0)
        with self.assertRaises(vs.ValidationError):
            vs.validate_manifest(data)

    def test_ci_status_enum(self) -> None:
        data = _valid_metadata(ci_status="passing")
        with self.assertRaises(vs.ValidationError):
            vs.validate_manifest(data)

    def test_ci_status_null_is_ok(self) -> None:
        vs.validate_manifest(_valid_metadata(ci_status=None))

    def test_boolean_human_directed(self) -> None:
        data = _valid_metadata(human_directed="yes")
        with self.assertRaises(vs.ValidationError):
            vs.validate_manifest(data)


class TaskDirTests(unittest.TestCase):
    def _tmp(self) -> str:
        d = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, d, ignore_errors=True)
        return d

    def test_valid_task_dir_passes(self) -> None:
        task_dir = _write_valid_task_dir(self._tmp())
        vs.validate_task_dir(task_dir)  # must not raise

    def test_missing_prompt_file_rejected(self) -> None:
        task_dir = _write_valid_task_dir(self._tmp())
        os.unlink(os.path.join(task_dir, "prompt.en.md"))
        with self.assertRaises(vs.ValidationError):
            vs.validate_task_dir(task_dir)

    def test_missing_transcript_file_rejected(self) -> None:
        task_dir = _write_valid_task_dir(self._tmp())
        os.unlink(os.path.join(task_dir, "transcript.en.md"))
        with self.assertRaises(vs.ValidationError):
            vs.validate_task_dir(task_dir)

    def test_missing_readme_rejected(self) -> None:
        task_dir = _write_valid_task_dir(self._tmp())
        os.unlink(os.path.join(task_dir, "README.md"))
        with self.assertRaises(vs.ValidationError):
            vs.validate_task_dir(task_dir)

    def test_broken_readme_link_rejected(self) -> None:
        task_dir = _write_valid_task_dir(self._tmp())
        with open(os.path.join(task_dir, "README.md"), "a", encoding="utf-8") as fh:
            fh.write("\n- [Broken](does-not-exist.md)\n")
        with self.assertRaises(vs.ValidationError):
            vs.validate_task_dir(task_dir)

    def test_link_with_anchor_fragment_accepted(self) -> None:
        """A link like `[foo](prompt.en.md#somewhere)` should validate as long
        as the file part exists on disk. The anchor fragment must not be
        treated as part of the filename."""
        task_dir = _write_valid_task_dir(self._tmp())
        with open(os.path.join(task_dir, "README.md"), "a", encoding="utf-8") as fh:
            fh.write("\n- [Prompt section](prompt.en.md#header)\n")
        vs.validate_task_dir(task_dir)  # must not raise

    def test_broken_link_with_anchor_still_rejected(self) -> None:
        """Even with an anchor, a missing file part must fail."""
        task_dir = _write_valid_task_dir(self._tmp())
        with open(os.path.join(task_dir, "README.md"), "a", encoding="utf-8") as fh:
            fh.write("\n- [Broken](does-not-exist.md#anywhere)\n")
        with self.assertRaises(vs.ValidationError):
            vs.validate_task_dir(task_dir)

    def test_task_dir_not_directory(self) -> None:
        f = tempfile.NamedTemporaryFile(delete=False)
        self.addCleanup(os.unlink, f.name)
        f.close()
        with self.assertRaises(vs.ValidationError):
            vs.validate_task_dir(f.name)


class CredentialScanTests(unittest.TestCase):
    """Regression tests for the secret scanner. Fixtures resemble
    credential shapes but are NOT valid secrets."""

    def _tmp_with_prompt_containing(self, needle: str) -> str:
        d = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, d, ignore_errors=True)
        task_dir = _write_valid_task_dir(d)
        with open(os.path.join(task_dir, "prompt.en.md"), "a", encoding="utf-8") as fh:
            fh.write("\n" + needle + "\n")
        return task_dir

    def test_ghp_token_pattern_rejected(self) -> None:
        task_dir = self._tmp_with_prompt_containing("token: ghp_" + "A" * 36)
        with self.assertRaises(vs.ValidationError):
            vs.validate_task_dir(task_dir)

    def test_gho_token_pattern_rejected(self) -> None:
        task_dir = self._tmp_with_prompt_containing("token: gho_" + "b" * 36)
        with self.assertRaises(vs.ValidationError):
            vs.validate_task_dir(task_dir)

    def test_openai_style_key_rejected(self) -> None:
        task_dir = self._tmp_with_prompt_containing("key: sk-" + "A1b2C3d4" * 4)
        with self.assertRaises(vs.ValidationError):
            vs.validate_task_dir(task_dir)

    def test_aws_access_key_rejected(self) -> None:
        task_dir = self._tmp_with_prompt_containing("aws: AKIA" + "ABCDEFGHIJKLMNOP")
        with self.assertRaises(vs.ValidationError):
            vs.validate_task_dir(task_dir)

    def test_slack_token_rejected(self) -> None:
        task_dir = self._tmp_with_prompt_containing("slack: xoxb-1234567890-abcdef")
        with self.assertRaises(vs.ValidationError):
            vs.validate_task_dir(task_dir)

    def test_pem_private_key_header_rejected(self) -> None:
        task_dir = self._tmp_with_prompt_containing("-----BEGIN RSA PRIVATE KEY-----")
        with self.assertRaises(vs.ValidationError):
            vs.validate_task_dir(task_dir)

    def test_bearer_authorization_header_rejected(self) -> None:
        task_dir = self._tmp_with_prompt_containing("Authorization: Bearer abcdef1234567890")
        with self.assertRaises(vs.ValidationError):
            vs.validate_task_dir(task_dir)

    def test_password_assignment_rejected(self) -> None:
        task_dir = self._tmp_with_prompt_containing('password="hunter2!!"')
        with self.assertRaises(vs.ValidationError):
            vs.validate_task_dir(task_dir)

    def test_redacted_placeholder_accepted(self) -> None:
        task_dir = self._tmp_with_prompt_containing("Authorization: Bearer [REDACTED]")
        vs.validate_task_dir(task_dir)  # must not raise


class BannedPhraseTests(unittest.TestCase):
    def _tmp_with_prompt_containing(self, needle: str) -> str:
        d = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, d, ignore_errors=True)
        task_dir = _write_valid_task_dir(d)
        with open(os.path.join(task_dir, "prompt.en.md"), "a", encoding="utf-8") as fh:
            fh.write("\n" + needle + "\n")
        return task_dir

    def test_banned_phrase_rejected(self) -> None:
        task_dir = self._tmp_with_prompt_containing("This is the verbatim original prompt.")
        with self.assertRaises(vs.ValidationError):
            vs.validate_task_dir(task_dir)

    def test_banned_phrase_case_insensitive(self) -> None:
        task_dir = self._tmp_with_prompt_containing("VERBATIM ORIGINAL PROMPT")
        with self.assertRaises(vs.ValidationError):
            vs.validate_task_dir(task_dir)


class RepoBootstrapTests(unittest.TestCase):
    """The archive record for Task 005 shipped by this PR must itself pass."""

    def test_task_005_record_validates(self) -> None:
        # tests/ → scripts/ai/ → scripts/ → repo root
        repo_root = os.path.abspath(os.path.join(_HERE, "..", "..", ".."))
        task_dir = os.path.join(
            repo_root,
            "docs",
            "ai-sessions",
            "task-005-public-ai-session-archive",
        )
        if not os.path.isdir(task_dir):
            self.skipTest(f"repo bootstrap directory not present: {task_dir}")
        vs.validate_task_dir(task_dir)


if __name__ == "__main__":  # pragma: no cover
    unittest.main()
