# Context7 MCP 服务 Docker 部署指南

## 概述
本文档旨在指导如何使用 Docker Compose 部署 Context7 MCP 服务。

## 前提条件
- 已安装 Docker 和 Docker Compose。
- 已获取 Context7 API Key。

## 部署步骤

1.  **创建 Dockerfile**
    在 `services/mcp/context7` 目录下创建 `Dockerfile` 文件，内容如下：
    ```dockerfile
    # 使用官方 Node.js 镜像作为基础镜像
    FROM node:lts-alpine

    # 设置工作目录
    WORKDIR /app

    # 安装依赖
    RUN npm install -g @upstash/context7-mcp

    # 暴露服务端口
    EXPOSE 3000

    # 定义容器启动时执行的命令
    CMD ["npx", "@upstash/context7-mcp", "--api-key", "${CONTEXT7_API_KEY}"]
    ```

2.  **构建 Docker 镜像**
    在 `services/mcp/context7` 目录下，打开终端并执行以下命令来构建你的 Docker 镜像：
    ```bash
    docker build -t context7-mcp-service:latest .
    ```
    这将创建一个名为 `context7-mcp-service`，标签为 `latest` 的 Docker 镜像。

3.  **配置 `docker-compose.yml`**
    打开 `docker-compose.yml` 文件，内容如下：
    ```yaml
    version: '3.8'
    services:
      context7-mcp:
        image: context7-mcp-service:latest # 使用你构建的Context7 MCP服务镜像
        container_name: context7-mcp-service
        ports:
          - "3000:3000" # Context7 MCP服务默认监听端口
        environment:
          - CONTEXT7_API_KEY=YOUR_API_KEY # 替换为你的实际API密钥
        restart: always
    ```
    **重要提示**：请将 `CONTEXT7_API_KEY=YOUR_API_KEY` 中的 `YOUR_API_KEY` 替换为你的实际 Context7 API 密钥。

4.  **启动服务**
    在 `services/mcp/context7` 目录下，打开终端并执行以下命令启动服务：
    ```bash
    docker-compose up -d
    ```
    `-d` 参数表示在后台运行服务。

5.  **查看服务状态**
    可以使用以下命令查看服务运行状态：
    ```bash
    docker-compose ps
    ```

6.  **停止服务**
    要停止服务，执行以下命令：
    ```bash
    docker-compose down
    ```

7.  **查看服务日志**
    要查看服务的实时日志，执行以下命令：
    ```bash
    docker-compose logs -f context7-mcp
    ```

## 注意事项
-   请确保你的 Docker 镜像 `context7-mcp-service:latest` 已成功构建。
-   **镜像拉取失败处理 (非常重要)**：
    如果你在执行 `docker build` 时遇到 `FROM node:20-alpine` 相关的错误 (如 `Head "..." : EOF` 或 `failed to resolve source metadata`)，通常是因为你的 Docker 镜像加速器（例如网易 163 源）已失效或连接不稳定。
    **解决方法**：
    1.  打开 Docker Desktop 设置 (Settings) -> Docker Engine。
    2.  删除 `registry-mirrors` 中已失效的镜像地址（如 `https://hub-mirror.c.163.com`）。
    3.  尝试使用其他可用的加速器，或者暂时清空该列表，然后重启 Docker Desktop。
    4.  如果是企业内网环境，请检查代理设置。
-   如果你的服务需要连接数据库或其他外部服务，请在 `docker-compose.yml` 中配置相应的环境变量和网络。
-   如果你的服务需要持久化数据，请配置 `volumes`。
