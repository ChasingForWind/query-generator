#!/bin/bash

# Docker 镜像加速器诊断脚本

echo "=========================================="
echo "Docker 镜像加速器诊断"
echo "=========================================="

echo -e "\n[1] 检查配置文件..."
if [ -f /etc/docker/daemon.json ]; then
    echo "✓ 配置文件存在: /etc/docker/daemon.json"
    echo "配置内容:"
    cat /etc/docker/daemon.json | python3 -m json.tool 2>/dev/null || cat /etc/docker/daemon.json
else
    echo "✗ 配置文件不存在: /etc/docker/daemon.json"
fi

echo -e "\n[2] 检查 Docker 服务状态..."
systemctl status docker --no-pager -l | head -10

echo -e "\n[3] 检查 Docker 信息中的镜像加速器配置..."
if docker info 2>/dev/null | grep -A 10 "Registry Mirrors"; then
    echo "✓ 镜像加速器已配置"
else
    echo "✗ 镜像加速器未在 Docker 信息中显示"
fi

echo -e "\n[4] 检查 Docker 日志（最近50行）..."
journalctl -u docker.service -n 50 --no-pager | grep -i "mirror\|registry\|error" || echo "未找到相关日志"

echo -e "\n[5] 测试镜像拉取..."
echo "尝试拉取测试镜像..."
timeout 10 docker pull hello-world:latest 2>&1 | head -20 || echo "拉取超时或失败"

echo -e "\n=========================================="
echo "诊断完成"
echo "=========================================="


