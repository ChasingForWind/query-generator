# 构建阶段 - 使用阿里云镜像加速器拉取基础镜像
FROM 6cuqr5nu.mirror.aliyuncs.com/library/node:18-alpine AS build

WORKDIR /app

# 配置 npm 使用国内镜像源（加速 Node 包下载）
RUN npm config set registry https://registry.npmmirror.com && \
    npm config set fetch-retries 3 && \
    npm config set fetch-retry-mintimeout 20000 && \
    npm config set fetch-retry-maxtimeout 120000

# 复制 package 文件（利用 Docker 缓存层）
COPY package.json ./

# 安装依赖（这一步会较慢，但只需要运行一次）
# 如果 package.json 没变化，Docker 会使用缓存，不会重新安装
# 使用 --legacy-peer-deps 和 --no-audit 加速安装
RUN npm install --legacy-peer-deps --no-audit --verbose=false

# 复制源代码
COPY . .

# 构建应用（使用环境变量加速构建）
ENV NODE_OPTIONS="--max-old-space-size=4096"
ENV NODE_ENV=production
# 使用 vite 的快速构建模式
RUN npm run build

# 运行阶段 - 使用阿里云镜像加速器拉取基础镜像
FROM 6cuqr5nu.mirror.aliyuncs.com/library/nginx:alpine

# 复制构建产物到 nginx
COPY --from=build /app/dist /usr/share/nginx/html

# 复制 nginx 配置
COPY nginx.conf /etc/nginx/conf.d/default.conf

# 暴露端口
EXPOSE 80

# 启动 nginx
CMD ["nginx", "-g", "daemon off;"]

