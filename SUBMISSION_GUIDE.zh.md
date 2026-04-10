# KDL Frontier API 交付说明

本文档说明排行榜评测方如何通过公开 API 使用 KDL Frontier 运行 OCRBench_v2。

## 接口信息

```text
API base: http://leaderboard.koreadeep.com
Chat completions: http://leaderboard.koreadeep.com/v1/chat/completions
Model: KDL Frontier
Authentication: Authorization: Bearer <issued-token>
```

该接口兼容 OpenAI 多模态 chat-completions 格式。

## 需要提供的文件

可以提供整个仓库目录，或提供以下命令生成的 zip：

```bash
bash vlmevalkit/package_results.sh
```

zip 包含：

- 健康检查和单样本请求测试客户端。
- VLMEvalKit OCRBench_v2 运行脚本。
- VLMEvalKit 配置模板。
- 英文和中文 README。
- 如果本地已有评测输出，也会包含输出结果。

API key 不会包含在包内。请通过单独的安全渠道发送分配的 token。

## 必要配置

带 VLMEvalKit 克隆仓库：

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

填写：

```env
DEEPFLOW_API_BASE=http://leaderboard.koreadeep.com
DEEPFLOW_API_KEY=<issued-token>
DEEPFLOW_MODEL="KDL Frontier"
```

## 健康检查

```bash
bash health_check.sh
```

会检查：

- `GET /api/v1/live`
- `GET /v1/models`
- `GET /v1/limits`

## 单样本测试

```bash
python chat_test.py \
  --image /path/to/test.jpg \
  --question "What is written in the image?"
```

## 使用 VLMEvalKit 运行 OCRBench_v2

该 runner 不需要修改 VLMEvalKit 源码。脚本会生成临时 `run.py --config`
配置，并使用 VLMEvalKit 自带的 OpenAI 兼容 `GPT4V` wrapper。

```bash
MAX_SAMPLES=0 \
MODE=all \
NPROC=10 \
bash vlmevalkit/run_vlmevalkit.sh
```

快速测试：

```bash
MAX_SAMPLES=5 MODE=infer NPROC=4 bash vlmevalkit/run_vlmevalkit.sh
```

## 运维说明

- OCRBench_v2 pipeline 每次请求接收 1 张图片。
- 公开 API 使用队列方式处理超限请求。请通过 `GET /v1/limits` 查看当前并发限制。
- 推荐 VLMEvalKit 并发：`NPROC=10`。
- 服务端审计日志由 Korea Deep Learning Inc. 内部保存。
- 请不要把 API key 放入结果压缩包或公开 issue tracker。
