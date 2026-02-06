# Linux 系统同步网络时间步骤

在 Linux 系统中，保持系统时间准确非常重要，特别是对于分布式系统、日志记录和定时任务。以下是几种常见的同步网络时间的方法。

## 方法一：使用 ntpdate（传统方法）

`ntpdate` 是一个用于通过 NTP 协议设置日期的命令行实用程序。

### 1. 安装 ntpdate

如果系统中没有安装 `ntpdate`，可以使用包管理器进行安装：

**CentOS / RHEL:**
```bash
yum install -y ntpdate
```

**Ubuntu / Debian:**
```bash
apt-get update
apt-get install -y ntpdate
```

### 2. 同步时间

执行以下命令同步时间（使用阿里云 NTP 服务器为例）：

```bash
ntpdate ntp.aliyun.com
```

### 3. 设置定时任务（Crontab）

为了保持时间长期准确，建议设置定时任务自动同步：

```bash
crontab -e
```

添加以下内容（每小时同步一次）：
```cron
0 * * * * /usr/sbin/ntpdate ntp.aliyun.com
```

---

## 方法二：使用 Chrony（推荐方法）

`Chrony` 是一个更现代、更通用的 NTP 实现，特别适合在网络连接不稳定或间歇性连接的环境中运行。CentOS 7/8 和较新的 Ubuntu 版本通常默认使用 Chrony。

### 1. 安装 Chrony

**CentOS / RHEL:**
```bash
yum install -y chrony
systemctl enable chronyd
systemctl start chronyd
```

**Ubuntu / Debian:**
```bash
apt-get install -y chrony
systemctl enable chrony
systemctl start chrony
```

### 2. 配置时间服务器

编辑配置文件 `/etc/chrony.conf` (CentOS) 或 `/etc/chrony/chrony.conf` (Ubuntu)：

```bash
vi /etc/chrony.conf
```

注释掉默认的 server，添加国内的 NTP 服务器（如阿里云）：

```conf
server ntp.aliyun.com iburst
server ntp1.aliyun.com iburst
server ntp2.aliyun.com iburst
```

### 3. 重启服务并验证

重启 Chrony 服务：
```bash
# CentOS
systemctl restart chronyd
# Ubuntu
systemctl restart chrony
```

查看同步状态：
```bash
chronyc sources -v
```
如果看到 `*` 号，说明同步成功。

---

## 常用操作：设置时区

同步时间前，请确保时区设置正确（通常设置为上海时间）。

### 1. 查看当前时区
```bash
timedatectl
```

### 2. 设置时区为 Asia/Shanghai
```bash
timedatectl set-timezone Asia/Shanghai
```

### 3. 验证
再次执行 `date` 命令查看时间是否正确。

---

## 硬件时间同步

将系统时间写入硬件时钟（BIOS），防止重启后失效：

```bash
hwclock -w
```
