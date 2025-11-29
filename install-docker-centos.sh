#!/bin/bash

# CentOS服务器Docker环境初始化脚本
# 适用于阿里云CentOS轻量级服务器

set -e  # 遇到错误立即退出

echo "=========================================="
echo "CentOS Docker环境初始化脚本"
echo "=========================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检查是否为root用户
check_root() {
    if [ "$EUID" -ne 0 ]; then 
        echo -e "${RED}错误: 此脚本需要root权限运行${NC}"
        echo "请使用: sudo $0"
        exit 1
    fi
}

# 检测CentOS版本
detect_centos_version() {
    echo -e "\n${BLUE}[1/7] 检测系统版本...${NC}"
    
    if [ -f /etc/redhat-release ]; then
        CENTOS_VERSION=$(cat /etc/redhat-release)
        echo -e "${GREEN}系统版本: $CENTOS_VERSION${NC}"
    else
        echo -e "${YELLOW}警告: 无法检测CentOS版本，继续执行...${NC}"
    fi
}

# 更新系统
update_system() {
    echo -e "\n${BLUE}[2/7] 更新系统包...${NC}"
    
    yum update -y
    
    # 安装必要工具
    echo "安装必要工具..."
    yum install -y curl wget git vim net-tools
    
    echo -e "${GREEN}✓ 系统更新完成${NC}"
}

# 卸载旧版本Docker（如果存在）
remove_old_docker() {
    echo -e "\n${BLUE}[3/7] 检查并卸载旧版本Docker...${NC}"
    
    yum remove -y docker docker-client docker-client-latest docker-common \
        docker-latest docker-latest-logrotate docker-logrotate docker-engine 2>/dev/null || true
    
    echo -e "${GREEN}✓ 旧版本清理完成${NC}"
}

# 安装Docker
install_docker() {
    echo -e "\n${BLUE}[4/7] 安装Docker...${NC}"
    
    # 安装Docker依赖
    yum install -y yum-utils device-mapper-persistent-data lvm2
    
    # 添加Docker官方仓库（使用阿里云镜像加速）
    yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
    
    # 安装Docker CE
    yum install -y docker-ce docker-ce-cli containerd.io
    
    # 启动Docker服务
    systemctl start docker
    systemctl enable docker
    
    # 验证Docker安装
    docker --version
    
    echo -e "${GREEN}✓ Docker安装完成${NC}"
}

# 配置Docker镜像加速（使用阿里云镜像）
configure_docker_mirror() {
    echo -e "\n${BLUE}[5/7] 配置Docker镜像加速...${NC}"
    
    # 创建或更新daemon.json
    mkdir -p /etc/docker
    
    cat > /etc/docker/daemon.json << 'EOF'
{
  "registry-mirrors": [
    "https://registry.cn-hangzhou.aliyuncs.com",
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF
    
    # 重启Docker使配置生效
    systemctl daemon-reload
    systemctl restart docker
    
    echo -e "${GREEN}✓ Docker镜像加速配置完成${NC}"
}

# 安装Docker Compose
install_docker_compose() {
    echo -e "\n${BLUE}[6/7] 安装Docker Compose...${NC}"
    
    # 安装Docker Compose插件（推荐方式）
    yum install -y docker-compose-plugin
    
    # 验证安装
    docker compose version
    
    echo -e "${GREEN}✓ Docker Compose安装完成${NC}"
}

# 配置防火墙
configure_firewall() {
    echo -e "\n${BLUE}[7/7] 配置防火墙...${NC}"
    
    # 检查firewalld是否运行
    if systemctl is-active --quiet firewalld; then
        echo "firewalld正在运行，配置防火墙规则..."
        
        # 开放必要端口
        firewall-cmd --permanent --add-port=80/tcp    # HTTP
        firewall-cmd --permanent --add-port=443/tcp   # HTTPS（预留）
        firewall-cmd --permanent --add-port=5000/tcp  # 后端API（可选）
        firewall-cmd --permanent --add-port=22/tcp    # SSH
        
        # 重新加载防火墙
        firewall-cmd --reload
        
        echo -e "${GREEN}✓ 防火墙配置完成${NC}"
        echo "已开放端口: 22(SSH), 80(HTTP), 443(HTTPS), 5000(API)"
    else
        echo -e "${YELLOW}警告: firewalld未运行，跳过防火墙配置${NC}"
        echo "如果使用其他防火墙工具，请手动开放以下端口: 22, 80, 443, 5000"
    fi
}

# 配置用户权限
configure_user_permissions() {
    echo -e "\n${BLUE}配置用户权限...${NC}"
    
    # 获取当前登录用户（如果不是root）
    if [ -n "$SUDO_USER" ]; then
        DOCKER_USER="$SUDO_USER"
    elif [ -n "$USER" ] && [ "$USER" != "root" ]; then
        DOCKER_USER="$USER"
    else
        echo -e "${YELLOW}无法确定非root用户，跳过用户组配置${NC}"
        echo -e "${YELLOW}提示: 手动执行以下命令将用户添加到docker组:${NC}"
        echo "  sudo usermod -aG docker <username>"
        echo "  然后重新登录使配置生效"
        return
    fi
    
    # 将用户添加到docker组
    usermod -aG docker "$DOCKER_USER"
    
    echo -e "${GREEN}✓ 已将用户 $DOCKER_USER 添加到docker组${NC}"
    echo -e "${YELLOW}提示: 需要重新登录或执行 'newgrp docker' 才能使配置生效${NC}"
}

# 显示完成信息
show_completion() {
    echo -e "\n${GREEN}=========================================="
    echo "Docker环境初始化完成！"
    echo "==========================================${NC}"
    
    echo -e "\n已安装的组件:"
    echo "  - Docker: $(docker --version | cut -d ' ' -f3 | cut -d ',' -f1)"
    echo "  - Docker Compose: $(docker compose version | cut -d ' ' -f4)"
    
    echo -e "\n下一步操作:"
    echo "1. 如果当前用户已添加到docker组，请重新登录或执行: newgrp docker"
    echo "2. 验证Docker安装: docker run hello-world"
    echo "3. 上传项目代码到服务器"
    echo "4. 运行部署脚本: ./deploy.sh"
    
    echo -e "\n常用命令:"
    echo "  - 查看Docker状态: systemctl status docker"
    echo "  - 启动Docker: systemctl start docker"
    echo "  - 停止Docker: systemctl stop docker"
    echo "  - 查看防火墙状态: firewall-cmd --list-all"
}

# 主函数
main() {
    check_root
    detect_centos_version
    update_system
    remove_old_docker
    install_docker
    configure_docker_mirror
    install_docker_compose
    configure_firewall
    configure_user_permissions
    show_completion
}

# 执行主函数
main

