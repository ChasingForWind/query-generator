#!/bin/bash

# 使用国内镜像仓库直接拉取镜像的脚本
# 如果镜像加速器配置不生效，可以使用此脚本修改 Dockerfile 使用国内镜像仓库

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=========================================="
echo "配置使用国内镜像仓库"
echo "=========================================="

# 测试镜像源是否可用
test_mirror() {
    local mirror=$1
    local image=$2
    echo -n "测试 $mirror ... "
    if timeout 5 docker pull "$mirror/$image" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ 可用${NC}"
        return 0
    else
        echo -e "${RED}✗ 不可用${NC}"
        return 1
    fi
}

echo -e "\n${BLUE}测试可用的镜像源...${NC}"

# 测试不同的镜像源
MIRRORS=(
    "ccr.ccs.tencentyun.com/library"
    "hub-mirror.c.163.com/library"
    "docker.mirrors.ustc.edu.cn/library"
)

TEST_IMAGE="python:3.11-slim"
AVAILABLE_MIRROR=""

for mirror in "${MIRRORS[@]}"; do
    if test_mirror "$mirror" "$TEST_IMAGE"; then
        AVAILABLE_MIRROR="$mirror"
        break
    fi
done

if [ -z "$AVAILABLE_MIRROR" ]; then
    echo -e "${YELLOW}未找到可用的镜像源，使用腾讯云镜像（默认）${NC}"
    AVAILABLE_MIRROR="ccr.ccs.tencentyun.com/library"
fi

echo -e "\n${GREEN}使用镜像源: $AVAILABLE_MIRROR${NC}"

# 备份原始 Dockerfile
echo -e "\n${BLUE}备份原始 Dockerfile...${NC}"
if [ -f backend/Dockerfile ]; then
    cp backend/Dockerfile backend/Dockerfile.backup
    echo "✓ 已备份 backend/Dockerfile"
fi
if [ -f frontend/Dockerfile ]; then
    cp frontend/Dockerfile frontend/Dockerfile.backup
    echo "✓ 已备份 frontend/Dockerfile"
fi

# 修改 backend/Dockerfile
if [ -f backend/Dockerfile ]; then
    echo -e "\n${BLUE}修改 backend/Dockerfile...${NC}"
    sed -i "s|^FROM python:3.11-slim|FROM $AVAILABLE_MIRROR/python:3.11-slim|" backend/Dockerfile
    echo "✓ 已修改 backend/Dockerfile"
fi

# 修改 frontend/Dockerfile
if [ -f frontend/Dockerfile ]; then
    echo -e "\n${BLUE}修改 frontend/Dockerfile...${NC}"
    sed -i "s|^FROM node:18-alpine|FROM $AVAILABLE_MIRROR/node:18-alpine|" frontend/Dockerfile
    sed -i "s|^FROM nginx:alpine|FROM $AVAILABLE_MIRROR/nginx:alpine|" frontend/Dockerfile
    echo "✓ 已修改 frontend/Dockerfile"
fi

echo -e "\n${GREEN}=========================================="
echo "配置完成！"
echo "==========================================${NC}"
echo ""
echo "已使用镜像源: $AVAILABLE_MIRROR"
echo "备份文件: *.backup"
echo ""
echo "现在可以运行: ./deploy.sh"


