# 查询语句生成器 Web 应用

一个帮助开发者快速生成常用数据库和日志查询语句的Web应用。

## 功能特性

- 输入 goodsId、skuId、simGoodsId、simSkuId 四个ID
- 自动生成以下类型的查询语句：
  - MySQL 查询语句
  - Elasticsearch 查询 JSON
  - API 请求 JSON
  - Log 日志查询语句（两种模式）
- 一键复制生成的查询语句
- 美观的现代化UI界面

## 技术栈

- **后端**: Flask (Python)
- **前端**: Vue 3 + Vite
- **部署**: Docker + Docker Compose

## 快速开始

### 使用 Docker Compose（推荐）

**Windows 用户注意事项：**
- 确保已安装 Docker Desktop 并正在运行
- 如果端口 8080 被占用，可以修改 `docker-compose.yml` 中的端口映射
- 建议使用 PowerShell 或命令提示符（CMD）执行命令
- **如果遇到镜像拉取超时问题，请先执行 `pull-images.bat` 手动拉取镜像**

1. 克隆或下载项目到服务器

2. **如果遇到网络问题，先手动拉取镜像：**
   ```bash
   # 方式一：使用批处理文件（推荐）
   pull-images.bat
   
   # 方式二：手动执行命令
   docker pull python:3.11-slim
   docker pull node:18-alpine
   docker pull nginx:alpine
   ```

3. 在项目根目录执行：

```bash
# Docker Compose v2 (推荐)
docker compose up -d

# 或者使用旧版本命令（如果安装的是 v1）
docker-compose up -d
```

3. 访问应用

打开浏览器访问：
- Windows/Linux: `http://localhost:8080` 或 `http://服务器IP:8080`
- 如果使用端口 80（需要管理员权限）: `http://localhost` 或 `http://服务器IP`

### 本地开发

#### 后端开发

```bash
cd backend
pip install -r requirements.txt
python app.py
```

后端服务运行在 `http://localhost:5000`

#### 前端开发

```bash
cd frontend
npm install
npm run dev
```

前端服务运行在 `http://localhost:5173`

## 项目结构

```
query-generator/
├── backend/              # Flask 后端
│   ├── app.py           # 主应用
│   ├── query_generator.py  # 查询生成逻辑
│   ├── requirements.txt # Python 依赖
│   └── Dockerfile       # 后端 Docker 配置
├── frontend/            # Vue 前端
│   ├── src/             # 源代码
│   ├── package.json     # Node 依赖
│   ├── vite.config.js   # Vite 配置
│   └── Dockerfile       # 前端 Docker 配置
├── docker-compose.yml   # 容器编排
└── README.md            # 本文档
```

## API 接口

### POST /api/generate

生成查询语句

**请求体**:
```json
{
  "goodsId": "807708509179",
  "skuId": "1780376972946",
  "simGoodsId": "983723685861",
  "simSkuId": "5943842676368"
}
```

**响应**:
```json
{
  "mysql": "SELECT * FROM ...",
  "es": "{...}",
  "api": "[...]",
  "log1": "...",
  "log2": "..."
}
```

## 使用说明

1. 在输入框中填入 goodsId、skuId、simGoodsId、simSkuId
2. 系统会自动生成所有类型的查询语句
3. 点击"复制"按钮即可复制对应的查询语句
4. 将复制的查询语句粘贴到相应的工具中使用

## 停止服务

```bash
# Docker Compose v2
docker compose down

# 或者使用旧版本命令
docker-compose down
```

## 更新应用

```bash
# Docker Compose v2
docker compose down
docker compose up -d --build

# 或者使用旧版本命令
docker-compose down
docker-compose up -d --build
```

## 生产环境部署

### 快速部署

1. **上传项目到服务器**
   ```bash
   git clone <your-repo-url>
   cd query-generator
   ```

2. **运行自动部署脚本**
   ```bash
   chmod +x deploy.sh
   ./deploy.sh
   ```

3. **配置HTTPS（可选，推荐）**
   ```bash
   chmod +x ssl-setup.sh
   ./ssl-setup.sh
   ```

### 详细部署文档

请查看 [DEPLOYMENT.md](./DEPLOYMENT.md) 获取完整的生产环境部署指南，包括：
- 服务器选型建议
- 详细部署步骤
- HTTPS配置
- 维护和监控
- 故障排查

### 服务器配置建议

**最低配置（10人以下）**：
- CPU: 1核
- 内存: 2GB
- 存储: 20GB SSD
- 推荐: 阿里云/腾讯云轻量应用服务器（约50-100元/月）

**推荐配置（10-50人）**：
- CPU: 2核
- 内存: 4GB
- 存储: 40GB SSD
- 推荐: 阿里云ECS t6实例或腾讯云CVM标准型（约200-300元/月）

