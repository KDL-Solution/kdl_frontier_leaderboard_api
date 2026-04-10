# KDL Frontier API 评测客户端

此目录包含通过公开 API 评测 KDL Frontier 的示例客户端代码。
排行榜评测方只需要 API endpoint、分配的 API key，以及这些脚本即可运行。

请不要把分配的 API key 提交到代码仓库或随包公开分发。请将其写入
`.env`，或通过评测平台的 secret manager 提供。

## API 信息

```text
API base: http://leaderboard.koreadeep.com
Chat endpoint: http://leaderboard.koreadeep.com/v1/chat/completions
Model: KDL Frontier
Authentication: Authorization: Bearer <issued-token>
```

该 API 使用 OpenAI 兼容的多模态 chat-completions 格式。

## 文件说明

- `.env.example`：环境变量模板。复制为 `.env` 后填写分配的 token。
- `health_check.py`：检查 API 可用性、模型信息和公开限制。
- `health_check.sh`：`health_check.py` 的 shell 封装。
- `chat_test.py`：向 chat-completions API 发送一个图片问答请求。
- `run_test.sh`：`chat_test.py` 的 shell 封装。
- `vlmevalkit/`：用于 OCRBench_v2 的 VLMEvalKit 运行脚本和配置模板。

## 配置

带 VLMEvalKit submodule 克隆仓库：

```bash
git clone --recursive https://github.com/KDL-Solution/kdl_frontier_leaderboard_api.git
cd kdl_frontier_leaderboard_api
```

如果已经普通克隆过仓库：

```bash
git submodule update --init --recursive
```

```bash
cp .env.example .env
vi .env
```

填写分配的 token：

```env
DEEPFLOW_API_BASE=http://leaderboard.koreadeep.com
DEEPFLOW_API_KEY=<issued-token>
DEEPFLOW_MODEL="KDL Frontier"
```

## 健康检查

```bash
bash health_check.sh
```

会检查以下接口：

- `GET /api/v1/live`
- `GET /v1/models`
- `GET /v1/limits`

## 单样本请求测试

在 `.env` 中设置 `TEST_IMAGE` 和 `TEST_QUESTION`，然后运行：

```bash
bash run_test.sh
```

也可以直接运行 Python 客户端：

```bash
python chat_test.py \
  --image /path/to/test.jpg \
  --question "What is written in the image?"
```

## 最小 curl 示例

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

## 请求限制

查看当前公开限制：

```bash
curl http://leaderboard.koreadeep.com/v1/limits
```

公开 API 使用队列方式处理超限请求。如果并发超过返回的
`max_concurrent_requests_per_token`，请求会在服务端排队，而不是直接失败。
使用 VLMEvalKit 时，建议将 `NPROC` 设置为不超过返回的 `max_concurrent_requests_per_token`。

## 使用 VLMEvalKit 运行 OCRBench_v2

运行专用脚本：

```bash
MAX_SAMPLES=0 MODE=all NPROC=10 bash vlmevalkit/run_vlmevalkit.sh
```

完整 VLMEvalKit 说明见 `vlmevalkit/README.zh.md`。

## 需要发送给排行榜评测方的内容

请发送以下内容：

- 此仓库目录，或由 `vlmevalkit/package_results.sh` 生成的 zip。
- API base：`http://leaderboard.koreadeep.com`
- 模型名：`KDL Frontier`
- API key：通过安全渠道单独提供分配的 token。
- 推荐运行命令：`MAX_SAMPLES=0 MODE=all NPROC=10 bash vlmevalkit/run_vlmevalkit.sh`

服务端会在内部保存请求审计日志。排行榜评测方运行评测时不需要访问该日志。
