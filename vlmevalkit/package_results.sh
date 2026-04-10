#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLIENT_DIR="$ROOT_DIR"
VLMEVAL_CLIENT_DIR="$CLIENT_DIR/vlmevalkit"
ENV_FILE="$CLIENT_DIR/.env"

if [ -f "$ENV_FILE" ]; then
  set -a
  source "$ENV_FILE"
  set +a
fi

DEFAULT_PLAY_PYTHON="/home/ian/anaconda3/envs/play/bin/python"
if [ -x "$DEFAULT_PLAY_PYTHON" ]; then
  PYTHON_BIN="${PYTHON_BIN:-$DEFAULT_PLAY_PYTHON}"
else
  PYTHON_BIN="${PYTHON_BIN:-$(command -v python3 || command -v python)}"
fi

DEEPFLOW_API_BASE="${DEEPFLOW_API_BASE:-http://leaderboard.koreadeep.com}"
DEEPFLOW_MODEL="${DEEPFLOW_MODEL:-KDL Frontier}"
WORK_DIR="${WORK_DIR:-$VLMEVAL_CLIENT_DIR/results}"
SUBMISSION_DIR="${SUBMISSION_DIR:-$VLMEVAL_CLIENT_DIR/submission}"
STAMP="$(date +%Y%m%d_%H%M%S)"
SAFE_MODEL_NAME="${DEEPFLOW_MODEL// /_}"
ZIP_PATH="$SUBMISSION_DIR/${SAFE_MODEL_NAME}_ocrbench_v2_vlmevalkit_${STAMP}.zip"

mkdir -p "$SUBMISSION_DIR"

ROOT_DIR="$ROOT_DIR" \
CLIENT_DIR="$CLIENT_DIR" \
VLMEVAL_CLIENT_DIR="$VLMEVAL_CLIENT_DIR" \
WORK_DIR="$WORK_DIR" \
ZIP_PATH="$ZIP_PATH" \
DEEPFLOW_API_BASE="$DEEPFLOW_API_BASE" \
DEEPFLOW_MODEL="$DEEPFLOW_MODEL" \
"$PYTHON_BIN" - <<'PY'
import json
import os
from datetime import datetime, timezone
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile

root_dir = Path(os.environ["ROOT_DIR"]).resolve()
client_dir = Path(os.environ["CLIENT_DIR"]).resolve()
vlmeval_client_dir = Path(os.environ["VLMEVAL_CLIENT_DIR"]).resolve()
work_dir = Path(os.environ["WORK_DIR"]).resolve()
zip_path = Path(os.environ["ZIP_PATH"]).resolve()
model = os.environ["DEEPFLOW_MODEL"]
api_base = os.environ["DEEPFLOW_API_BASE"]

manifest = {
    "model": model,
    "api_base": api_base,
    "openai_api_base": api_base.rstrip("/") + "/v1/chat/completions",
    "dataset": "OCRBench_v2",
    "created_at": datetime.now(timezone.utc).isoformat(),
    "note": "API key is intentionally not included. Provide it separately.",
    "recommended_command": "MAX_SAMPLES=0 MODE=all NPROC=10 bash vlmevalkit/run_vlmevalkit.sh",
    "health_check_command": "bash health_check.sh",
}

with ZipFile(zip_path, "w", compression=ZIP_DEFLATED) as zf:
    zf.writestr("submission_manifest.json", json.dumps(manifest, ensure_ascii=False, indent=2) + "\n")

    for path in [
        client_dir / ".env.example",
        client_dir / "README.md",
        client_dir / "README.en.md",
        client_dir / "README.zh.md",
        client_dir / "SUBMISSION_GUIDE.en.md",
        client_dir / "SUBMISSION_GUIDE.zh.md",
        client_dir / "health_check.py",
        client_dir / "health_check.sh",
        client_dir / "chat_test.py",
        client_dir / "run_test.sh",
        vlmeval_client_dir / "README.md",
        vlmeval_client_dir / "README.en.md",
        vlmeval_client_dir / "README.zh.md",
        vlmeval_client_dir / "config.kdl_frontier_ocrbench_v2.json.template",
        vlmeval_client_dir / "run_vlmevalkit.sh",
        vlmeval_client_dir / "package_results.sh",
    ]:
        if path.exists():
            zf.write(path, path.relative_to(root_dir))

    if work_dir.exists():
        for path in sorted(work_dir.rglob("*")):
            if path.is_file():
                if any(part.startswith("bak_") for part in path.parts):
                    continue
                zf.write(path, path.relative_to(root_dir))

print(zip_path)
PY

echo "Submission package: $ZIP_PATH"
