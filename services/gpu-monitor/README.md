# GPU 监控（NVIDIA DCGM Exporter）

本目录用于在**带 NVIDIA GPU 的 Linux 服务器**上部署 [DCGM Exporter](https://github.com/NVIDIA/dcgm-exporter)，把 GPU 指标（利用率 / 显存 / 温度 / 功耗 / 风扇转速等）暴露给已有的 Prometheus + Grafana 监控栈。

配套改动（在远端监控栈主机上）：
- `services/monitoring/prometheus/prometheus.yml`：新增 `gpu` 抓取 job，target 为 `<本机IP>:9400`（默认已配 `10.0.2.170:9400`）
- `services/monitoring/grafana/provisioning/dashboards/dcgm-exporter-dashboard.json`：NVIDIA 官方 DCGM 面板（id `12239`），由 Grafana provisioning 自动加载

---

## 一、前置条件（必须在 GPU 服务器上完成）

1. **NVIDIA 显卡驱动**
   ```bash
   nvidia-smi        # 能输出显卡信息即驱动正常
   ```

2. **NVIDIA Container Toolkit**（让 Docker 容器能访问 GPU）
   ```bash
   docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu20.04 nvidia-smi
   # 能输出显卡信息即容器运行时可用
   ```
   > 若容器不可用 GPU，请先安装 NVIDIA Container Toolkit：
   > https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html

3. **Docker 与 Docker Compose v2**
   ```bash
   docker compose version
   ```

---

## 二、离线导入镜像（内网/无法访问 nvcr.io 时）

DCGM Exporter 镜像位于 NVIDIA 私有仓库 `nvcr.io`，许多内网环境无法直接拉取。在有外网的机器上执行：

```bash
# 在有外网的机器上拉取并导出
docker pull nvcr.io/nvidia/k8s/dcgm-exporter:4.6.0-4.8.3-distroless
docker save nvcr.io/nvidia/k8s/dcgm-exporter:4.6.0-4.8.3-distroless -o dcgm-exporter.tar
# 把 dcgm-exporter.tar 拷到 GPU 服务器后导入
docker load -i dcgm-exporter.tar
```

---

## 三、启动与验证

```bash
cd services/gpu-monitor
docker compose up -d

# 验证指标（本机）
curl http://<本机IP>:9400/metrics | grep DCGM_FI_DEV_GPU_UTIL
```

能看到 `DCGM_FI_DEV_GPU_UTIL`、`DCGM_FI_DEV_GPU_TEMP`、`DCGM_FI_DEV_FB_USED`、`DCGM_FI_DEV_POWER_USAGE`、`DCGM_FI_DEV_FAN_SPEED` 等指标即部署成功。

### 在监控栈主机确认
- Prometheus → `http://<监控主机>:9090/targets`：`gpu` job 状态为 **UP**
- Grafana → `http://<监控主机>:3000`：自动出现 **NVIDIA DCGM Exporter Dashboard**

---

## 四、监控指标说明

| 指标 | 含义 |
|------|------|
| `DCGM_FI_DEV_GPU_UTIL` | GPU 计算利用率（%） |
| `DCGM_FI_DEV_FB_USED` / `DCGM_FI_DEV_FB_FREE` | 显存已用 / 剩余（MiB） |
| `DCGM_FI_DEV_GPU_TEMP` / `DCGM_FI_DEV_MEMORY_TEMP` | GPU / 显存温度（℃） |
| `DCGM_FI_DEV_POWER_USAGE` | 功耗（W） |
| `DCGM_FI_DEV_FAN_SPEED` | 风扇转速（%） |
| `DCGM_FI_DEV_XID_ERRORS` | 最近一次 XID 错误（排查故障用） |
| `DCGM_FI_DRIVER_VERSION` | 驱动版本（作为 label） |

> 计数器文件 `dcgm-exporter-counters.csv` 在默认基础上补充了风扇转速与 ECC/健康相关字段，可按需增删。

---

## 五、可选：GPU 上的进程监控

DCGM Exporter 默认不暴露"哪些进程在使用 GPU"。若需要，提供一种稳定方式：**node-exporter textfile collector + cron**。

1. GPU 服务器上已有 `node_exporter`（或按 `services/server-monitor` 部署），并启用 textfile collector：
   ```bash
   node_exporter --collector.textfile.directory=/var/lib/node_exporter/textfile_collector
   ```

2. 把 `gpu-process-monitor.sh` 拷到 GPU 服务器，创建目录并加 cron：

   ```bash
   sudo mkdir -p /var/lib/node_exporter/textfile_collector
   sudo chmod +x gpu-process-monitor.sh
   # 每 1 分钟采集一次（脚本可加 -- 或环境变量指定 nvidia-smi 绝对路径）
   echo "*/1 * * * * root TEXTFILE_DIR=/var/lib/node_exporter/textfile_collector /opt/gpu-monitor/gpu-process-monitor.sh" | sudo tee /etc/cron.d/gpu-process
   ```

3. 脚本输出指标 `gpu_process_used_memory_bytes{pid="..",process="..",gpu_uuid=".."}`，可在 Grafana 新建查询面板查看当前占用 GPU 的进程。
