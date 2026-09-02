#!/bin/bash
# =============================================================
# gpu-process-monitor.sh
# 用途：把当前占用 NVIDIA GPU 的进程信息写成 Prometheus textfile，
#       供 node-exporter（--collector.textfile.directory）采集。
# 输出指标：gpu_process_used_memory_mib{gpu_uuid="..",pid="..",process=".."}
#
# 用法：放入 cron 定期执行（建议 30s ~ 1m）。
#   输出默认写到 /var/lib/node_exporter/textfile_collector/gpu_processes.prom
#   可通过环境变量 TEXTFILE_DIR 覆盖输出目录。
#
# 依赖：nvidia-smi 可执行（在 cron 的 PATH 中，或用绝对路径）。
# =============================================================

set -u

# 输出目录（node-exporter 的 textfile collector 目录）
TEXTFILE_DIR="${TEXTFILE_DIR:-/var/lib/node_exporter/textfile_collector}"
OUT_FILE="${TEXTFILE_DIR}/gpu_processes.prom"

# nvidia-smi 绝对路径（cron 常不加载用户 PATH，建议用绝对路径）
NVML_SMI="${NVML_SMI:-$(command -v nvidia-smi || echo /usr/bin/nvidia-smi)}"

if [ ! -x "$NVML_SMI" ]; then
    echo "# nvidia-smi not found: $NVML_SMI" > "$OUT_FILE"
    exit 0
fi

mkdir -p "$TEXTFILE_DIR"

# 临时文件，避免写入一半被读取
TMP_FILE="${OUT_FILE}.tmp"

{
    echo "# HELP gpu_process_used_memory_mib GPU memory used by a process (MiB)."
    echo "# TYPE gpu_process_used_memory_mib gauge"
    # 查询计算进程：gpu_uuid,pid,进程名,显存(MiB)。逗号分隔，et/runtime名称可能含逗号，用双引号包裹。
    "$NVML_SMI" --query-compute-apps=gpu_uuid,pid,process_name,used_gpu_memory \
        --format=csv,noheader,nounits 2>/dev/null | while IFS=',' read -r gpu_uuid pid pname mem; do
        # 去空白
        gpu_uuid=$(echo "$gpu_uuid" | tr -d ' ')
        pid=$(echo "$pid" | tr -d ' ')
        pname=$(echo "$pname" | tr -d ' ')
        mem=$(echo "$mem" | tr -d ' ')

        # 跳过无效行（空值 / N/A）
        if [ -z "$gpu_uuid" ] || [ -z "$pid" ] || [ -z "$mem" ] || [ "$mem" = "N/A" ]; then
            continue
        fi

        # 转义指标 label 中的引号与反斜杠
        pname=${pname//\\/\\\\}
        pname=${pname//\"/\\\"}

        printf 'gpu_process_used_memory_mib{gpu_uuid="%s",pid="%s",process="%s"} %s\n' \
            "$gpu_uuid" "$pid" "$pname" "$mem"
    done
} > "$TMP_FILE"

mv "$TMP_FILE" "$OUT_FILE"
