# KDL Frontier API Handoff Guide

This guide summarizes what the leaderboard operator needs to run OCRBench_v2
against KDL Frontier through the public API.

## Endpoint

```text
API base: http://leaderboard.koreadeep.com
Chat completions: http://leaderboard.koreadeep.com/v1/chat/completions
Model: KDL Frontier
Authentication: Authorization: Bearer <issued-token>
```

The API is OpenAI-compatible for multimodal chat-completions requests.

## Files To Provide

Provide this repository folder or the zip created by:

```bash
bash vlmevalkit/package_results.sh
```

The package includes:

- Health check and single-request test clients.
- VLMEvalKit OCRBench_v2 runner.
- VLMEvalKit config template.
- README files in English and Chinese.
- Existing evaluation outputs, if present.

The API key is intentionally not included in the package. Send the issued token
through a separate secure channel.

## Required Setup

```bash
cp .env.example .env
vi .env
```

Set:

```env
DEEPFLOW_API_BASE=http://leaderboard.koreadeep.com
DEEPFLOW_API_KEY=<issued-token>
DEEPFLOW_MODEL="KDL Frontier"
```

## Health Check

```bash
bash health_check.sh
```

Expected checks:

- `GET /api/v1/live`
- `GET /v1/models`
- `GET /v1/limits`

## Single Sample Test

```bash
python chat_test.py \
  --image /path/to/test.jpg \
  --question "What is written in the image?"
```

## VLMEvalKit OCRBench_v2

The runner does not require modifying VLMEvalKit. It generates a temporary
`run.py --config` file that uses VLMEvalKit's OpenAI-compatible `GPT4V` wrapper.

```bash
VLMEVALKIT_DIR=/path/to/VLMEvalKit \
MAX_SAMPLES=0 \
MODE=all \
NPROC=10 \
bash vlmevalkit/run_vlmevalkit.sh
```

For a smoke test:

```bash
MAX_SAMPLES=5 MODE=infer NPROC=4 bash vlmevalkit/run_vlmevalkit.sh
```

## Operational Notes

- The API accepts one image per request for this OCRBench_v2 pipeline.
- Public overflow handling is queue-based. Use `GET /v1/limits` to check the current concurrency limit.
- Recommended VLMEvalKit concurrency is `NPROC=10`.
- Server-side audit logs are maintained internally by Korea Deep Learning Inc.
- Do not include the API key in result archives or public issue trackers.
