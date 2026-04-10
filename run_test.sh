#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$ROOT_DIR/.env"
if [ -f "$ENV_FILE" ]; then
  set -a
  source "$ENV_FILE"
  set +a
else
  set -a
  source "$ROOT_DIR/.env.example"
  set +a
fi

python "$ROOT_DIR/health_check.py"
python "$ROOT_DIR/chat_test.py"
