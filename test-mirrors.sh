#!/bin/bash

# 测试国内镜像源可用性的脚本

echo "=========================================="
echo "测试国内 Docker 镜像源可用性"
echo "=========================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 要测试的镜像源列表
MIRRORS=(
    "ccr.ccs.tencentyun.com/library"
    "hub-mirror.c.163.com/library"
    "docker.mirrors.ustc.edu.cn/library"
    "mirror.baidubce.com/library"
    "docker.nju.edu.cn/library"
)

TEST_IMAGE="python:3.11-slim"
AVAILABLE_MIRRORS=()

echo -e "\n${BLUE}测试镜像: $TEST_IMAGE${NC}\n"

for mirror in "${MIRRORS[@]}"; do
    full_image="$mirror/$TEST_IMAGE"
    echo -n "测试 $mirror ... "
    
    # 先测试 DNS 解析
    hostname=$(echo "$mirror" | cut -d'/' -f1)
    if ! getent hosts "$hostname" > /dev/null 2>&1; then
        echo -e "${RED}✗ DNS 解析失败${NC}"
        continue
    fi
    
    # 测试拉取镜像（只拉取元数据，不下载完整镜像）
    if timeout 10 docker pull "$full_image" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ 可用${NC}"
        AVAILABLE_MIRRORS+=("$mirror")
    else
        echo -e "${RED}✗ 不可用${NC}"
    fi
done

echo -e "\n${GREEN}=========================================="
echo "测试结果"
echo "==========================================${NC}"

if [ ${#AVAILABLE_MIRRORS[@]} -eq 0 ]; then
    echo -e "${RED}未找到可用的镜像源！${NC}"
    echo ""
    echo "建议："
    echo "  1. 检查网络连接"
    echo "  2. 检查 DNS 配置"
    echo "  3. 尝试使用代理"
    exit 1
else
    echo -e "${GREEN}找到 ${#AVAILABLE_MIRRORS[@]} 个可用的镜像源:${NC}"
    for mirror in "${AVAILABLE_MIRRORS[@]}"; do
        echo "  ✓ $mirror"
    done
    
    echo ""
    echo -e "${BLUE}推荐使用第一个可用的镜像源: ${AVAILABLE_MIRRORS[0]}${NC}"
    echo ""
    echo "修改 Dockerfile 使用此镜像源:"
    echo "  backend/Dockerfile:"
    echo "    FROM ${AVAILABLE_MIRRORS[0]}/python:3.11-slim"
    echo ""
    echo "  frontend/Dockerfile:"
    echo "    FROM ${AVAILABLE_MIRRORS[0]}/node:18-alpine AS build"
    echo "    FROM ${AVAILABLE_MIRRORS[0]}/nginx:alpine"
fi


