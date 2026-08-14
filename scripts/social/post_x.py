#!/usr/bin/env python3
"""WildLive X Development Live publisher.

Reads a committed social manifest (docs/social/x/task-*.json), renders a
bilingual post, checks its X twitter-text weighted length, signs the
request with OAuth 1.0a User Context, and calls POST /2/tweets exactly
once. Includes bounded retry, dry-run mode, credential guards, and a
fail-closed default when anything about the environment is off.

Design notes:
- Stdlib only. No third-party HTTP client. No OAuth library. No LLM.
- The AI does not write text at run time. Everything postable was
  authored inside a Pull Request and reviewed there.
- Secrets are read from environment variables and never printed. The
  Authorization header is built per attempt with a fresh nonce and
  timestamp.
- Retries are bounded (max 3) and only fire on 429 / 5xx / transport
  errors. 4xx (other than 429) fails fast.

See docs/adr/0003-x-development-live.md for the reasoning behind every
decision here, and docs/social/x/README.md for operator instructions.
"""

from __future__ import annotations

import argparse
import base64
import hashlib
import hmac
import json
import os
import re
import secrets
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import dataclass
from typing import Any, Callable, Dict, Iterable, Optional, Tuple


TWEET_ENDPOINT = "https://api.x.com/2/tweets"
MAX_WEIGHTED_LENGTH = 280
URL_WEIGHT = 23  # X shortens URLs via t.co (23 as of last publicly-documented setting).
HASHTAG = "#shipaton"
POST_HEADER_PREFIX = "WildLive Dev · "
MAX_RETRIES = 3
BACKOFF_BASE_SECONDS = 2

# Manifest schema versions.
#   v1 — legacy bilingual (Japanese + English body). Retained for
#        historical compatibility with manifests already merged to main
#        (docs/social/x/task-003-*, docs/social/x/task-004-*). Rendering
#        for v1 is identical to before this change was introduced.
#   v2 — English-only. Preferred format for all new manifests. `ja` is
#        forbidden in v2 so a stale bilingual manifest cannot silently
#        be treated as v2.
SCHEMA_VERSION_BILINGUAL = 1
SCHEMA_VERSION_ENGLISH_ONLY = 2
SUPPORTED_SCHEMA_VERSIONS: Tuple[int, ...] = (
    SCHEMA_VERSION_BILINGUAL,
    SCHEMA_VERSION_ENGLISH_ONLY,
)

_URL_RE = re.compile(r"https?://\S+")
_SLUG_RE = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")

# Shared across every schema version.
_COMMON_REQUIRED_KEYS: Tuple[str, ...] = (
    "schema_version",
    "task",
    "slug",
    "post_on_merge",
    "en",
)

# Additional keys required per schema_version.
_REQUIRED_EXTRA_KEYS: Dict[int, Tuple[str, ...]] = {
    SCHEMA_VERSION_BILINGUAL: ("ja",),
    SCHEMA_VERSION_ENGLISH_ONLY: (),
}

# Keys that are forbidden per schema_version (so a stale bilingual
# manifest cannot silently render under a newer version).
_FORBIDDEN_KEYS: Dict[int, Tuple[str, ...]] = {
    SCHEMA_VERSION_BILINGUAL: (),
    SCHEMA_VERSION_ENGLISH_ONLY: ("ja",),
}

_REQUIRED_CREDENTIAL_ENV: Tuple[str, ...] = (
    "X_API_KEY",
    "X_API_KEY_SECRET",
    "X_ACCESS_TOKEN",
    "X_ACCESS_TOKEN_SECRET",
)


# -- Exceptions ---------------------------------------------------------------


class ManifestError(ValueError):
    """Raised for any structural problem with a social manifest."""


class RenderError(ValueError):
    """Raised when the caller-supplied context (PR number, URL) is invalid."""


class LengthError(ValueError):
    """Raised when the rendered post exceeds the X weighted-length cap."""


class ConfigError(RuntimeError):
    """Raised when required environment variables are missing."""


class PublishError(RuntimeError):
    """Raised for HTTP/transport failures once retries are exhausted."""


# -- Credentials --------------------------------------------------------------


@dataclass(frozen=True)
class OAuthCredentials:
    api_key: str
    api_key_secret: str
    access_token: str
    access_token_secret: str

    @classmethod
    def from_env(cls, env: Optional[Dict[str, str]] = None) -> "OAuthCredentials":
        source = env if env is not None else os.environ
        missing = [k for k in _REQUIRED_CREDENTIAL_ENV if not source.get(k)]
        if missing:
            raise ConfigError(
                "missing required credential env vars: " + ", ".join(missing)
            )
        return cls(
            api_key=source["X_API_KEY"],
            api_key_secret=source["X_API_KEY_SECRET"],
            access_token=source["X_ACCESS_TOKEN"],
            access_token_secret=source["X_ACCESS_TOKEN_SECRET"],
        )

    def __repr__(self) -> str:  # never leak secrets in repr / logs
        return "OAuthCredentials(<redacted>)"


# -- Manifest -----------------------------------------------------------------


def load_manifest(path: str) -> Dict[str, Any]:
    """Read and validate a manifest from disk. Raises ManifestError on failure."""
    try:
        with open(path, "r", encoding="utf-8") as fh:
            data = json.load(fh)
    except json.JSONDecodeError as exc:
        raise ManifestError(f"{path}: invalid JSON: {exc}") from exc
    except OSError as exc:
        raise ManifestError(f"{path}: cannot read: {exc}") from exc
    validate_manifest(data, path)
    return data


def validate_manifest(data: Any, path: str = "<manifest>") -> Dict[str, Any]:
    if not isinstance(data, dict):
        raise ManifestError(f"{path}: root must be an object")

    # schema_version comes first — every later check is dispatched on it.
    version = data.get("schema_version")
    if version not in SUPPORTED_SCHEMA_VERSIONS:
        raise ManifestError(
            f"{path}: schema_version must be one of "
            f"{list(SUPPORTED_SCHEMA_VERSIONS)}, got {version!r}"
        )

    required = _COMMON_REQUIRED_KEYS + _REQUIRED_EXTRA_KEYS[version]
    allowed = set(required)  # forbidden keys are explicitly excluded from `allowed`
    missing = [k for k in required if k not in data]
    if missing:
        raise ManifestError(
            f"{path}: schema_version={version} manifest missing keys: "
            f"{', '.join(missing)}"
        )
    forbidden_present = [k for k in _FORBIDDEN_KEYS[version] if k in data]
    if forbidden_present:
        raise ManifestError(
            f"{path}: schema_version={version} manifest must not contain: "
            f"{', '.join(forbidden_present)}"
        )
    unknown = [k for k in data if k not in allowed]
    if unknown:
        raise ManifestError(
            f"{path}: schema_version={version} manifest has unknown keys: "
            f"{', '.join(unknown)}"
        )
    if not isinstance(data["task"], str) or not data["task"].strip():
        raise ManifestError(f"{path}: task must be a non-empty string")
    if not isinstance(data["slug"], str) or not _SLUG_RE.match(data["slug"]):
        raise ManifestError(
            f"{path}: slug must be kebab-case ASCII, got {data['slug']!r}"
        )
    if not isinstance(data["post_on_merge"], bool):
        raise ManifestError(f"{path}: post_on_merge must be a boolean")

    body_langs = ("en",) + (("ja",) if version == SCHEMA_VERSION_BILINGUAL else ())
    for lang in body_langs:
        value = data[lang]
        if not isinstance(value, str) or not value.strip():
            raise ManifestError(f"{path}: {lang} must be a non-empty string")
        if HASHTAG in value:
            raise ManifestError(
                f"{path}: {lang} must not contain '{HASHTAG}' — publisher appends it"
            )
        if "github.com/" in value or "PR #" in value:
            raise ManifestError(
                f"{path}: {lang} must not contain a PR URL or 'PR #' — publisher appends both"
            )
    return data


# -- Rendering ----------------------------------------------------------------


def render_post(manifest: Dict[str, Any], pr_number: int, pr_url: str) -> str:
    if not isinstance(pr_number, int) or pr_number <= 0:
        raise RenderError(f"pr_number must be a positive integer, got {pr_number!r}")
    if not (isinstance(pr_url, str) and pr_url.startswith("https://github.com/")):
        raise RenderError(f"pr_url must start with https://github.com/, got {pr_url!r}")

    version = manifest.get("schema_version")
    header = f"{POST_HEADER_PREFIX}{manifest['task']}"
    trailer = f"PR #{pr_number}\n{pr_url}\n\n{HASHTAG}"

    if version == SCHEMA_VERSION_BILINGUAL:
        # v1 render is intentionally byte-identical to the pre-v2 output so
        # historical manifests (task-003, task-004, …) reproduce exactly.
        return (
            f"{header}\n"
            f"\n"
            f"{manifest['ja'].strip()}\n"
            f"\n"
            f"{manifest['en'].strip()}\n"
            f"\n"
            f"{trailer}"
        )
    if version == SCHEMA_VERSION_ENGLISH_ONLY:
        return (
            f"{header}\n"
            f"\n"
            f"{manifest['en'].strip()}\n"
            f"\n"
            f"{trailer}"
        )
    # validate_manifest rejects unsupported versions before render_post is
    # called, so this branch is a defence-in-depth guard.
    raise RenderError(
        f"unsupported schema_version {version!r}; expected one of "
        f"{list(SUPPORTED_SCHEMA_VERSIONS)}"
    )


def weighted_length(text: str) -> int:
    """Conservative approximation of X's twitter-text weighted length.

    Rules:
      - URLs are counted as a fixed URL_WEIGHT (regardless of literal length).
      - Each remaining codepoint contributes 1 (Latin-ish ranges) or 2 (CJK,
        emoji, most non-Latin scripts).

    The result is the total weighted length; the platform limit is 280.
    """
    total = 0
    total += len(_URL_RE.findall(text)) * URL_WEIGHT
    text_without_urls = _URL_RE.sub("", text)
    for ch in text_without_urls:
        cp = ord(ch)
        if cp < 4352:
            total += 1
        elif 8192 <= cp <= 8205:
            total += 1
        elif 8208 <= cp <= 8223:
            total += 1
        elif 8242 <= cp <= 8247:
            total += 1
        else:
            total += 2
    return total


def validate_length(text: str, maximum: int = MAX_WEIGHTED_LENGTH) -> int:
    wl = weighted_length(text)
    if wl > maximum:
        raise LengthError(
            f"rendered post is {wl} weighted chars, exceeds cap of {maximum}"
        )
    return wl


# -- OAuth 1.0a signing -------------------------------------------------------


def _percent_encode(value: Any) -> str:
    """RFC 3986 percent-encode; only A-Z a-z 0-9 - _ . ~ pass through."""
    return urllib.parse.quote(str(value), safe="-_.~")


def build_oauth_header(
    method: str,
    url: str,
    credentials: OAuthCredentials,
    oauth_params: Dict[str, str],
    extra_params: Optional[Iterable[Tuple[str, str]]] = None,
) -> str:
    """Return the value of an OAuth 1.0a Authorization header.

    For a JSON body, pass `extra_params=None` — X's OAuth 1.0a signing base
    string covers OAuth params + URL query params only when the body is
    application/json.

    The returned string is safe to log — it contains the public API key,
    the access token (public), and the signature. It does NOT contain either
    secret; those live only in the signing key.
    """
    method_upper = method.upper()
    parsed = urllib.parse.urlsplit(url)
    base_url = urllib.parse.urlunsplit(
        (parsed.scheme.lower(), parsed.netloc.lower(), parsed.path, "", "")
    )
    query_params = urllib.parse.parse_qsl(parsed.query, keep_blank_values=True)

    all_params: list = []
    all_params.extend(oauth_params.items())
    all_params.extend(query_params)
    if extra_params:
        all_params.extend(extra_params)

    encoded_pairs = sorted(
        (_percent_encode(k), _percent_encode(v)) for k, v in all_params
    )
    param_string = "&".join(f"{k}={v}" for k, v in encoded_pairs)

    base_string = "&".join(
        [
            method_upper,
            _percent_encode(base_url),
            _percent_encode(param_string),
        ]
    )
    signing_key = (
        f"{_percent_encode(credentials.api_key_secret)}"
        f"&{_percent_encode(credentials.access_token_secret)}"
    )
    signature = hmac.new(
        signing_key.encode("utf-8"),
        base_string.encode("utf-8"),
        hashlib.sha1,
    ).digest()
    signature_b64 = base64.b64encode(signature).decode("ascii")

    header_params = dict(oauth_params)
    header_params["oauth_signature"] = signature_b64
    header_body = ", ".join(
        f'{_percent_encode(k)}="{_percent_encode(v)}"'
        for k, v in sorted(header_params.items())
    )
    return "OAuth " + header_body


def build_oauth_params(
    credentials: OAuthCredentials,
    nonce: Optional[str] = None,
    timestamp: Optional[str] = None,
) -> Dict[str, str]:
    return {
        "oauth_consumer_key": credentials.api_key,
        "oauth_nonce": nonce if nonce is not None else secrets.token_hex(16),
        "oauth_signature_method": "HMAC-SHA1",
        "oauth_timestamp": timestamp if timestamp is not None else str(int(time.time())),
        "oauth_token": credentials.access_token,
        "oauth_version": "1.0",
    }


# -- HTTP transport -----------------------------------------------------------


def _default_sleep(seconds: float) -> None:  # pragma: no cover
    time.sleep(seconds)


def post_tweet(
    text: str,
    credentials: OAuthCredentials,
    http_opener: Optional[Any] = None,
    sleep_fn: Optional[Callable[[float], None]] = None,
    max_retries: int = MAX_RETRIES,
) -> Tuple[str, str, int]:
    """POST /2/tweets with bounded retry. Returns (post_id, post_url, status).

    Retries only on 429, 5xx, and transport errors, up to `max_retries`
    attempts. 4xx (other than 429) fails immediately. Never logs secrets.
    """
    opener = http_opener or urllib.request.build_opener()
    sleep = sleep_fn or _default_sleep

    body = json.dumps({"text": text}, ensure_ascii=False).encode("utf-8")

    last_status: Optional[int] = None
    last_snippet: Optional[str] = None
    attempts_made = 0

    for attempt in range(1, max_retries + 1):
        attempts_made = attempt
        oauth_params = build_oauth_params(credentials)
        auth_header = build_oauth_header(
            "POST", TWEET_ENDPOINT, credentials, oauth_params
        )
        req = urllib.request.Request(
            TWEET_ENDPOINT,
            data=body,
            method="POST",
            headers={
                "Authorization": auth_header,
                "Content-Type": "application/json; charset=utf-8",
                "User-Agent": "wildlive-x-devlive/1.0 (+https://github.com/sugie/wildlive)",
                "Accept": "application/json",
            },
        )
        try:
            with opener.open(req, timeout=30) as resp:
                status = getattr(resp, "status", None) or resp.getcode()
                data = resp.read()
                if status in (200, 201):
                    return _parse_created_response(data, status)
                last_status = status
                last_snippet = _safe_snippet(data)
                # Unusual non-201/200 success — do not retry, fail loud.
                break
        except urllib.error.HTTPError as exc:
            status = exc.code
            try:
                data = exc.read()
            except Exception:  # noqa: BLE001
                data = b""
            last_status = status
            last_snippet = _safe_snippet(data)
            if status == 429 or 500 <= status < 600:
                if attempt < max_retries:
                    sleep(BACKOFF_BASE_SECONDS * attempt)
                    continue
                break
            # Any other 4xx: fail fast — retrying will not help.
            break
        except urllib.error.URLError as exc:
            last_status = 0
            last_snippet = f"transport error: {type(exc).__name__}"
            if attempt < max_retries:
                sleep(BACKOFF_BASE_SECONDS * attempt)
                continue
            break

    raise PublishError(
        f"POST /2/tweets failed after {attempts_made} attempt(s): "
        f"status={last_status}, body_snippet={last_snippet!r}"
    )


def _parse_created_response(data: bytes, status: int) -> Tuple[str, str, int]:
    try:
        payload = json.loads(data.decode("utf-8"))
    except (ValueError, UnicodeDecodeError) as exc:
        raise PublishError(f"unparseable success body: {exc}") from exc
    inner = payload.get("data") if isinstance(payload, dict) else None
    post_id = None
    if isinstance(inner, dict):
        post_id = inner.get("id")
    if not post_id:
        raise PublishError(
            f"success response missing data.id: {_safe_snippet(data)!r}"
        )
    return str(post_id), f"https://x.com/i/status/{post_id}", int(status)


def _safe_snippet(data: bytes, limit: int = 200) -> str:
    """Return a bounded, single-line string representation of a response body."""
    try:
        text = data.decode("utf-8", errors="replace")
    except Exception:  # noqa: BLE001
        return f"<{len(data)} bytes>"
    text = text.replace("\n", " ").replace("\r", " ")
    return text[:limit]


# -- CLI ----------------------------------------------------------------------


def _fail(msg: str) -> None:
    print(msg, file=sys.stderr)
    sys.exit(1)


def _build_arg_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="post_x.py",
        description="WildLive X development-live publisher (stdlib-only).",
    )
    parser.add_argument(
        "--manifest",
        required=True,
        help="Path to docs/social/x/task-*.json manifest.",
    )
    parser.add_argument(
        "--pr-number",
        required=True,
        type=int,
        help="Merged Pull Request number.",
    )
    parser.add_argument(
        "--pr-url",
        required=True,
        help="Merged Pull Request URL (must be a github.com URL).",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Validate + render + length-check only. Do NOT call the X API.",
    )
    return parser


def main(argv: Optional[list] = None) -> int:
    args = _build_arg_parser().parse_args(argv)

    try:
        manifest = load_manifest(args.manifest)
    except ManifestError as exc:
        _fail(f"manifest error: {exc}")
        return 1  # pragma: no cover — _fail exits

    if not manifest["post_on_merge"]:
        print(f"post_on_merge=false — skip (manifest: {args.manifest})")
        return 0

    try:
        text = render_post(manifest, args.pr_number, args.pr_url)
    except RenderError as exc:
        _fail(f"render error: {exc}")
        return 1  # pragma: no cover

    try:
        wl = validate_length(text)
    except LengthError as exc:
        _fail(f"length error: {exc}")
        return 1  # pragma: no cover

    print(f"--- rendered post ({wl} weighted chars, cap {MAX_WEIGHTED_LENGTH}) ---")
    print(text)
    print("--- end rendered post ---")

    if args.dry_run:
        print("dry-run: not calling X API")
        return 0

    try:
        credentials = OAuthCredentials.from_env()
    except ConfigError as exc:
        _fail(f"config error: {exc}")
        return 1  # pragma: no cover

    try:
        post_id, post_url, status = post_tweet(text, credentials)
    except PublishError as exc:
        _fail(f"publish error: {exc}")
        return 1  # pragma: no cover

    print(f"posted: id={post_id} status={status} url={post_url}")
    return 0


if __name__ == "__main__":  # pragma: no cover
    sys.exit(main())
