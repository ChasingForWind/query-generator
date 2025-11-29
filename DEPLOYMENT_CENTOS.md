# CentOS服务器Docker部署指南

本文档详细介绍如何在阿里云CentOS轻量级服务器上部署查询生成器应用。

## 目录

- [前置准备](#前置准备)
- [服务器初始化](#服务器初始化)
- [上传代码到服务器](#上传代码到服务器)
- [部署应用](#部署应用)
- [验证部署](#验证部署)
- [常见问题排查](#常见问题排查)
- [维护操作](#维护操作)

## 前置准备

### 1. 服务器信息

确保您已准备好以下信息：
- 服务器公网IP地址
- SSH登录用户名（通常是 `root` 或自定义用户）
- SSH登录密码或密钥文件

### 2. 本地环境

- Windows系统（本指南基于Windows）
- SSH客户端（Windows 10/11自带OpenSSH，或使用PuTTY）
- SCP工具（Windows 10/11自带，或使用WinSCP）

### 3. 服务器要求

- **操作系统**: CentOS 7/8
- **最低配置**: 1核CPU, 2GB内存, 20GB存储
- **推荐配置**: 2核CPU, 4GB内存, 40GB存储

## 服务器初始化

### 步骤1: 连接到服务器

使用SSH连接到您的服务器：

```bash
# 使用密码登录
ssh root@your-server-ip

# 或使用密钥文件登录
ssh -i your-key.pem root@your-server-ip
```

### 步骤2: 运行初始化脚本

将 `install-docker-centos.sh` 脚本上传到服务器，或直接在服务器上创建：

```bash
# 创建脚本文件
vi install-docker-centos.sh
# 将脚本内容粘贴进去，保存退出（:wq）

# 或使用nano编辑器
nano install-docker-centos.sh
```

给脚本添加执行权限并运行：

```bash
chmod +x install-docker-centos.sh
sudo ./install-docker-centos.sh
```

**脚本会自动完成以下操作：**
1. 更新系统包
2. 安装Docker和Docker Compose
3. 配置Docker镜像加速（使用阿里云镜像）
4. 配置防火墙（开放80、443、5000、22端口）
5. 将当前用户添加到docker组

### 步骤3: 验证Docker安装

```bash
# 验证Docker版本
docker --version

# 验证Docker Compose版本
docker compose version

# 测试Docker（可选）
docker run hello-world
```

### 步骤4: 重新登录（重要）

如果脚本将您添加到docker组，需要重新登录使配置生效：

```bash
# 退出SSH连接
exit

# 重新连接
ssh root@your-server-ip

# 或使用newgrp命令（无需重新登录）
newgrp docker
```

## 上传代码到服务器

### 方式一：使用SCP命令（推荐）

在Windows PowerShell或命令提示符中执行：

```powershell
# 进入项目目录
cd D:\selfCode\query-generator

# 上传整个项目到服务器（排除node_modules等）
scp -r -o StrictHostKeyChecking=no ^
    --exclude=node_modules ^
    --exclude=__pycache__ ^
    --exclude=.git ^
    . root@your-server-ip:/opt/query-generator
```

**注意**: Windows的scp可能不支持`--exclude`选项，可以使用以下方法：

#### 方法A：使用tar压缩后上传（推荐）

在Windows上（使用Git Bash或WSL）：

```bash
# 创建压缩包（排除不需要的文件）
tar --exclude='node_modules' \
    --exclude='__pycache__' \
    --exclude='.git' \
    --exclude='dist' \
    --exclude='*.log' \
    -czf query-generator.tar.gz .

# 上传压缩包
scp query-generator.tar.gz root@your-server-ip:/opt/

# 在服务器上解压
ssh root@your-server-ip
cd /opt
tar -xzf query-generator.tar.gz -C query-generator
cd query-generator
```

#### 方法B：使用WinSCP（图形界面，推荐新手）

1. 下载并安装 [WinSCP](https://winscp.net/)
2. 连接到服务器
3. 将项目文件夹拖拽到服务器的 `/opt/query-generator` 目录
4. 在WinSCP中排除不需要的文件夹（设置 → 首选项 → 传输 → 排除）

### 方式二：使用Git（如果项目在Git仓库）

在服务器上直接克隆：

```bash
# 安装Git（如果未安装）
yum install -y git

# 克隆项目
cd /opt
git clone your-repo-url query-generator
cd query-generator
```

## 部署应用

### 步骤1: 进入项目目录

```bash
cd /opt/query-generator
```

### 步骤2: 配置环境变量

```bash
# 复制环境变量模板
cp .env.example .env

# 编辑环境变量（根据实际情况修改）
vi .env
# 或使用nano
nano .env
```

**重要配置项说明：**

```bash
# 如果使用非root用户，建议修改端口（避免权限问题）
FRONTEND_PORT_HTTP=8080  # 改为8080或其他端口

# CORS配置（如果知道访问IP，建议指定具体IP）
CORS_ORIGINS=http://your-server-ip,http://your-server-ip:8080

# 资源限制（根据服务器配置调整）
BACKEND_MEMORY_LIMIT=512M
FRONTEND_MEMORY_LIMIT=256M
```

### 步骤3: 创建必要目录

```bash
mkdir -p logs/backend ssl
```

### 步骤4: 运行部署脚本

```bash
# 给部署脚本添加执行权限
chmod +x deploy.sh

# 运行部署脚本
./deploy.sh
```

部署脚本会自动：
1. 检查Docker环境
2. 检查端口占用
3. 创建必要目录
4. 构建Docker镜像
5. 启动服务

### 步骤5: 查看部署状态

```bash
# 查看容器状态
docker compose -f docker-compose.prod.yml ps

# 查看日志
docker compose -f docker-compose.prod.yml logs -f
```

## 验证部署

### 1. 检查服务状态

```bash
# 查看所有容器
docker compose -f docker-compose.prod.yml ps

# 应该看到两个容器运行中：
# - query-generator-backend-prod
# - query-generator-frontend-prod
```

### 2. 检查端口监听

```bash
# 检查端口是否监听
netstat -tuln | grep -E ':(80|443|5000) '
# 或
ss -tuln | grep -E ':(80|443|5000) '
```

### 3. 测试访问

在浏览器中访问：
- `http://your-server-ip` （如果使用80端口）
- `http://your-server-ip:8080` （如果使用8080端口）

### 4. 测试API

```bash
# 测试后端健康检查
curl http://localhost:5000/api/health

# 测试前端代理
curl http://localhost/api/health
```

## 常见问题排查

### 问题1: 端口被占用

**症状**: 部署时提示端口已被占用

**解决方案**:
```bash
# 查看端口占用
netstat -tuln | grep :80
# 或
ss -tuln | grep :80

# 停止占用端口的服务，或修改.env文件中的端口配置
```

### 问题2: 权限不足

**症状**: 无法绑定80或443端口

**解决方案**:
```bash
# 方案1: 使用sudo运行（不推荐）
sudo docker compose -f docker-compose.prod.yml up -d

# 方案2: 修改.env文件，使用非特权端口（推荐）
FRONTEND_PORT_HTTP=8080
```

### 问题3: Docker镜像拉取失败

**症状**: 构建时无法拉取基础镜像

**解决方案**:
```bash
# 检查Docker镜像加速配置
cat /etc/docker/daemon.json

# 重启Docker服务
systemctl restart docker

# 手动拉取镜像
docker pull python:3.11-slim
docker pull node:18-alpine
docker pull nginx:alpine
```

### 问题4: 防火墙阻止访问

**症状**: 本地无法访问服务器

**解决方案**:
```bash
# 检查防火墙状态
firewall-cmd --list-all

# 开放端口
firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --permanent --add-port=8080/tcp
firewall-cmd --reload

# 检查阿里云安全组规则（在阿里云控制台配置）
```

### 问题5: 容器无法启动

**症状**: 容器状态为Exited

**解决方案**:
```bash
# 查看容器日志
docker compose -f docker-compose.prod.yml logs backend
docker compose -f docker-compose.prod.yml logs frontend

# 查看详细错误信息
docker logs query-generator-backend-prod
docker logs query-generator-frontend-prod
```

### 问题6: 内存不足

**症状**: 容器频繁重启或OOM

**解决方案**:
```bash
# 检查内存使用
free -h
docker stats

# 修改.env文件，降低资源限制
BACKEND_MEMORY_LIMIT=256M
FRONTEND_MEMORY_LIMIT=128M
```

## 维护操作

### 查看日志

```bash
# 查看所有服务日志
docker compose -f docker-compose.prod.yml logs -f

# 查看特定服务日志
docker compose -f docker-compose.prod.yml logs -f backend
docker compose -f docker-compose.prod.yml logs -f frontend

# 查看最近100行日志
docker compose -f docker-compose.prod.yml logs --tail=100
```

### 重启服务

```bash
# 重启所有服务
docker compose -f docker-compose.prod.yml restart

# 重启特定服务
docker compose -f docker-compose.prod.yml restart backend
docker compose -f docker-compose.prod.yml restart frontend
```

### 停止服务

```bash
# 停止所有服务
docker compose -f docker-compose.prod.yml down

# 停止并删除数据卷（谨慎使用）
docker compose -f docker-compose.prod.yml down -v
```

### 更新应用

```bash
# 1. 上传新代码到服务器（使用SCP或Git pull）

# 2. 进入项目目录
cd /opt/query-generator

# 3. 重新构建并启动
docker compose -f docker-compose.prod.yml up -d --build

# 4. 查看日志确认启动成功
docker compose -f docker-compose.prod.yml logs -f
```

### 清理未使用的镜像

```bash
# 清理未使用的镜像和容器
docker system prune -a

# 仅清理未使用的镜像
docker image prune -a
```

### 备份和恢复

```bash
# 备份日志
tar -czf logs-backup-$(date +%Y%m%d).tar.gz logs/

# 备份环境配置
cp .env .env.backup

# 恢复环境配置
cp .env.backup .env
```

## 安全建议

1. **修改SSH默认端口**（可选）
2. **使用SSH密钥登录**，禁用密码登录
3. **定期更新系统**：`yum update -y`
4. **定期更新Docker**：`yum update docker-ce`
5. **限制CORS来源**：生产环境不要使用 `*`
6. **监控日志**：定期检查应用日志，发现异常及时处理
7. **配置防火墙**：只开放必要端口

## 性能优化

### 1. 调整Gunicorn Workers

根据CPU核心数调整：

```bash
# 在.env文件中
# 1核CPU: GUNICORN_WORKERS=2
# 2核CPU: GUNICORN_WORKERS=4
# 公式: (2 * CPU核心数) + 1
```

### 2. 调整资源限制

根据服务器实际配置调整内存和CPU限制。

### 3. 启用Gzip压缩

已在前端nginx配置中启用，无需额外配置。

## 技术支持

如遇到问题，请检查：
1. 服务器系统日志: `journalctl -xe`
2. Docker日志: `docker compose -f docker-compose.prod.yml logs`
3. 应用日志: `logs/backend/` 目录
4. 防火墙状态: `firewall-cmd --list-all`

## 快速命令参考

```bash
# 启动服务
docker compose -f docker-compose.prod.yml up -d

# 停止服务
docker compose -f docker-compose.prod.yml down

# 查看状态
docker compose -f docker-compose.prod.yml ps

# 查看日志
docker compose -f docker-compose.prod.yml logs -f

# 重启服务
docker compose -f docker-compose.prod.yml restart

# 更新应用
docker compose -f docker-compose.prod.yml up -d --build

# 进入容器
docker compose -f docker-compose.prod.yml exec backend bash
docker compose -f docker-compose.prod.yml exec frontend sh
```

