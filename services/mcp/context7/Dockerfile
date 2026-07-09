# 使用具体的 Node.js LTS 版本镜像 (20.x alpine)
FROM node:20-alpine

# 设置工作目录
WORKDIR /app

# 复制 package.json 和 package-lock.json (如果存在)
# 这样可以利用 Docker 缓存，如果依赖没有变化，则不会重新安装
# 注意：Context7 MCP 是一个全局安装的 npm 包，所以这里不需要复制项目本身的 package.json
# 如果 Context7 MCP 服务有自己的 package.json，则需要复制

# 安装依赖
# Context7 MCP 是一个 npm 包，所以我们直接全局安装它
RUN npm install -g @upstash/context7-mcp

# 暴露服务端口 (根据你的服务实际监听的端口)
# 根据 GitHub 仓库的示例，Context7 MCP 服务通常不直接监听 HTTP 端口，
# 而是通过 npx 命令启动，并可能通过标准输入/输出与客户端通信。
# 如果它确实监听 HTTP 端口，你需要在这里指定。
# 假设它监听 3000 端口，如果不是，请修改
EXPOSE 3000

# 定义容器启动时执行的命令
# 这里使用 npx 运行 Context7 MCP 服务，并传入 API 密钥
# 注意：YOUR_API_KEY 应该通过环境变量传递，而不是硬编码
CMD ["npx", "@upstash/context7-mcp", "--api-key", "${CONTEXT7_API_KEY}"]
