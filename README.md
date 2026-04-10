# KDL Frontier Leaderboard API Client

## English

This repository provides the API client and VLMEvalKit runner for evaluating KDL Frontier on OCRBench_v2 through the public API.

### API

```text
API base: http://leaderboard.koreadeep.com
Chat endpoint: http://leaderboard.koreadeep.com/v1/chat/completions
Model: KDL Frontier
Authentication: Authorization: Bearer <issued-token>
```

The API is compatible with OpenAI-style multimodal chat completions.
Only non-streaming requests are supported. Set `"stream": false` or omit the `stream` field.
The leaderboard evaluation endpoint is `/v1/chat/completions`.

### Repository Structure

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

### Clone

Clone this repository with the VLMEvalKit submodule included:

```bash
git clone --recursive https://github.com/KDL-Solution/kdl_frontier_leaderboard_api.git
cd kdl_frontier_leaderboard_api
```

If the repository was cloned without submodules:

```bash
git submodule update --init --recursive
```

### Configure

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

### Health Check

```bash
bash health_check.sh
```

This checks:

- `GET /api/v1/live`
- `GET /v1/models`
- `GET /v1/limits`

### Single Request Test

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

### OCRBench_v2 with VLMEvalKit

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

### Minimal curl Example

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

### Request Limits

```bash
curl http://leaderboard.koreadeep.com/v1/limits
```

The public API applies queue-based overflow handling to `/v1/chat/completions`.
For stable throughput, keep `NPROC` at or below `max_concurrent_requests_per_token`.
The `limited_paths` value returned by `/v1/limits` should contain only `/v1/chat/completions`.

### Results

VLMEvalKit outputs are written under:

```text
vlmevalkit/results/
```

Result files are intentionally ignored by git. Send evaluation outputs separately if needed.

## 中文

此仓库提供通过公开 API 在 OCRBench_v2 上评测 KDL Frontier 所需的 API 客户端和 VLMEvalKit 运行脚本。

### API 信息

```text
API base: http://leaderboard.koreadeep.com
Chat endpoint: http://leaderboard.koreadeep.com/v1/chat/completions
Model: KDL Frontier
Authentication: Authorization: Bearer <issued-token>
```

该 API 兼容 OpenAI 风格的多模态 chat completions 请求格式。
仅支持非流式请求。请设置 `"stream": false`，或省略 `stream` 字段。
排行榜评测接口为 `/v1/chat/completions`。

### 仓库结构

```text
.
├── VLMEvalKit/        官方 VLMEvalKit 源码，以 git submodule 方式提供
├── vlmevalkit/        KDL 运行脚本和配置模板
├── health_check.py    API 健康检查、模型信息和限制检查
├── chat_test.py       单张图片问答请求客户端
├── health_check.sh    health_check.py 的 shell 封装
├── run_test.sh        chat_test.py 的 shell 封装
└── .env.example       环境变量模板
```

### 克隆仓库

请带 submodule 克隆仓库：

```bash
git clone --recursive https://github.com/KDL-Solution/kdl_frontier_leaderboard_api.git
cd kdl_frontier_leaderboard_api
```

如果已经未带 submodule 克隆仓库：

```bash
git submodule update --init --recursive
```

### 配置

```bash
cp .env.example .env
vi .env
```

填写分配的 API token：

```env
DEEPFLOW_API_BASE=http://leaderboard.koreadeep.com
DEEPFLOW_API_KEY=<issued-token>
DEEPFLOW_MODEL="KDL Frontier"
```

API key 不包含在此仓库中。请通过单独的安全渠道发送或保存。

### 健康检查

```bash
bash health_check.sh
```

该命令会检查：

- `GET /api/v1/live`
- `GET /v1/models`
- `GET /v1/limits`

### 单样本请求测试

在 `.env` 中设置 `TEST_IMAGE` 和 `TEST_QUESTION`，然后运行：

```bash
bash run_test.sh
```

也可以直接调用 Python 客户端：

```bash
python chat_test.py \
  --image /path/to/test.jpg \
  --question "What is written in the image?"
```

### 使用 VLMEvalKit 运行 OCRBench_v2

运行完整 OCRBench_v2 评测：

```bash
MAX_SAMPLES=0 MODE=all NPROC=10 bash vlmevalkit/run_vlmevalkit.sh
```

运行小规模连通性测试：

```bash
MAX_SAMPLES=5 MODE=infer NPROC=4 bash vlmevalkit/run_vlmevalkit.sh
```

默认使用仓库根目录下的 `VLMEvalKit/` submodule。如需使用其他 VLMEvalKit 路径：

```bash
VLMEVALKIT_DIR=/path/to/VLMEvalKit MAX_SAMPLES=0 MODE=all NPROC=10 bash vlmevalkit/run_vlmevalkit.sh
```

### 最小 curl 示例

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

### 请求限制

```bash
curl http://leaderboard.koreadeep.com/v1/limits
```

公开 API 仅对 `/v1/chat/completions` 使用队列方式处理超限请求。
为了获得稳定吞吐，建议 `NPROC` 不超过 `max_concurrent_requests_per_token`。
`/v1/limits` 返回的 `limited_paths` 应只包含 `/v1/chat/completions`。

### 结果

VLMEvalKit 输出目录：

```text
vlmevalkit/results/
```

结果文件已被 git 忽略。如需提交评测结果，请单独发送。
