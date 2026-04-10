#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import sys
import urllib.error
import urllib.request


def _env(name: str, default: str) -> str:
    return os.environ.get(name, default).strip() or default


def _headers(api_key: str | None = None) -> dict[str, str]:
    headers = {"accept": "application/json"}
    if api_key:
        headers["authorization"] = f"Bearer {api_key}"
    return headers


def _get_json(url: str, *, api_key: str | None = None, timeout: float = 10.0) -> dict:
    req = urllib.request.Request(url, headers=_headers(api_key), method="GET")
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        raw = resp.read().decode("utf-8")
        return json.loads(raw) if raw else {}


def _check(label: str, url: str, *, api_key: str | None = None, timeout: float = 10.0) -> bool:
    try:
        payload = _get_json(url, api_key=api_key, timeout=timeout)
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")
        print(f"[FAIL] {label}: HTTP {exc.code} {body}", file=sys.stderr)
        return False
    except Exception as exc:
        print(f"[FAIL] {label}: {exc}", file=sys.stderr)
        return False

    print(f"[ OK ] {label}: {json.dumps(payload, ensure_ascii=False)}")
    return True


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base-url", default=_env("DEEPFLOW_API_BASE", "http://leaderboard.koreadeep.com"))
    parser.add_argument("--api-key", default=os.environ.get("DEEPFLOW_API_KEY", ""))
    parser.add_argument("--timeout", type=float, default=10.0)
    parser.add_argument("--full", action="store_true", help="also call /api/v1/health")
    args = parser.parse_args()

    base_url = args.base_url.rstrip("/")
    ok = True
    ok &= _check("live", f"{base_url}/api/v1/live", timeout=args.timeout)
    ok &= _check("models", f"{base_url}/v1/models", timeout=args.timeout)
    ok &= _check("limits", f"{base_url}/v1/limits", timeout=args.timeout)
    if args.full:
        ok &= _check(
            "backend-health",
            f"{base_url}/api/v1/health",
            api_key=args.api_key,
            timeout=args.timeout,
        )
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
