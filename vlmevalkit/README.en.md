# VLMEvalKit OCRBench_v2 Runner for KDL Frontier

This directory contains the runnable VLMEvalKit example for leaderboard evaluation.
It does not require patching VLMEvalKit. The script generates a `run.py --config` file that uses VLMEvalKit's OpenAI-compatible `GPT4V` wrapper.

## Configure API Access

Create `.env` in the repository root:

```bash
cp .env.example .env
```

Required values:

```env
DEEPFLOW_API_BASE=http://leaderboard.koreadeep.com
DEEPFLOW_API_KEY=<issued-token>
DEEPFLOW_MODEL="KDL Frontier"
```

## Prerequisites

- Python environment that can run VLMEvalKit.
- VLMEvalKit source directory from the included submodule. Default path: `VLMEvalKit`
- Network access to `http://leaderboard.koreadeep.com`

Initialize the included VLMEvalKit submodule after cloning this repository:

```bash
git submodule update --init --recursive
```

Or clone this repository with submodules:

```bash
git clone --recursive https://github.com/KDL-Solution/kdl_frontier_leaderboard_api.git
```

Override the VLMEvalKit path only if needed:

```bash
VLMEVALKIT_DIR=/path/to/VLMEvalKit bash vlmevalkit/run_vlmevalkit.sh
```

## Smoke Test

The default run sends 5 OCRBench_v2 samples in inference-only mode:

```bash
bash vlmevalkit/run_vlmevalkit.sh
```

This is intended to verify API connectivity and output generation.

## Full OCRBench_v2 Evaluation

```bash
MAX_SAMPLES=0 MODE=all NPROC=10 bash vlmevalkit/run_vlmevalkit.sh
```

Parameter meaning:

- `MAX_SAMPLES=0`: run the full OCRBench_v2 dataset.
- `MODE=all`: run inference and evaluation.
- `NPROC=10`: send up to 10 concurrent API requests.

Before increasing `NPROC`, check:

```bash
curl http://leaderboard.koreadeep.com/v1/limits
```

The API uses queue-based overflow handling. Requests above the reported concurrency
limit wait in the server queue. For reproducible throughput, keep `NPROC` at or below
`max_concurrent_requests_per_token`.

## Output

Default output directory:

```text
vlmevalkit/results/KDL Frontier
```

Generated VLMEvalKit config:

```text
vlmevalkit/generated/kdl_frontier_ocrbench_v2_config.json
```

## Package Results

After evaluation:

```bash
bash vlmevalkit/package_results.sh
```

The package is written to:

```text
vlmevalkit/submission/
```

The zip includes:

- VLMEvalKit outputs
- generated manifest
- English and Chinese instructions
- executable client scripts
- config template

The API key is not included in the zip and must be provided separately.
