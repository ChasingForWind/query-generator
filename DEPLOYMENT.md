# 生产环境部署文档

本文档介绍如何将查询生成器项目部署到Linux生产服务器。

## 目录

- [服务器要求](#服务器要求)
- [前置准备](#前置准备)
- [部署步骤](#部署步骤)
- [HTTPS配置](#https配置)
- [维护和监控](#维护和监控)
- [故障排查](#故障排查)

## 服务器要求

### 最低配置（10人以下小团队）

- **CPU**: 1核
- **内存**: 2GB
- **存储**: 20GB SSD
- **带宽**: 1-3Mbps
- **操作系统**: Ubuntu 22.04 LTS 或 CentOS 7/8
- **推荐云服务商**: 
  - 阿里云轻量应用服务器（约50-100元/月）
  - 腾讯云轻量应用服务器（约50-100元/月）

### 推荐配置（10-50人）

- **CPU**: 2核
- **内存**: 4GB
- **存储**: 40GB SSD
- **带宽**: 3-5Mbps
- **推荐云服务商**:
  - 阿里云ECS t6实例（约200-300元/月）
  - 腾讯云CVM标准型（约200-300元/月）

### 系统要求

- Docker 20.10+
- Docker Compose 2.0+（或docker-compose 1.29+）
- 开放端口: 80（HTTP）、443（HTTPS）、5000（后端，可选）

## 前置准备

### 1. 服务器初始化

```bash
# 更新系统
sudo apt-get update && sudo apt-get upgrade -y  # Ubuntu/Debian
# 或
sudo yum update -y  # CentOS/RHEL

# 安装必要工具
sudo apt-get install -y curl wget git  # Ubuntu/Debian
# 或
sudo yum install -y curl wget git  # CentOS/RHEL
```

### 2. 安装Docker

```bash
# 使用官方脚本安装（推荐）
curl -fsSL https://get.docker.com | sh

# 启动Docker服务
sudo systemctl start docker
sudo systemctl enable docker

# 将当前用户添加到docker组（避免每次使用sudo）
sudo usermod -aG docker $USER
# 需要重新登录才能生效
```

### 3. 安装Docker Compose

```bash
# Ubuntu/Debian
sudo apt-get install docker-compose-plugin

# CentOS/RHEL
sudo yum install docker-compose-plugin

# 验证安装
docker compose version
```

### 4. 配置防火墙

```bash
# Ubuntu (UFW)
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 22/tcp  # SSH
sudo ufw enable

# CentOS (firewalld)
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=443/tcp
sudo firewall-cmd --permanent --add-port=22/tcp
sudo firewall-cmd --reload
```

### 5. 域名解析（如果使用域名）

在域名服务商处添加A记录，将域名指向服务器IP：
- 记录类型: A
- 主机记录: @ 或 www
- 记录值: 服务器公网IP

## 部署步骤

### 方式一：使用自动部署脚本（推荐）

```bash
# 1. 上传项目到服务器（使用git或scp）
git clone <your-repo-url>
cd query-generator

# 或使用scp从本地上传
# scp -r query-generator user@server:/path/to/

# 2. 给部署脚本执行权限
chmod +x deploy.sh

# 3. 运行部署脚本
./deploy.sh
```

### 方式二：手动部署

```bash
# 1. 进入项目目录
cd query-generator

# 2. 创建环境变量文件
cp .env.example .env
# 编辑 .env 文件，设置域名、端口等配置
nano .env

# 3. 创建必要目录
mkdir -p logs/backend ssl

# 4. 构建并启动服务
docker compose -f docker-compose.prod.yml up -d --build

# 5. 查看服务状态
docker compose -f docker-compose.prod.yml ps

# 6. 查看日志
docker compose -f docker-compose.prod.yml logs -f
```

### 环境变量配置

编辑 `.env` 文件，主要配置项：

```bash
# 域名配置（用于nginx）
DOMAIN=your-domain.com

# CORS配置（生产环境建议指定具体域名）
CORS_ORIGINS=https://your-domain.com,https://www.your-domain.com

# Gunicorn工作进程数（推荐: (2 * CPU核心数) + 1）
GUNICORN_WORKERS=2

# 资源限制（根据服务器配置调整）
BACKEND_MEMORY_LIMIT=512M
FRONTEND_MEMORY_LIMIT=256M
```

## HTTPS配置

### 使用Let's Encrypt免费证书

```bash
# 1. 安装certbot
sudo apt-get install certbot  # Ubuntu/Debian
# 或
sudo yum install certbot  # CentOS/RHEL

# 2. 运行SSL配置脚本
chmod +x ssl-setup.sh
./ssl-setup.sh

# 3. 修改 docker-compose.prod.yml
# 取消frontend服务中SSL相关volumes的注释：
# volumes:
#   - ./ssl:/etc/nginx/ssl:ro
#   - ./frontend/nginx-ssl.conf:/etc/nginx/conf.d/default.conf:ro

# 4. 重启服务
docker compose -f docker-compose.prod.yml restart frontend
```

### 手动配置SSL证书

如果已有SSL证书：

```bash
# 1. 将证书文件放到 ssl 目录
mkdir -p ssl
cp your-fullchain.pem ssl/fullchain.pem
cp your-privkey.pem ssl/privkey.pem

# 2. 修改 frontend/nginx-ssl.conf 中的域名

# 3. 修改 docker-compose.prod.yml，启用SSL配置

# 4. 重启服务
docker compose -f docker-compose.prod.yml restart frontend
```

## 维护和监控

### 查看服务状态

```bash
docker compose -f docker-compose.prod.yml ps
```

### 查看日志

```bash
# 查看所有服务日志
docker compose -f docker-compose.prod.yml logs -f

# 查看特定服务日志
docker compose -f docker-compose.prod.yml logs -f backend
docker compose -f docker-compose.prod.yml logs -f frontend
```

### 重启服务

```bash
# 重启所有服务
docker compose -f docker-compose.prod.yml restart

# 重启特定服务
docker compose -f docker-compose.prod.yml restart backend
```

### 更新应用

```bash
# 1. 拉取最新代码
git pull

# 2. 重新构建并启动
docker compose -f docker-compose.prod.yml up -d --build

# 3. 查看日志确认启动成功
docker compose -f docker-compose.prod.yml logs -f
```

### 健康检查

```bash
# 检查后端健康状态
curl http://localhost:5000/api/health

# 检查前端（通过nginx代理）
curl http://localhost/api/health
```

### 备份

```bash
# 备份日志
tar -czf logs-backup-$(date +%Y%m%d).tar.gz logs/

# 备份SSL证书
tar -czf ssl-backup-$(date +%Y%m%d).tar.gz ssl/
```

## 故障排查

### 服务无法启动

1. **检查Docker服务状态**
   ```bash
   sudo systemctl status docker
   ```

2. **检查端口占用**
   ```bash
   sudo netstat -tuln | grep -E ':(80|443|5000) '
   # 或
   sudo ss -tuln | grep -E ':(80|443|5000) '
   ```

3. **查看详细错误日志**
   ```bash
   docker compose -f docker-compose.prod.yml logs
   ```

### 无法访问网站

1. **检查防火墙**
   ```bash
   sudo ufw status  # Ubuntu
   sudo firewall-cmd --list-all  # CentOS
   ```

2. **检查容器状态**
   ```bash
   docker compose -f docker-compose.prod.yml ps
   ```

3. **检查nginx配置**
   ```bash
   docker compose -f docker-compose.prod.yml exec frontend nginx -t
   ```

### 性能问题

1. **检查资源使用**
   ```bash
   docker stats
   ```

2. **调整资源限制**
   编辑 `.env` 文件，增加内存和CPU限制

3. **优化Gunicorn配置**
   根据服务器CPU核心数调整 `GUNICORN_WORKERS`

### SSL证书问题

1. **检查证书有效期**
   ```bash
   sudo certbot certificates
   ```

2. **手动续期证书**
   ```bash
   sudo certbot renew
   ```

3. **检查证书文件权限**
   ```bash
   ls -la ssl/
   ```

## 常用命令速查

```bash
# 启动服务
docker compose -f docker-compose.prod.yml up -d

# 停止服务
docker compose -f docker-compose.prod.yml down

# 查看日志
docker compose -f docker-compose.prod.yml logs -f

# 重启服务
docker compose -f docker-compose.prod.yml restart

# 更新应用
docker compose -f docker-compose.prod.yml up -d --build

# 进入容器
docker compose -f docker-compose.prod.yml exec backend bash
docker compose -f docker-compose.prod.yml exec frontend sh

# 清理未使用的镜像
docker system prune -a
```

## 安全建议

1. **定期更新系统和Docker**
   ```bash
   sudo apt-get update && sudo apt-get upgrade
   ```

2. **使用强密码和SSH密钥**
3. **定期备份数据**
4. **监控日志，及时发现异常**
5. **限制CORS来源**（生产环境不要使用 `*`）
6. **使用HTTPS加密传输**
7. **定期更新应用依赖**

## 技术支持

如遇到问题，请检查：
1. 服务器系统日志: `journalctl -xe`
2. Docker日志: `docker compose -f docker-compose.prod.yml logs`
3. 应用日志: `logs/backend/` 目录

