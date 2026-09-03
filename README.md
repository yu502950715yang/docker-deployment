# Docker 部署合集

本仓库整理了一组可直接在本地或服务器使用的 Docker Compose 服务，覆盖 Web 反向代理（Nginx）、缓存（Redis）、数据库（MySQL 5.7、PostgreSQL）、自动化平台（n8n）、监控栈（Prometheus + Grafana）以及 Java 环境相关的服务（Sentinel、WildfireChat IM、JMX），并包含若干离线镜像与配套脚本。

> 仓库中部分服务目录内含 `*.tar` 离线镜像文件——这些文件已被 `.gitignore` 忽略（不会提交到 Git），需要预先导出/导入后方可使用。`docs/` 目录提供了 Docker 安装与常用命令的参考资料。

## 目录结构

- `services/nginx`：Nginx 反向代理与静态站点服务（1.25-alpine）
- `services/redis`：Redis 7.0，带密码校验与持久化配置
- `services/mysql5.7`：MySQL 5.7，支持初始化脚本挂载
- `services/n8n`：n8n 自动化平台 + PostgreSQL，支持中文界面汉化
- `services/monitoring`：Prometheus、Grafana、Node Exporter、MySQL Exporter 组合，附带 JMX 监控配置与 Grafana 面板
- `services/gpu-monitor`：NVIDIA GPU 监控（DCGM Exporter），供监控栈抓取
- `services/sentinel`：Sentinel Dashboard 1.8.8 的镜像构建与运行
- `services/server-monitor`：独立部署的 Node Exporter，供远端 Prometheus 抓取
- `services/mcp/context7`：Context7 MCP 服务（为 AI 工具提供上下文）
- `services/wildfirechat/im-server`：野火 IM 服务（Java，基于 openjdk:8-jdk-alpine）
- `start-jmx.sh`：在宿主机为多个 Java 服务附加 JMX Exporter 的启动/停止脚本
- `docs`：与 Docker 安装和常用命令相关的参考资料

## 前置条件

- 已安装 Docker 与 Docker Compose（建议使用 v2，命令为 `docker compose`）
- 开发/生产环境开放对应端口（见文末“端口一览”）
- 根据需要准备持久化存储目录、配置文件与证书等
- 部分服务需离线导入镜像（见下方“离线镜像导入”）

---

## 快速开始

以下命令均在对应服务目录中执行。

### Nginx
路径：`services/nginx`
- 镜像：`nginx:1.25-alpine`
- 暴露端口：`80`（HTTP）、`443`（HTTPS）
- 重要挂载：
  - `./html/dist` → `/usr/share/nginx/html`（前端打包产物）
  - `./logs` → `/var/log/nginx`（访问/错误日志）
  - `./conf/nginx.conf` → `/etc/nginx/nginx.conf`（主配置）
  - `./certs` → `/etc/nginx/certs`（可选：TLS 证书）
- 内置健康检查：`nginx -t || exit 1`

如需代理后端接口或 WebSocket，请在 `conf/nginx.conf` 的 `upstream` 中替换为你的真实服务地址与端口。

```bash
cd services/nginx
docker compose up -d
```

### Redis
路径：`services/redis`
- 镜像：`redis:7.0.12`
- 暴露端口：`6379`
- 密码通过 `REDIS_PASSWORD` 环境变量传入（默认 `123456`，建议修改）；compose 启动脚本会在密码为空时报错退出
- 基础配置文件：`config/redis.conf`（已开启 `appendonly` 与对外监听）

```bash
cd services/redis
docker compose up -d
```

> 安全提示：生产环境应启用网络访问控制、防火墙与更强的密码策略。

### MySQL 5.7
路径：`services/mysql5.7`
- 镜像：`mysql:5.7`
- 暴露端口：`3306`
- 根密码：环境变量 `MYSQL_ROOT_PASSWORD`（默认 `root`）
- 数据持久化卷：`mysql_data`
- 可选初始化脚本目录：`./init`（`SQL/SH` 文件在首次启动时执行）
- 离线镜像见同目录 `mysql5.7.tar`

```bash
cd services/mysql5.7
docker compose up -d
```

### n8n（含 PostgreSQL）
路径：`services/n8n`
- 镜像：`n8nio/n8n:2.1.4`、`postgres:15-alpine`
- 暴露端口：n8n → `5678`，PostgreSQL → 仅容器内部 `5432`
- 配置文件：同目录 `.env`（已提供示例）
  - 必填项：`POSTGRES_USER`、`POSTGRES_PASSWORD`、`N8N_ENCRYPTION_KEY`
  - 建议：将 `N8N_HOST`、`WEBHOOK_URL` 设置为生产域名并通过反向代理提供 HTTPS
- 汉化：`language/zh/dist` 已挂载至 n8n-editor-ui 的 `dist` 目录
- 依赖：n8n 等待 PostgreSQL 健康检查通过后才启动
- 注意：PostgreSQL 与 n8n 容器的 `restart` 均为 `no`，需手动启动或重启

```bash
cd services/n8n
# 检查并修改 .env 中的强密码与随机加密密钥
docker compose up -d
```

访问：
- Web 控制台：`http://localhost:5678/`（生产建议走 Nginx/HTTPS）

### 监控栈（Prometheus + Grafana 等）
路径：`services/monitoring`
- 镜像：`prom/prometheus:v3.6.0`、`grafana/grafana:12.3.0-18392635519`、`prom/node-exporter:v1.9.1`、`prom/mysqld-exporter:v0.18.0`
- 暴露端口：Prometheus → `9090`，Grafana → `3000`，Node Exporter → `9100`，MySQL Exporter → `9104`
- Prometheus 配置：`prometheus/prometheus.yml`（可在此添加/修改抓取目标），并含 `alert_rules.yml`（预留告警规则）
- Grafana 预配置目录：`grafana/provisioning`，默认管理员 `admin/admin123`（生产请修改），已开启中文界面（`GF_LANG=zh-CN`）
- MySQL Exporter 使用 `mysql-exporter/my.cnf` 提供凭据
- 数据持久化：`prometheus_data`、`grafana_data` 两个命名卷
- 网络：`monitoring` 桥接网络；Prometheus 已配置 `host.docker.internal:host-gateway` 便于抓取宿主机服务
- 离线镜像：`images/prom/prometheus-v3.6.0.tar`

```bash
cd services/monitoring
docker compose up -d
```

访问：
- Prometheus：`http://localhost:9090/`
- Grafana：`http://localhost:3000/`

### NVIDIA GPU 监控（DCGM Exporter）
路径：`services/gpu-monitor`（部署在带 NVIDIA GPU 的服务器上）
- 镜像：`nvcr.io/nvidia/k8s/dcgm-exporter:4.6.0-4.8.3-distroless`
- 前提：GPU 服务器需安装 NVIDIA 驱动与 NVIDIA Container Toolkit（详见该目录 `README.md`）
- 暴露端口：`9400`（供远端 Prometheus 抓取）
- 计数器文件：`dcgm-exporter-counters.csv`（在官方基础上补充了风扇转速、ECC 等字段）
- 配套改动（在监控栈主机上）：
  - `monitoring/prometheus/prometheus.yml` 已添加 `gpu` 抓取 job（target 默认 `10.0.2.170:9400`，请按实际 IP 修改）
  - `monitoring/grafana/provisioning/dashboards/dcgm-exporter-dashboard.json` 已预置 NVIDIA 官方面板（id `12239`）
- 可选：`gpu-process-monitor.sh` 用于监控“哪些进程在使用 GPU”（node-exporter textfile collector 方案）

```bash
cd services/gpu-monitor
docker compose up -d
curl http://<本机IP>:9400/metrics | grep DCGM_FI_DEV_GPU_UTIL
```

### Sentinel Dashboard
路径：`services/sentinel`
- 镜像基于 `openjdk:8-jdk-alpine` 构建，版本：`1.8.8`
- Jar 包：`sentinel-dashboard-1.8.8.jar`
- 默认账户与密码可通过环境变量 `SENTINEL_USER`、`SENTINEL_PWD` 覆盖（compose 中默认 `sentinel` / `8vdJ3Qzo@2`，生产请修改）
- 暴露端口：`8081`

```bash
cd services/sentinel
docker compose build
docker compose up -d
```

访问：
- 控制台：`http://localhost:8081/`

### 服务器监控（独立 Node Exporter）
路径：`services/server-monitor`（部署在被监控服务器上）
- 镜像：`prom/node-exporter:v1.9.1`
- 暴露端口：`9100`（供远端 Prometheus 抓取）
- 通过 `pid: host` 与宿主文件系统挂载采集真实状态；已排除噪音挂载点
- 适用于单独采集某台主机指标且不需要全套监控栈的场景

```bash
cd services/server-monitor
docker compose up -d
curl http://<本机IP>:9100/metrics
```

### Context7 MCP 服务
路径：`services/mcp/context7`
- 镜像：基于 `node:lts-alpine` 构建的 `context7-mcp-service:latest`（需先执行 `docker build`）
- 暴露端口：`3000`
- 环境变量：`CONTEXT7_API_KEY`（替换为你的实际 API 密钥）
- 详细说明见该目录 `README.md`

```bash
cd services/mcp/context7
docker build -t context7-mcp-service:latest .
docker compose up -d
```

### WildfireChat IM 服务
路径：`services/wildfirechat/im-server`
- 镜像：基于 `openjdk:8-jdk-alpine`，内含 `distribution-*-bundle-tar.tar.gz` 解包而成
- 暴露端口：`80`（HTTP）、`1883`（MQTT）、`8083`/`8084`（WebSocket / SSL）、`18080`（管理后台）
- 挂载：`./config`（配置文件）、`./data/logs`、`./data/h2db`、`./data/media`
- 环境变量：`JVM_XMX`、`JVM_XMS`（默认 256M）、`TZ=Asia/Shanghai`
- 部署前需先编译 im-server 并放置 `distribution-*-bundle-tar.tar.gz`，并导入 `openjdk-8-jdk-alpine.tar`

```bash
cd services/wildfirechat/im-server
docker load -i openjdk-8-jdk-alpine.tar
docker compose up -d --build
docker logs -f im-server
# 验证：http://<IP>/api/version 返回 json 即成功
```

### JMX 监控（宿主机 Java 服务）
仓库根目录 `start-jmx.sh` 用于在宿主机为多个 Java 服务启动/停止时附加 JMX Exporter（`jmx_prometheus_javaagent`），配合 Prometheus 抓取 Java 应用指标。

- 依赖：`services/monitoring/jmx_prometheus/` 下的 `jmx_prometheus_javaagent-1.5.0.jar` 与 `jmx_config.yml`
- 脚本内定义了服务端口映射（服务名:端口），并通过 `JMX_PORT_OFFSET` 计算 JMX 端口（默认 +10000）
- 用法：

```bash
./start-jmx.sh start              # 启动全部服务
./start-jmx.sh start <服务名>     # 启动指定服务
./start-jmx.sh stop               # 停止全部服务
./start-jmx.sh stop <服务名>      # 停止指定服务
```

> 使用前请按实际修改脚本顶部的 `NACOS_*` 环境变量、`JMX_AGENT_PATH`、`JMX_CONFIG_PATH` 与 `services` 映射表。对应的 Grafana 面板参考 `monitoring/grafana面板配置文件/` 目录（如 `JMX仪表盘-*.json`、`tomcat.json` 等）。

---

## 离线镜像导入

仓库部分目录内含离线镜像文件（已被 `.gitignore` 忽略，需手动保留）。在无法访问外网/私有仓库的环境中，先在有外网的机器拉取并导出，再拷贝到服务器导入：

```bash
# 导出示例（以 prometheus 为例）
docker pull prom/prometheus:v3.6.0
docker save prom/prometheus:v3.6.0 -o prometheus-v3.6.0.tar

# 在目标服务器导入（文件名按实际替换）
docker load -i <镜像>.tar
```

涉及离线镜像的服务：MySQL（`mysql5.7.tar`）、Redis（`redis7.0.12.tar`）、Sentinel（`openjdk-8-jdk-alpine.tar`）、GPU（`dcgm-exporter.tar`）、监控（`images/prom/prometheus-v3.6.0.tar`）、Nginx（`nginx1.25-alpine`）、WildfireChat（`openjdk-8-jdk-alpine.tar`）。

---

## 常用命令

```bash
# 启动（在对应服务目录下）
docker compose up -d          # 后台启动
docker compose up -d --build  # 启动并重新构建镜像
docker compose build          # 仅构建镜像

# 停止
docker compose down           # 停止并移除容器/网络

# 查看
docker compose ps             # 服务状态
docker compose logs -f        # 实时日志
docker compose restart        # 重启

# 通用 Docker 命令
docker ps                     # 容器列表
docker images                 # 镜像列表
docker logs -f <容器名>       # 容器日志
docker load -i <镜像>.tar     # 导入离线镜像
docker save <镜像> -o <镜像>.tar  # 导出镜像
```

---

## 端口一览

| 服务 | 宿主机端口 | 容器端口 | 备注 |
|------|-----------|---------|------|
| Nginx | `80` / `443` | `80` / `443` | HTTP / HTTPS |
| Redis | `6379` | `6379` | 带密码 |
| MySQL 5.7 | `3306` | `3306` | |
| n8n | `5678` | `5678` | |
| Prometheus | `9090` | `9090` | |
| Grafana | `3000` | `3000` | 默认 admin/admin123 |
| Node Exporter（监控栈/独立） | `9100` | `9100` | |
| MySQL Exporter | `9104` | `9104` | |
| DCGM Exporter | `9400` | `9400` | GPU 指标 |
| Sentinel | `8081` | `8081` | |
| Context7 MCP | `3000` | `3000` | |
| WildfireChat | `80`/`1883`/`8083`/`8084`/`18080` | 同左 | IM / MQTT / WS / 管理后台 |

> 注意：Nginx 与 WildfireChat 均占用宿主 `80` 端口，若同时部署请调整其中之一的端口映射。
