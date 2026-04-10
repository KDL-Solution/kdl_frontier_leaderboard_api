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

DEFAULT_VLMEVALKIT_DIR="$CLIENT_DIR/VLMEvalKit"
VLMEVALKIT_DIR="${VLMEVALKIT_DIR:-$DEFAULT_VLMEVALKIT_DIR}"
REQUIREMENTS_FILE="$VLMEVAL_CLIENT_DIR/requirements.txt"
PYTHON_BIN="${PYTHON_BIN:-$(command -v python3 || command -v python)}"

DEEPFLOW_API_BASE="${DEEPFLOW_API_BASE:-http://leaderboard.koreadeep.com}"
DEEPFLOW_MODEL="${DEEPFLOW_MODEL:-KDL Frontier}"
DEEPFLOW_API_KEY="${DEEPFLOW_API_KEY:-}"
OPENAI_API_BASE="${OPENAI_API_BASE:-${DEEPFLOW_API_BASE%/}/v1/chat/completions}"
WORK_DIR="${WORK_DIR:-$VLMEVAL_CLIENT_DIR/results}"
MAX_SAMPLES="${MAX_SAMPLES:-5}"
NPROC="${NPROC:-4}"
if [ -z "${MODE:-}" ]; then
  if [ "$MAX_SAMPLES" -gt 0 ]; then
    MODE="infer"
  else
    MODE="all"
  fi
fi
DRY_RUN="${DRY_RUN:-0}"

if [ -z "$DEEPFLOW_API_KEY" ]; then
  echo "DEEPFLOW_API_KEY is required. Set it in .env." >&2
  exit 2
fi
if [ ! -d "$VLMEVALKIT_DIR" ]; then
  echo "VLMEVALKIT_DIR not found: $VLMEVALKIT_DIR" >&2
  echo "Run: git submodule update --init --recursive" >&2
  exit 2
fi

CREATED_VLMEVALKIT_ENV=0
if [ ! -f "$VLMEVALKIT_DIR/.env" ]; then
  if touch "$VLMEVALKIT_DIR/.env" 2>/dev/null; then
    CREATED_VLMEVALKIT_ENV=1
  fi
fi

cleanup() {
  if [ "$CREATED_VLMEVALKIT_ENV" = "1" ]; then
    rm -f "$VLMEVALKIT_DIR/.env"
  fi
}
trap cleanup EXIT

if [ "${SKIP_VLMEVALKIT_PREFLIGHT:-0}" != "1" ]; then
  if ! "$PYTHON_BIN" - "$REQUIREMENTS_FILE" <<'PY'
import importlib.util
import sys
from importlib.metadata import PackageNotFoundError, version

requirements_file = sys.argv[1]
required = {
    "dotenv": "python-dotenv",
    "num2words": "num2words",
    "openai": "openai",
    "validators": "validators",
}
missing = [package for module, package in required.items() if importlib.util.find_spec(module) is None]
version_errors = []

try:
    hf_version = version("huggingface-hub")
except PackageNotFoundError:
    missing.append("huggingface-hub>=0.34.0,<1.0")
else:
    major = hf_version.split(".", 1)[0]
    if major.isdigit() and int(major) >= 1:
        version_errors.append(
            f"huggingface-hub=={hf_version} is incompatible with transformers; required >=0.34.0,<1.0"
        )

try:
    import transformers  # noqa: F401
except Exception as exc:
    version_errors.append(f"transformers import failed: {exc}")

if missing or version_errors:
    if missing:
        print("Missing Python packages for VLMEvalKit: " + ", ".join(missing), file=sys.stderr)
    if version_errors:
        print("Python dependency conflicts for VLMEvalKit:", file=sys.stderr)
        for error in version_errors:
            print(f"  - {error}", file=sys.stderr)
    print("Install dependencies with:", file=sys.stderr)
    print(f"  {sys.executable} -m pip install -r {requirements_file}", file=sys.stderr)
    sys.exit(2)
PY
  then
    exit 2
  fi
fi

GENERATED_DIR="$VLMEVAL_CLIENT_DIR/generated"
CONFIG_FILE="$GENERATED_DIR/kdl_frontier_ocrbench_v2_config.json"
mkdir -p "$GENERATED_DIR" "$WORK_DIR"

TEMPLATE_FILE="$VLMEVAL_CLIENT_DIR/config.kdl_frontier_ocrbench_v2.json.template" \
CONFIG_FILE="$CONFIG_FILE" \
MODEL_NAME="$DEEPFLOW_MODEL" \
API_BASE="$OPENAI_API_BASE" \
API_KEY="$DEEPFLOW_API_KEY" \
"$PYTHON_BIN" - <<'PY'
import json
import os
from pathlib import Path

template = Path(os.environ["TEMPLATE_FILE"]).read_text(encoding="utf-8")
rendered = (
    template
    .replace("__MODEL_NAME__", os.environ["MODEL_NAME"])
    .replace("__API_BASE__", os.environ["API_BASE"])
    .replace("__API_KEY__", os.environ["API_KEY"])
)
payload = json.loads(rendered)
Path(os.environ["CONFIG_FILE"]).write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)
PY

echo "=========================================="
echo "  VLMEvalKit - KDL Frontier OCRBench_v2"
echo "=========================================="
echo "  VLMEVALKIT_DIR : $VLMEVALKIT_DIR"
echo "  API_BASE       : $OPENAI_API_BASE"
echo "  MODEL          : $DEEPFLOW_MODEL"
echo "  DATA           : OCRBench_v2"
echo "  WORK_DIR       : $WORK_DIR"
echo "  MAX_SAMPLES    : $MAX_SAMPLES"
echo "  NPROC          : $NPROC"
echo "  MODE           : $MODE"
echo "  DRY_RUN        : $DRY_RUN"
echo "=========================================="

echo "[1/2] Health check"
"$PYTHON_BIN" "$CLIENT_DIR/health_check.py" --base-url "$DEEPFLOW_API_BASE"

ARGS=(
  run.py
  --config "$CONFIG_FILE"
  --work-dir "$WORK_DIR"
  --api-nproc "$NPROC"
  --mode "$MODE"
)
if [ "$MAX_SAMPLES" -gt 0 ]; then
  ARGS+=(--max-samples "$MAX_SAMPLES")
fi

if [ "$DRY_RUN" = "1" ]; then
  echo "[dry-run] Generated config: $CONFIG_FILE"
  printf '[dry-run] Command:'
  printf ' %q' "$PYTHON_BIN" "${ARGS[@]}"
  printf '\n'
  exit 0
fi

echo "[2/2] VLMEvalKit run"
cd "$VLMEVALKIT_DIR"
PYTHONNOUSERSITE=1 "$PYTHON_BIN" "${ARGS[@]}"

echo ""
echo "Done. Results are under: $WORK_DIR/$DEEPFLOW_MODEL"
