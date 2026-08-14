"""Tests for scripts/social/post_x.py.

Stdlib-only (unittest). No network. No real X credentials.
"""

from __future__ import annotations

import io
import json
import os
import sys
import tempfile
import unittest
import urllib.error
from typing import Any, Dict, List
from unittest import mock

# Make the sibling module importable regardless of cwd.
_HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(_HERE))

import post_x  # noqa: E402


def _valid_manifest() -> Dict[str, Any]:
    """Legacy v1 bilingual manifest — canonical shape for backwards-compat tests."""
    return {
        "schema_version": 1,
        "task": "Task 003",
        "slug": "x-development-live",
        "post_on_merge": True,
        "ja": "AI開発実況を追加しました。",
        "en": "Added an AI dev-live feed.",
    }


def _valid_v2_manifest() -> Dict[str, Any]:
    """v2 English-only manifest — canonical shape for the new default."""
    return {
        "schema_version": 2,
        "task": "Task 100",
        "slug": "english-only-demo",
        "post_on_merge": True,
        "en": "Testing English-only rendering.",
    }


def _fake_credentials() -> post_x.OAuthCredentials:
    # These are intentionally NOT real credentials. Used only for signature
    # tests and to satisfy the type at the boundary of post_tweet.
    return post_x.OAuthCredentials(
        api_key="test-consumer-key",
        api_key_secret="test-consumer-secret",
        access_token="test-access-token",
        access_token_secret="test-access-secret",
    )


class ManifestValidationTests(unittest.TestCase):
    def test_valid_manifest_accepted(self) -> None:
        post_x.validate_manifest(_valid_manifest())

    def test_v1_missing_required_key_rejected(self) -> None:
        for key in ("schema_version", "task", "slug", "post_on_merge", "ja", "en"):
            with self.subTest(key=key):
                data = _valid_manifest()
                del data[key]
                with self.assertRaises(post_x.ManifestError):
                    post_x.validate_manifest(data)

    def test_v1_unknown_key_rejected(self) -> None:
        data = _valid_manifest()
        data["extra"] = "no"
        with self.assertRaises(post_x.ManifestError):
            post_x.validate_manifest(data)

    def test_slug_must_be_kebab(self) -> None:
        for bad in ("Task 003", "task_003", "Task-003", "-x-", "", "TASK"):
            with self.subTest(slug=bad):
                data = _valid_manifest()
                data["slug"] = bad
                with self.assertRaises(post_x.ManifestError):
                    post_x.validate_manifest(data)

    def test_post_on_merge_must_be_boolean(self) -> None:
        data = _valid_manifest()
        data["post_on_merge"] = "true"  # str, not bool
        with self.assertRaises(post_x.ManifestError):
            post_x.validate_manifest(data)

    def test_missing_language_rejected(self) -> None:
        for lang in ("ja", "en"):
            with self.subTest(lang=lang):
                data = _valid_manifest()
                data[lang] = ""
                with self.assertRaises(post_x.ManifestError):
                    post_x.validate_manifest(data)

    def test_body_must_not_contain_hashtag(self) -> None:
        data = _valid_manifest()
        data["en"] = "already tagged #shipaton"
        with self.assertRaises(post_x.ManifestError):
            post_x.validate_manifest(data)

    def test_body_must_not_contain_pr_url(self) -> None:
        data = _valid_manifest()
        data["en"] = "see github.com/sugie/wildlive/pull/1"
        with self.assertRaises(post_x.ManifestError):
            post_x.validate_manifest(data)

    def test_body_must_not_contain_pr_hash(self) -> None:
        data = _valid_manifest()
        data["ja"] = "PR #1 参照"
        with self.assertRaises(post_x.ManifestError):
            post_x.validate_manifest(data)

    def test_load_manifest_reads_file(self) -> None:
        with tempfile.NamedTemporaryFile(
            mode="w", encoding="utf-8", suffix=".json", delete=False
        ) as f:
            json.dump(_valid_manifest(), f, ensure_ascii=False)
            path = f.name
        try:
            data = post_x.load_manifest(path)
            self.assertEqual(data["slug"], "x-development-live")
        finally:
            os.unlink(path)

    def test_load_manifest_rejects_invalid_json(self) -> None:
        with tempfile.NamedTemporaryFile(
            mode="w", encoding="utf-8", suffix=".json", delete=False
        ) as f:
            f.write("{not-json")
            path = f.name
        try:
            with self.assertRaises(post_x.ManifestError):
                post_x.load_manifest(path)
        finally:
            os.unlink(path)


class SchemaVersionTests(unittest.TestCase):
    """Covers the v1 (legacy bilingual) ↔ v2 (English-only) split."""

    # -- v1 (legacy bilingual) -------------------------------------------------

    def test_v1_valid_manifest_accepted(self) -> None:
        post_x.validate_manifest(_valid_manifest())

    def test_v1_missing_ja_rejected(self) -> None:
        data = _valid_manifest()
        del data["ja"]
        with self.assertRaises(post_x.ManifestError):
            post_x.validate_manifest(data)

    def test_v1_missing_en_rejected(self) -> None:
        data = _valid_manifest()
        del data["en"]
        with self.assertRaises(post_x.ManifestError):
            post_x.validate_manifest(data)

    def test_v1_render_output_is_byte_stable(self) -> None:
        """v1 rendering must remain byte-identical to the pre-v2 output so
        historical manifests (task-003, task-004) reproduce exactly."""
        expected = (
            "WildLive Dev · Task 003\n"
            "\n"
            "AI開発実況を追加しました。\n"
            "\n"
            "Added an AI dev-live feed.\n"
            "\n"
            "PR #4\n"
            "https://github.com/sugie/wildlive/pull/4\n"
            "\n"
            "#shipaton"
        )
        actual = post_x.render_post(
            _valid_manifest(), 4, "https://github.com/sugie/wildlive/pull/4"
        )
        self.assertEqual(actual, expected)

    # -- v2 (English only) -----------------------------------------------------

    def test_v2_valid_manifest_accepted(self) -> None:
        post_x.validate_manifest(_valid_v2_manifest())

    def test_v2_requires_en(self) -> None:
        data = _valid_v2_manifest()
        del data["en"]
        with self.assertRaises(post_x.ManifestError):
            post_x.validate_manifest(data)

    def test_v2_forbids_ja_field(self) -> None:
        data = _valid_v2_manifest()
        data["ja"] = "これは v2 に入れてはいけない"
        with self.assertRaises(post_x.ManifestError):
            post_x.validate_manifest(data)

    def test_v2_render_excludes_any_japanese_body(self) -> None:
        rendered = post_x.render_post(
            _valid_v2_manifest(), 8, "https://github.com/sugie/wildlive/pull/8"
        )
        # The English body must be present.
        self.assertIn("Testing English-only rendering.", rendered)
        # No CJK code point should appear anywhere in the output.
        cjk_hits = [
            (i, ch) for i, ch in enumerate(rendered)
            if 0x3000 <= ord(ch) <= 0x9FFF or 0xFF00 <= ord(ch) <= 0xFFEF
        ]
        self.assertEqual(cjk_hits, [], f"unexpected CJK in v2 render: {cjk_hits!r}")
        # Structural expectations for v2.
        self.assertTrue(rendered.startswith("WildLive Dev · Task 100\n"))
        self.assertIn("PR #8", rendered)
        self.assertIn("https://github.com/sugie/wildlive/pull/8", rendered)
        self.assertTrue(rendered.rstrip().endswith("#shipaton"))

    def test_v2_render_has_no_extra_body_block(self) -> None:
        """The v2 template must have exactly one body block between the header
        and the PR line — never a leftover blank paragraph where JP used to sit."""
        rendered = post_x.render_post(
            _valid_v2_manifest(), 8, "https://github.com/sugie/wildlive/pull/8"
        )
        expected = (
            "WildLive Dev · Task 100\n"
            "\n"
            "Testing English-only rendering.\n"
            "\n"
            "PR #8\n"
            "https://github.com/sugie/wildlive/pull/8\n"
            "\n"
            "#shipaton"
        )
        self.assertEqual(rendered, expected)

    def test_v2_body_hashtag_guard_still_applies(self) -> None:
        data = _valid_v2_manifest()
        data["en"] = "already tagged #shipaton"
        with self.assertRaises(post_x.ManifestError):
            post_x.validate_manifest(data)

    def test_v2_body_pr_url_guard_still_applies(self) -> None:
        data = _valid_v2_manifest()
        data["en"] = "see github.com/sugie/wildlive/pull/1"
        with self.assertRaises(post_x.ManifestError):
            post_x.validate_manifest(data)

    def test_v2_body_pr_hash_guard_still_applies(self) -> None:
        data = _valid_v2_manifest()
        data["en"] = "see PR #1"
        with self.assertRaises(post_x.ManifestError):
            post_x.validate_manifest(data)

    def test_v2_slug_still_kebab(self) -> None:
        data = _valid_v2_manifest()
        data["slug"] = "Not_Kebab"
        with self.assertRaises(post_x.ManifestError):
            post_x.validate_manifest(data)

    def test_v2_post_on_merge_must_be_boolean(self) -> None:
        data = _valid_v2_manifest()
        data["post_on_merge"] = "true"
        with self.assertRaises(post_x.ManifestError):
            post_x.validate_manifest(data)

    # -- unknown / boundary cases ---------------------------------------------

    def test_unknown_schema_version_fails_closed(self) -> None:
        for bad in (0, 3, 99, "1", None, -1):
            with self.subTest(version=bad):
                data = _valid_v2_manifest()
                data["schema_version"] = bad
                with self.assertRaises(post_x.ManifestError):
                    post_x.validate_manifest(data)

    def test_render_rejects_unsupported_schema_version(self) -> None:
        """Defence-in-depth: even if validate_manifest were bypassed, render_post
        must refuse an unknown version."""
        m = dict(_valid_v2_manifest(), schema_version=99)
        with self.assertRaises(post_x.RenderError):
            post_x.render_post(m, 1, "https://github.com/sugie/wildlive/pull/1")

    def test_v1_length_check_still_works(self) -> None:
        long = "a" * 500
        m = dict(_valid_manifest(), en=long)
        rendered = post_x.render_post(m, 1, "https://github.com/sugie/wildlive/pull/1")
        with self.assertRaises(post_x.LengthError):
            post_x.validate_length(rendered)

    def test_v2_length_check_still_works(self) -> None:
        long = "a" * 500
        m = dict(_valid_v2_manifest(), en=long)
        rendered = post_x.render_post(m, 1, "https://github.com/sugie/wildlive/pull/1")
        with self.assertRaises(post_x.LengthError):
            post_x.validate_length(rendered)


class RenderTests(unittest.TestCase):
    def test_rendered_post_contains_all_parts(self) -> None:
        text = post_x.render_post(
            _valid_manifest(),
            pr_number=42,
            pr_url="https://github.com/sugie/wildlive/pull/42",
        )
        self.assertIn("WildLive Dev · Task 003", text)
        self.assertIn("AI開発実況を追加しました。", text)
        self.assertIn("Added an AI dev-live feed.", text)
        self.assertIn("PR #42", text)
        self.assertIn("https://github.com/sugie/wildlive/pull/42", text)
        self.assertTrue(
            text.rstrip().endswith(post_x.HASHTAG),
            f"post should end with hashtag; ends with {text[-20:]!r}",
        )

    def test_bad_pr_number_rejected(self) -> None:
        for bad in (0, -1, "1", 1.0):
            with self.subTest(bad=bad):
                with self.assertRaises(post_x.RenderError):
                    post_x.render_post(_valid_manifest(), bad, "https://github.com/sugie/wildlive/pull/1")  # type: ignore[arg-type]

    def test_bad_pr_url_rejected(self) -> None:
        for bad in ("http://github.com/x", "https://example.com/x", "", None):
            with self.subTest(bad=bad):
                with self.assertRaises(post_x.RenderError):
                    post_x.render_post(_valid_manifest(), 1, bad)  # type: ignore[arg-type]


class WeightedLengthTests(unittest.TestCase):
    def test_ascii_weights_one(self) -> None:
        self.assertEqual(post_x.weighted_length("hello"), 5)

    def test_cjk_weighs_two(self) -> None:
        # 5 Japanese characters — each weight 2.
        self.assertEqual(post_x.weighted_length("こんにちは"), 10)

    def test_url_counts_as_url_weight(self) -> None:
        wl = post_x.weighted_length("see https://example.com/very/long/path/that/normally/is/many/chars end")
        # 'see ' (4) + URL (23) + ' end' (4) = 31
        self.assertEqual(wl, 31)

    def test_over_length_rejected(self) -> None:
        long = "a" * 300
        with self.assertRaises(post_x.LengthError):
            post_x.validate_length(long)

    def test_under_length_accepted(self) -> None:
        self.assertEqual(post_x.validate_length("short"), 5)


class OAuthTests(unittest.TestCase):
    """OAuth 1.0a signature tests with fixed nonce/timestamp for determinism."""

    def test_percent_encode_rules(self) -> None:
        # RFC 3986 unreserved characters pass through; everything else encodes.
        self.assertEqual(post_x._percent_encode("Ladies + Gentlemen"), "Ladies%20%2B%20Gentlemen")
        self.assertEqual(post_x._percent_encode("abc-._~"), "abc-._~")
        self.assertEqual(post_x._percent_encode("こんにちは"),
                         "%E3%81%93%E3%82%93%E3%81%AB%E3%81%A1%E3%81%AF")

    def test_header_deterministic_with_fixed_nonce(self) -> None:
        creds = _fake_credentials()
        params = post_x.build_oauth_params(
            creds, nonce="a" * 32, timestamp="1700000000"
        )
        h1 = post_x.build_oauth_header("POST", post_x.TWEET_ENDPOINT, creds, params)
        h2 = post_x.build_oauth_header("POST", post_x.TWEET_ENDPOINT, creds, params)
        self.assertEqual(h1, h2)

    def test_header_changes_with_different_nonce(self) -> None:
        creds = _fake_credentials()
        params_a = post_x.build_oauth_params(
            creds, nonce="a" * 32, timestamp="1700000000"
        )
        params_b = post_x.build_oauth_params(
            creds, nonce="b" * 32, timestamp="1700000000"
        )
        h_a = post_x.build_oauth_header("POST", post_x.TWEET_ENDPOINT, creds, params_a)
        h_b = post_x.build_oauth_header("POST", post_x.TWEET_ENDPOINT, creds, params_b)
        self.assertNotEqual(h_a, h_b)

    def test_header_starts_with_oauth_scheme(self) -> None:
        creds = _fake_credentials()
        params = post_x.build_oauth_params(
            creds, nonce="a" * 32, timestamp="1700000000"
        )
        h = post_x.build_oauth_header("POST", post_x.TWEET_ENDPOINT, creds, params)
        self.assertTrue(h.startswith("OAuth "))
        self.assertIn('oauth_signature=', h)
        self.assertIn('oauth_signature_method="HMAC-SHA1"', h)

    def test_header_never_contains_secrets(self) -> None:
        creds = _fake_credentials()
        params = post_x.build_oauth_params(
            creds, nonce="a" * 32, timestamp="1700000000"
        )
        h = post_x.build_oauth_header("POST", post_x.TWEET_ENDPOINT, creds, params)
        # Neither secret should be visible in the header. Percent-encoded
        # secrets would also be a leak, so check both raw and encoded forms.
        self.assertNotIn(creds.api_key_secret, h)
        self.assertNotIn(creds.access_token_secret, h)
        self.assertNotIn(post_x._percent_encode(creds.api_key_secret), h)
        self.assertNotIn(post_x._percent_encode(creds.access_token_secret), h)

    def test_credentials_repr_redacts(self) -> None:
        creds = _fake_credentials()
        r = repr(creds)
        self.assertIn("redacted", r)
        self.assertNotIn(creds.api_key_secret, r)
        self.assertNotIn(creds.access_token_secret, r)

    def test_from_env_missing_raises(self) -> None:
        with self.assertRaises(post_x.ConfigError):
            post_x.OAuthCredentials.from_env(env={})
        with self.assertRaises(post_x.ConfigError):
            post_x.OAuthCredentials.from_env(env={"X_API_KEY": "k"})

    def test_from_env_all_set_ok(self) -> None:
        env = {
            "X_API_KEY": "k",
            "X_API_KEY_SECRET": "ks",
            "X_ACCESS_TOKEN": "t",
            "X_ACCESS_TOKEN_SECRET": "ts",
        }
        creds = post_x.OAuthCredentials.from_env(env=env)
        self.assertEqual(creds.api_key, "k")


class _FakeResponse:
    def __init__(self, status: int, body: bytes) -> None:
        self.status = status
        self._body = body

    def read(self) -> bytes:
        return self._body

    def getcode(self) -> int:
        return self.status

    def __enter__(self):
        return self

    def __exit__(self, *args):
        return False


class _FakeOpener:
    def __init__(self, responses: List[Any]) -> None:
        self._responses = list(responses)
        self.calls: List[Any] = []

    def open(self, req, timeout=None):
        self.calls.append(req)
        if not self._responses:
            raise AssertionError("opener.open called more times than expected")
        r = self._responses.pop(0)
        if isinstance(r, Exception):
            raise r
        return r


class PublisherHTTPTests(unittest.TestCase):
    def _http_error(self, code: int, body: bytes = b"") -> urllib.error.HTTPError:
        return urllib.error.HTTPError(
            url=post_x.TWEET_ENDPOINT,
            code=code,
            msg="err",
            hdrs=None,  # type: ignore[arg-type]
            fp=io.BytesIO(body),
        )

    def test_201_parsed(self) -> None:
        resp = _FakeResponse(201, b'{"data":{"id":"1234567890","text":"hi"}}')
        opener = _FakeOpener([resp])
        sleeps: List[float] = []
        pid, url, status = post_x.post_tweet(
            "hi", _fake_credentials(),
            http_opener=opener,
            sleep_fn=lambda s: sleeps.append(s),
        )
        self.assertEqual(pid, "1234567890")
        self.assertEqual(status, 201)
        self.assertEqual(url, "https://x.com/i/status/1234567890")
        self.assertEqual(sleeps, [], "no sleep on immediate success")
        self.assertEqual(len(opener.calls), 1)

    def test_401_not_retried(self) -> None:
        opener = _FakeOpener([self._http_error(401, b'{"title":"Unauthorized"}')])
        sleeps: List[float] = []
        with self.assertRaises(post_x.PublishError):
            post_x.post_tweet(
                "hi", _fake_credentials(),
                http_opener=opener,
                sleep_fn=lambda s: sleeps.append(s),
            )
        self.assertEqual(len(opener.calls), 1, "401 must not retry")
        self.assertEqual(sleeps, [])

    def test_403_not_retried(self) -> None:
        opener = _FakeOpener([self._http_error(403, b"{}")])
        with self.assertRaises(post_x.PublishError):
            post_x.post_tweet("hi", _fake_credentials(), http_opener=opener,
                              sleep_fn=lambda s: None)
        self.assertEqual(len(opener.calls), 1)

    def test_429_bounded_retry(self) -> None:
        opener = _FakeOpener([
            self._http_error(429, b"{}"),
            self._http_error(429, b"{}"),
            self._http_error(429, b"{}"),
        ])
        sleeps: List[float] = []
        with self.assertRaises(post_x.PublishError):
            post_x.post_tweet("hi", _fake_credentials(), http_opener=opener,
                              sleep_fn=lambda s: sleeps.append(s))
        self.assertEqual(len(opener.calls), 3, "should stop at max_retries")
        self.assertEqual(len(sleeps), 2, "sleep between attempts, not after last")

    def test_5xx_bounded_retry_then_success(self) -> None:
        opener = _FakeOpener([
            self._http_error(503, b"{}"),
            _FakeResponse(201, b'{"data":{"id":"9","text":"hi"}}'),
        ])
        sleeps: List[float] = []
        pid, _, _ = post_x.post_tweet("hi", _fake_credentials(), http_opener=opener,
                                      sleep_fn=lambda s: sleeps.append(s))
        self.assertEqual(pid, "9")
        self.assertEqual(len(opener.calls), 2)
        self.assertEqual(len(sleeps), 1)

    def test_transport_error_bounded_retry(self) -> None:
        opener = _FakeOpener([
            urllib.error.URLError("boom"),
            urllib.error.URLError("boom"),
            urllib.error.URLError("boom"),
        ])
        with self.assertRaises(post_x.PublishError):
            post_x.post_tweet("hi", _fake_credentials(), http_opener=opener,
                              sleep_fn=lambda s: None)
        self.assertEqual(len(opener.calls), 3)

    def test_success_missing_data_id_fails(self) -> None:
        opener = _FakeOpener([_FakeResponse(201, b'{"data":{}}')])
        with self.assertRaises(post_x.PublishError):
            post_x.post_tweet("hi", _fake_credentials(), http_opener=opener,
                              sleep_fn=lambda s: None)


class CLIDryRunTests(unittest.TestCase):
    def _write_manifest(self, data: Dict[str, Any]) -> str:
        f = tempfile.NamedTemporaryFile(
            mode="w", encoding="utf-8", suffix=".json", delete=False
        )
        try:
            json.dump(data, f, ensure_ascii=False)
        finally:
            f.close()
        self.addCleanup(os.unlink, f.name)
        return f.name

    def test_dry_run_skips_network_and_credentials(self) -> None:
        path = self._write_manifest(_valid_manifest())
        # Neither X_* env vars set, no credentials, no network — must succeed.
        with mock.patch.dict(os.environ, {}, clear=False):
            for var in post_x._REQUIRED_CREDENTIAL_ENV:
                os.environ.pop(var, None)
            rc = post_x.main([
                "--manifest", path,
                "--pr-number", "4",
                "--pr-url", "https://github.com/sugie/wildlive/pull/4",
                "--dry-run",
            ])
        self.assertEqual(rc, 0)

    def test_post_on_merge_false_is_noop(self) -> None:
        data = _valid_manifest()
        data["post_on_merge"] = False
        path = self._write_manifest(data)
        rc = post_x.main([
            "--manifest", path,
            "--pr-number", "1",
            "--pr-url", "https://github.com/sugie/wildlive/pull/1",
            "--dry-run",
        ])
        self.assertEqual(rc, 0)

    def test_dry_run_over_length_fails_loudly(self) -> None:
        data = _valid_manifest()
        data["ja"] = "あ" * 500  # 500 CJK chars * weight 2 = 1000
        path = self._write_manifest(data)
        with self.assertRaises(SystemExit) as ctx:
            post_x.main([
                "--manifest", path,
                "--pr-number", "1",
                "--pr-url", "https://github.com/sugie/wildlive/pull/1",
                "--dry-run",
            ])
        self.assertEqual(ctx.exception.code, 1)


if __name__ == "__main__":  # pragma: no cover
    unittest.main()
