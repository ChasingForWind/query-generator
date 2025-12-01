#!/bin/bash

# Docker 镜像加速器配置脚本
# 用于配置国内 Docker 镜像加速器，解决拉取镜像超时问题

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "=========================================="
echo "Docker 镜像加速器配置脚本"
echo "=========================================="

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}错误: 此脚本需要 root 权限${NC}"
    echo "请使用: sudo ./configure-docker-mirror.sh"
    exit 1
fi

# 检查Docker是否安装
if ! command -v docker &> /dev/null; then
    echo -e "${RED}错误: Docker未安装${NC}"
    exit 1
fi

echo -e "\n${BLUE}[1/5] 备份现有配置...${NC}"
if [ -f /etc/docker/daemon.json ]; then
    BACKUP_FILE="/etc/docker/daemon.json.backup.$(date +%Y%m%d_%H%M%S)"
    cp /etc/docker/daemon.json "$BACKUP_FILE"
    echo -e "${GREEN}✓ 已备份到 $BACKUP_FILE${NC}"
else
    echo -e "${YELLOW}未找到现有配置，将创建新配置${NC}"
fi

echo -e "\n${BLUE}[2/5] 配置镜像加速器...${NC}"
mkdir -p /etc/docker

# 创建新的 daemon.json 配置
# 使用多个国内镜像加速器，Docker会按顺序尝试
cat > /etc/docker/daemon.json << 'EOF'
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com",
    "https://mirror.baidubce.com",
    "https://dockerproxy.com",
    "https://docker.nju.edu.cn",
    "https://6cuqr5nu.mirror.aliyuncs.com"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

echo -e "${GREEN}✓ 配置文件已创建${NC}"
echo "配置内容:"
cat /etc/docker/daemon.json | python3 -m json.tool 2>/dev/null || cat /etc/docker/daemon.json

echo -e "\n${BLUE}[3/5] 验证JSON格式...${NC}"
if command -v python3 &> /dev/null; then
    if python3 -m json.tool /etc/docker/daemon.json > /dev/null 2>&1; then
        echo -e "${GREEN}✓ JSON格式正确${NC}"
    else
        echo -e "${RED}✗ JSON格式错误！${NC}"
        exit 1
    fi
elif command -v python &> /dev/null; then
    if python -m json.tool /etc/docker/daemon.json > /dev/null 2>&1; then
        echo -e "${GREEN}✓ JSON格式正确${NC}"
    else
        echo -e "${RED}✗ JSON格式错误！${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}警告: 未找到Python，无法验证JSON格式${NC}"
fi

echo -e "\n${BLUE}[4/5] 重启Docker服务...${NC}"
systemctl daemon-reload
if systemctl restart docker; then
    echo -e "${GREEN}✓ Docker服务已重启${NC}"
else
    echo -e "${RED}✗ Docker服务重启失败${NC}"
    exit 1
fi

# 等待Docker启动
echo "等待Docker启动..."
sleep 3

echo -e "\n${BLUE}[5/5] 验证配置是否生效...${NC}"
if docker info 2>/dev/null | grep -q "Registry Mirrors" && docker info 2>/dev/null | grep -A 5 "Registry Mirrors" | grep -q "http"; then
    echo -e "${GREEN}✓ 镜像加速器配置成功并已生效！${NC}"
    echo ""
    echo "当前配置的镜像加速器:"
    docker info 2>/dev/null | grep -A 5 "Registry Mirrors"
    echo ""
    echo -e "${GREEN}=========================================="
    echo "配置完成！可以开始使用 Docker 构建镜像了"
    echo "==========================================${NC}"
else
    echo -e "${RED}✗ 配置可能未生效${NC}"
    echo ""
    echo "请检查:"
    echo "  1. Docker服务状态: systemctl status docker"
    echo "  2. Docker日志: journalctl -u docker.service -n 50"
    echo "  3. 配置文件: cat /etc/docker/daemon.json"
    echo ""
    echo "当前 Docker 信息:"
    docker info 2>/dev/null | grep -A 5 "Registry Mirrors" || echo "  未找到镜像加速器配置"
    exit 1
fi

