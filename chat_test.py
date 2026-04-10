#!/usr/bin/env python3
from __future__ import annotations

import argparse
import base64
import json
import mimetypes
import os
from pathlib import Path
import sys
import urllib.error
import urllib.request


def _env(name: str, default: str) -> str:
    return os.environ.get(name, default).strip() or default


def _image_to_url(image: str) -> str:
    if image.startswith(("http://", "https://", "data:")):
        return image

    path = Path(image)
    if not path.exists():
        raise FileNotFoundError(f"image not found: {path}")
    mime = mimetypes.guess_type(path.name)[0] or "image/jpeg"
    b64 = base64.b64encode(path.read_bytes()).decode("ascii")
    return f"data:{mime};base64,{b64}"


def _post_json(url: str, payload: dict, *, api_key: str, timeout: float) -> dict:
    headers = {
        "content-type": "application/json",
        "accept": "application/json",
        "authorization": f"Bearer {api_key}",
    }
    req = urllib.request.Request(
        url,
        data=json.dumps(payload, ensure_ascii=False).encode("utf-8"),
        headers=headers,
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return json.loads(resp.read().decode("utf-8"))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base-url", default=_env("DEEPFLOW_API_BASE", "http://leaderboard.koreadeep.com"))
    parser.add_argument("--api-key", default=_env("DEEPFLOW_API_KEY", ""))
    parser.add_argument("--model", default=_env("DEEPFLOW_MODEL", "KDL Frontier"))
    parser.add_argument("--image", default=os.environ.get("TEST_IMAGE", ""))
    parser.add_argument("--question", default=_env("TEST_QUESTION", "What is written in the image?"))
    parser.add_argument("--timeout", type=float, default=180.0)
    parser.add_argument("--raw", action="store_true")
    args = parser.parse_args()

    if not args.api_key:
        print("Set DEEPFLOW_API_KEY in .env or pass --api-key.", file=sys.stderr)
        return 2

    if not args.image or args.image == "/path/to/test.jpg":
        print("Set TEST_IMAGE in .env or pass --image.", file=sys.stderr)
        return 2

    endpoint = f"{args.base_url.rstrip('/')}/v1/chat/completions"
    payload = {
        "model": args.model,
        "stream": False,
        "messages": [
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": args.question},
                    {"type": "image_url", "image_url": {"url": _image_to_url(args.image)}},
                ],
            }
        ],
    }

    try:
        response = _post_json(endpoint, payload, api_key=args.api_key, timeout=args.timeout)
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")
        print(f"HTTP {exc.code}: {body}", file=sys.stderr)
        return 1
    except Exception as exc:
        print(f"request failed: {exc}", file=sys.stderr)
        return 1

    if args.raw:
        print(json.dumps(response, ensure_ascii=False, indent=2))
        return 0

    answer = response.get("choices", [{}])[0].get("message", {}).get("content", "")
    usage = response.get("usage", {})
    print("answer:")
    print(answer)
    print("")
    print("usage:")
    print(json.dumps(usage, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
