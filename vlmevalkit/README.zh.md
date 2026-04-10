# KDL Frontier 的 VLMEvalKit OCRBench_v2 运行脚本

此目录包含排行榜评测方可直接运行的 VLMEvalKit 示例。
不需要修改 VLMEvalKit 源码。脚本会生成 `run.py --config` 所需配置，并使用 VLMEvalKit 自带的 OpenAI 兼容 `GPT4V` wrapper。

## 配置 API 访问

在仓库根目录创建 `.env`：

```bash
cp .env.example .env
```

必填配置：

```env
DEEPFLOW_API_BASE=http://leaderboard.koreadeep.com
DEEPFLOW_API_KEY=<issued-token>
DEEPFLOW_MODEL="KDL Frontier"
```

## 前置条件

- 可以运行 VLMEvalKit 的 Python 环境。
- VLMEvalKit 源码目录。默认路径：`/home/ian/workspace/VLMEvaluation/VLMEvalKit`
- 可以访问 `http://leaderboard.koreadeep.com`

如需指定 VLMEvalKit 路径：

```bash
VLMEVALKIT_DIR=/path/to/VLMEvalKit bash vlmevalkit/run_vlmevalkit.sh
```

## 快速测试

默认运行 5 个 OCRBench_v2 样本，只执行推理：

```bash
bash vlmevalkit/run_vlmevalkit.sh
```

该模式用于确认 API 连接和输出生成是否正常。

## 完整 OCRBench_v2 评测

```bash
MAX_SAMPLES=0 MODE=all NPROC=10 bash vlmevalkit/run_vlmevalkit.sh
```

参数说明：

- `MAX_SAMPLES=0`：运行完整 OCRBench_v2 数据集。
- `MODE=all`：执行推理和评测。
- `NPROC=10`：最多同时发送 10 个 API 请求。

增加 `NPROC` 前请先查看限制：

```bash
curl http://leaderboard.koreadeep.com/v1/limits
```

公开 API 使用队列方式处理超限请求。超过并发限制的请求会在服务端排队。
为了获得稳定吞吐，建议 `NPROC` 不超过 `max_concurrent_requests_per_token`。

## 输出

默认输出目录：

```text
vlmevalkit/results/KDL Frontier
```

生成的 VLMEvalKit 配置：

```text
vlmevalkit/generated/kdl_frontier_ocrbench_v2_config.json
```

## 打包结果

评测完成后运行：

```bash
bash vlmevalkit/package_results.sh
```

打包文件会写入：

```text
vlmevalkit/submission/
```

zip 包含：

- VLMEvalKit 输出
- 生成的 manifest
- 英文和中文说明
- 可直接运行的客户端脚本
- 配置模板

API key 不会包含在 zip 中，需要单独提供。
