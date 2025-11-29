# 快速开始指南

## 本地开发

### 方式一：直接运行（无需Docker）

**后端：**
```bash
cd backend
pip install -r requirements.txt
python app.py
```

**前端：**
```bash
cd frontend
npm install
npm run dev
```

访问：http://localhost:5173

### 方式二：使用Docker（开发环境）

```bash
# 使用开发配置
docker compose -f docker-compose.dev.yml up -d

# 或使用默认配置
docker compose up -d
```

访问：http://localhost:8080

## 生产环境部署

### 一键部署

```bash
chmod +x deploy.sh
./deploy.sh
```

### 手动部署

```bash
# 1. 配置环境变量
cp .env.example .env
# 编辑 .env 文件

# 2. 启动服务
docker compose -f docker-compose.prod.yml up -d --build
```

### 配置HTTPS

```bash
chmod +x ssl-setup.sh
./ssl-setup.sh
```

详细说明请查看 [DEPLOYMENT.md](./DEPLOYMENT.md)

## 常用命令

```bash
# 查看服务状态
docker compose -f docker-compose.prod.yml ps

# 查看日志
docker compose -f docker-compose.prod.yml logs -f

# 重启服务
docker compose -f docker-compose.prod.yml restart

# 停止服务
docker compose -f docker-compose.prod.yml down
```

