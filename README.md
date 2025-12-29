# Docker 部署合集

本仓库整理了一组可直接在本地或服务器使用的 Docker Compose 服务，覆盖 Web 反向代理（Nginx）、缓存（Redis）、数据库（MySQL 5.7、PostgreSQL）、自动化平台（n8n）以及监控栈（Prometheus + Grafana），并包含 Sentinel Dashboard 的独立构建。

## 目录结构
- services/nginx：最小可用的 Nginx 反向代理与静态站点服务
- services/redis：Redis 7.0，包含基础配置与密码校验
- services/mysql5.7：MySQL 5.7，支持初始化脚本挂载
- services/n8n：n8n 自动化平台 + PostgreSQL，支持中文界面汉化
- services/monitoring：Prometheus、Grafana、Node Exporter、MySQL Exporter 组合
- services/sentinel：Sentinel Dashboard 1.8.8 的镜像构建与运行
- docs：与 Docker 安装和常用命令相关的参考资料

## 前置条件
- 已安装 Docker 与 Docker Compose（建议使用 v2，命令为 docker compose）
- 开发/生产环境开放对应端口（见下文端口一览）
- 根据需要准备持久化存储目录、配置文件与证书等

## 快速开始
以下命令均在对应服务目录中执行。

### Nginx
路径：services/nginx
- 默认端口：80、443
- 重要目录挂载：
  - ./html/dist → /usr/share/nginx/html（前端打包产物）
  - ./logs → /var/log/nginx（访问/错误日志）
  - ./conf/nginx.conf → /etc/nginx/nginx.conf（主配置）
  - ./certs → /etc/nginx/certs（可选：TLS 证书）
- 如需代理后端接口或 WebSocket，请在 conf/nginx.conf 的 upstream 中替换为你的真实服务地址与端口。

启动：

```bash
cd services/nginx
docker compose up -d
```

### Redis
路径：services/redis
- 默认端口：6379
- 密码通过 REDIS_PASSWORD 环境变量传入，已在 compose 中校验为空时报错
- 基础配置文件：config/redis.conf（已开启 appendonly 与对外监听）

启动：

```bash
cd services/redis
docker compose up -d
```

> 安全提示：生产环境应启用网络访问控制、防火墙与更强的密码策略。

### MySQL 5.7
路径：services/mysql5.7
- 默认端口：3306
- 数据持久化卷：mysql_data
- 可选初始化脚本目录：./init（SQL/SH 文件在首次启动时执行）

启动：

```bash
cd services/mysql5.7
docker compose up -d
```

### n8n（含 PostgreSQL）
路径：services/n8n
- 默认端口：n8n → 5678，PostgreSQL → 5432（仅容器内部使用）
- 配置文件：同目录 .env（已提供示例）
  - 必填项：POSTGRES_USER、POSTGRES_PASSWORD、N8N_ENCRYPTION_KEY
  - 建议：将 N8N_HOST、WEBHOOK_URL 设置为生产域名并通过反向代理提供 HTTPS
- 汉化：language/zh/dist 已挂载至 n8n-editor-ui 的 dist 目录

启动：

```bash
cd services/n8n
# 检查并修改 .env 中的强密码与随机加密密钥
docker compose up -d
```

访问：
- Web 控制台：http://localhost:5678/（生产建议走 Nginx/HTTPS）

### 监控栈（Prometheus + Grafana 等）
路径：services/monitoring
- 默认端口：Prometheus → 9090，Grafana → 3000，Node Exporter → 9100，MySQL Exporter → 9104
- Prometheus 配置：prometheus/prometheus.yml（可在此添加/修改抓取目标）
- Grafana 预配置目录：grafana/provisioning（默认管理员 admin/admin123，生产请修改）
- MySQL Exporter 使用 mysql-exporter/my.cnf 提供凭据

启动：

```bash
cd services/monitoring
docker compose up -d
```

访问：
- Prometheus：http://localhost:9090/
- Grafana：http://localhost:3000/

### Sentinel Dashboard
路径：services/sentinel
- 镜像基于 openjdk:8-jdk-alpine 构建，版本：1.8.8
- Jar 包：sentinel-dashboard-1.8.8.jar
- 默认账户与密码可通过环境变量 SENTINEL_USER、SENTINEL_PWD 覆盖
- 默认端口：8081

构建与启动：

```bash
cd services/sentinel
docker compose build
docker compose up -d
```

访问：
- 控制台：http://localhost:8081/

## 常用命令
- 启动：docker compose up -d
- 停止：docker compose down
- 查看日志：docker compose logs -f
- 重启：docker compose restart
- 查看服务状态：docker compose ps



