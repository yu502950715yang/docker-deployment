# Ubuntu 系统部署 Docker 完整教程

## 一、环境说明

适配系统：Ubuntu 20.04 / 22.04 等主流 Ubuntu 发行版

操作权限：需要 root /sudo 管理员权限

## 二、完整安装步骤

1. 更新系统软件源索引

```bash
sudo apt-get update
```

2. 安装前置依赖包
   用于 HTTPS 访问仓库、密钥校验等基础组件：

```bash
sudo apt-get install ca-certificates curl gnupg lsb-release
```

3. 导入 Docker 官方 GPG 密钥
   校验 Docker 安装包合法性，防止软件篡改：

```bash
curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
```

4. 修改Docker软件源为阿里云

```bash
echo "deb [arch=\$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://mirrors.aliyun.com/docker-ce/linux/ubuntu \$(lsb\_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

5. 刷新软件源并安装 Docker 引擎

```bash
# 再次更新源，加载新增的docker仓库
sudo apt-get update 
# 安装docker核心组件 
sudo apt-get install docker-ce docker-ce-cli containerd.io
```

6. 免 sudo 操作 Docker
   默认 docker 命令需要管理员权限，将当前用户加入 docker 用户组，注销重登后生效：

```bash
sudo usermod -aG docker \$USER
```

注意：执行完命令后​**重新登录服务器**​，权限配置才能生效。

7. Docker 服务管理
   启动 Docker 服务

```bash
sudo systemctl start docker
```

查看 Docker 运行状态

```bash
sudo systemctl status docker
```

设置开机自启

```bash
sudo systemctl enable docker
```

校验开机自启是否配置成功

```bash
sudo systemctl is-enabled docker
```

## 三、安装 Docker Compose

用于批量编排、管理多容器服务

```bash
sudoaptinstall-ydocker-compose
```

验证 docker-compose 安装

```bash
docker-compose --version
```



