# Docker 镜像加速器问题排查指南

## 问题现象
即使配置了镜像加速器，Docker 仍然尝试从 `registry-1.docker.io` 拉取镜像，导致超时。

## 诊断步骤

### 1. 验证配置是否生效

```bash
# 检查配置文件
cat /etc/docker/daemon.json

# 检查 Docker 信息中的镜像加速器
docker info | grep -A 10 "Registry Mirrors"

# 如果看不到镜像加速器地址，说明配置未生效
```

### 2. 检查 Docker 服务状态

```bash
# 检查 Docker 服务状态
sudo systemctl status docker

# 查看 Docker 日志
sudo journalctl -u docker.service -n 50
```

### 3. 如果镜像加速器配置不生效

可能的原因：
- Docker 服务未正确重启
- JSON 格式错误
- 镜像加速器地址不可用

## 解决方案

### 方案1：使用国内镜像仓库直接拉取（推荐）

如果镜像加速器配置不生效，可以直接修改 Dockerfile 使用国内镜像仓库：

#### 腾讯云镜像（推荐，较稳定）

修改 `backend/Dockerfile`:
```dockerfile
FROM ccr.ccs.tencentyun.com/library/python:3.11-slim
```

修改 `frontend/Dockerfile`:
```dockerfile
FROM ccr.ccs.tencentyun.com/library/node:18-alpine AS build
FROM ccr.ccs.tencentyun.com/library/nginx:alpine
```

#### 网易镜像

修改 `backend/Dockerfile`:
```dockerfile
FROM hub-mirror.c.163.com/library/python:3.11-slim
```

修改 `frontend/Dockerfile`:
```dockerfile
FROM hub-mirror.c.163.com/library/node:18-alpine AS build
FROM hub-mirror.c.163.com/library/nginx:alpine
```

#### 中科大镜像

修改 `backend/Dockerfile`:
```dockerfile
FROM docker.mirrors.ustc.edu.cn/library/python:3.11-slim
```

修改 `frontend/Dockerfile`:
```dockerfile
FROM docker.mirrors.ustc.edu.cn/library/node:18-alpine AS build
FROM docker.mirrors.ustc.edu.cn/library/nginx:alpine
```

### 方案2：手动拉取镜像并重新标记

```bash
# 从国内镜像源拉取
docker pull ccr.ccs.tencentyun.com/library/python:3.11-slim

# 重新标记为标准名称
docker tag ccr.ccs.tencentyun.com/library/python:3.11-slim python:3.11-slim

# 然后使用标准 Dockerfile 构建
```

### 方案3：修复镜像加速器配置

```bash
# 1. 确保 JSON 格式正确
sudo cat /etc/docker/daemon.json

# 2. 如果格式有问题，重新创建
sudo tee /etc/docker/daemon.json > /dev/null <<-'EOF'
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com",
    "https://mirror.baidubce.com"
  ]
}
EOF

# 3. 重启 Docker（重要！）
sudo systemctl daemon-reload
sudo systemctl stop docker
sudo systemctl start docker

# 4. 验证
docker info | grep -A 10 "Registry Mirrors"
```

## 快速测试脚本

在服务器上运行以下命令测试镜像源：

```bash
# 测试腾讯云镜像
docker pull ccr.ccs.tencentyun.com/library/python:3.11-slim

# 测试网易镜像
docker pull hub-mirror.c.163.com/library/python:3.11-slim

# 测试中科大镜像
docker pull docker.mirrors.ustc.edu.cn/library/python:3.11-slim
```

哪个能成功拉取，就使用哪个镜像源。

## 推荐配置

如果镜像加速器无法配置，建议直接修改 Dockerfile 使用腾讯云镜像：

**backend/Dockerfile:**
```dockerfile
FROM ccr.ccs.tencentyun.com/library/python:3.11-slim
```

**frontend/Dockerfile:**
```dockerfile
FROM ccr.ccs.tencentyun.com/library/node:18-alpine AS build
FROM ccr.ccs.tencentyun.com/library/nginx:alpine
```

这样可以直接从国内镜像源拉取，不依赖镜像加速器配置。


