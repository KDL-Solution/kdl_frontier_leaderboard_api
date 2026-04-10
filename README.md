# KDL Frontier Leaderboard API Client

This repository contains the API client and VLMEvalKit runner for evaluating KDL Frontier on OCRBench_v2.

## API

```text
API base: http://leaderboard.koreadeep.com
Chat endpoint: http://leaderboard.koreadeep.com/v1/chat/completions
Model: KDL Frontier
Authentication: Authorization: Bearer <issued-token>
```

The API is OpenAI-compatible for multimodal chat-completions requests.

## Repository Structure

```text
.
├── VLMEvalKit/        Official VLMEvalKit source as a git submodule
├── vlmevalkit/        KDL runner scripts and config template
├── health_check.py    API health, model, and limits check
├── chat_test.py       Single image-question request client
├── health_check.sh    Shell wrapper for health_check.py
├── run_test.sh        Shell wrapper for chat_test.py
└── .env.example       Environment template
```

## Clone

Clone with the VLMEvalKit submodule included:

```bash
git clone --recursive https://github.com/KDL-Solution/kdl_frontier_leaderboard_api.git
cd kdl_frontier_leaderboard_api
```

If the repository was cloned without submodules:

```bash
git submodule update --init --recursive
```

## Configure

```bash
cp .env.example .env
vi .env
```

Set the issued API token:

```env
DEEPFLOW_API_BASE=http://leaderboard.koreadeep.com
DEEPFLOW_API_KEY=<issued-token>
DEEPFLOW_MODEL="KDL Frontier"
```

The API key is not included in this repository. Send or store it separately.

## Health Check

```bash
bash health_check.sh
```

This checks:

- `GET /api/v1/live`
- `GET /v1/models`
- `GET /v1/limits`

## Single Request Test

Set `TEST_IMAGE` and `TEST_QUESTION` in `.env`, then run:

```bash
bash run_test.sh
```

Or call the Python client directly:

```bash
python chat_test.py \
  --image /path/to/test.jpg \
  --question "What is written in the image?"
```

## OCRBench_v2 with VLMEvalKit

Run the full OCRBench_v2 evaluation:

```bash
MAX_SAMPLES=0 MODE=all NPROC=10 bash vlmevalkit/run_vlmevalkit.sh
```

Run a small smoke test:

```bash
MAX_SAMPLES=5 MODE=infer NPROC=4 bash vlmevalkit/run_vlmevalkit.sh
```

The runner uses the root `VLMEvalKit/` submodule by default. To use another VLMEvalKit checkout:

```bash
VLMEVALKIT_DIR=/path/to/VLMEvalKit MAX_SAMPLES=0 MODE=all NPROC=10 bash vlmevalkit/run_vlmevalkit.sh
```

## Minimal curl Example

```bash
curl -X POST "http://leaderboard.koreadeep.com/v1/chat/completions" \
  -H "Authorization: Bearer <issued-token>" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "KDL Frontier",
    "stream": false,
    "messages": [
      {
        "role": "user",
        "content": [
          {"type": "text", "text": "What is written in the image?"},
          {"type": "image_url", "image_url": {"url": "data:image/jpeg;base64,<base64-image>"}}
        ]
      }
    ]
  }'
```

## Request Limits

```bash
curl http://leaderboard.koreadeep.com/v1/limits
```

The public API uses queue-based overflow handling. For stable throughput, keep `NPROC` at or below `max_concurrent_requests_per_token`.

## Results

VLMEvalKit outputs are written under:

```text
vlmevalkit/results/
```

Result files are intentionally ignored by git. Send evaluation outputs separately if needed.
