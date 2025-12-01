#!/bin/bash

# 查询生成器项目部署脚本
# 适用于Linux服务器（Ubuntu/CentOS）

set -e  # 遇到错误立即退出

echo "=========================================="
echo "查询生成器项目部署脚本"
echo "=========================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查是否为root用户
check_root() {
    if [ "$EUID" -eq 0 ]; then 
        echo -e "${YELLOW}警告: 不建议使用root用户运行，建议使用sudo${NC}"
    fi
}

# 检查Docker是否安装
check_docker() {
    echo -e "\n${GREEN}[1/6] 检查Docker环境...${NC}"
    
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}错误: Docker未安装${NC}"
        echo "请先安装Docker:"
        echo "  Ubuntu/Debian: curl -fsSL https://get.docker.com | sh"
        echo "  CentOS/RHEL: curl -fsSL https://get.docker.com | sh"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        echo -e "${RED}错误: Docker Compose未安装${NC}"
        echo "请安装Docker Compose v2:"
        echo "  sudo apt-get update && sudo apt-get install docker-compose-plugin"
        exit 1
    fi
    
    echo -e "${GREEN}✓ Docker环境检查通过${NC}"
    docker --version
    docker compose version 2>/dev/null || docker-compose --version
}

# 检查端口是否被占用
check_ports() {
    echo -e "\n${GREEN}[2/6] 检查端口占用...${NC}"
    
    # 从.env文件读取端口配置（如果存在）
    local ports=(80 443 5000)
    if [ -f .env ]; then
        FRONTEND_PORT=$(grep "^FRONTEND_PORT_HTTP=" .env | cut -d '=' -f2 | tr -d ' ' 2>/dev/null || echo "")
        BACKEND_PORT=$(grep "^BACKEND_PORT=" .env | cut -d '=' -f2 | tr -d ' ' 2>/dev/null || echo "")
        
        if [ ! -z "$FRONTEND_PORT" ] && [ "$FRONTEND_PORT" != "80" ]; then
            ports=($FRONTEND_PORT 443 ${ports[@]})
        fi
        if [ ! -z "$BACKEND_PORT" ] && [ "$BACKEND_PORT" != "5000" ]; then
            ports=(${ports[@]} $BACKEND_PORT)
        fi
    fi
    
    local occupied=()
    
    for port in "${ports[@]}"; do
        if command -v netstat &> /dev/null; then
            if netstat -tuln | grep -q ":$port "; then
                occupied+=($port)
            fi
        elif command -v ss &> /dev/null; then
            if ss -tuln | grep -q ":$port "; then
                occupied+=($port)
            fi
        fi
    done
    
    if [ ${#occupied[@]} -gt 0 ]; then
        echo -e "${YELLOW}警告: 以下端口已被占用: ${occupied[*]}${NC}"
        echo "如果这些端口被其他服务使用，请修改 .env 文件中的端口配置"
        read -p "是否继续? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        echo -e "${GREEN}✓ 端口检查通过${NC}"
    fi
}

# 创建必要的目录
create_directories() {
    echo -e "\n${GREEN}[3/6] 创建必要的目录...${NC}"
    
    mkdir -p logs/backend
    mkdir -p ssl
    
    echo -e "${GREEN}✓ 目录创建完成${NC}"
}

# 检查环境变量文件
check_env_file() {
    echo -e "\n${GREEN}[4/6] 检查环境变量配置...${NC}"
    
    if [ ! -f .env ]; then
        echo -e "${YELLOW}未找到 .env 文件，从 .env.example 创建...${NC}"
        if [ -f .env.example ]; then
            cp .env.example .env
            echo -e "${GREEN}✓ 已创建 .env 文件，请根据实际情况修改配置${NC}"
            echo -e "${YELLOW}提示: 编辑 .env 文件设置端口等配置${NC}"
            echo -e "${YELLOW}  - 如果使用非root用户，建议将FRONTEND_PORT_HTTP改为8080等非特权端口${NC}"
            echo -e "${YELLOW}  - 如果无域名，CORS_ORIGINS已默认设置为*（生产环境建议指定具体IP）${NC}"
        else
            echo -e "${RED}错误: 未找到 .env.example 文件${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}✓ 环境变量文件已存在${NC}"
    fi
}

# 构建和启动服务
build_and_start() {
    echo -e "\n${GREEN}[5/6] 构建Docker镜像...${NC}"
    
    # 使用docker compose v2或v1
    if docker compose version &> /dev/null; then
        COMPOSE_CMD="docker compose"
    else
        COMPOSE_CMD="docker-compose"
    fi
    
    echo "使用命令: $COMPOSE_CMD"
    
    # 停止旧容器
    echo "停止旧容器..."
    $COMPOSE_CMD -f docker-compose.prod.yml down 2>/dev/null || true
    
    # 构建镜像
    echo "构建镜像（这可能需要几分钟）..."
    $COMPOSE_CMD -f docker-compose.prod.yml build --no-cache
    
    echo -e "\n${GREEN}[6/6] 启动服务...${NC}"
    $COMPOSE_CMD -f docker-compose.prod.yml up -d
    
    echo -e "\n${GREEN}✓ 服务启动完成${NC}"
}

# 显示服务状态
show_status() {
    echo -e "\n${GREEN}=========================================="
    echo "部署完成！"
    echo "==========================================${NC}"
    
    if docker compose version &> /dev/null; then
        COMPOSE_CMD="docker compose"
    else
        COMPOSE_CMD="docker-compose"
    fi
    
    echo -e "\n服务状态:"
    $COMPOSE_CMD -f docker-compose.prod.yml ps
    
    echo -e "\n查看日志:"
    echo "  $COMPOSE_CMD -f docker-compose.prod.yml logs -f"
    
    echo -e "\n停止服务:"
    echo "  $COMPOSE_CMD -f docker-compose.prod.yml down"
    
    echo -e "\n重启服务:"
    echo "  $COMPOSE_CMD -f docker-compose.prod.yml restart"
    
    echo -e "\n访问地址:"
    
    # 获取服务器IP
    SERVER_IP=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "your-server-ip")
    
    # 从.env文件读取端口配置
    if [ -f .env ]; then
        FRONTEND_PORT=$(grep "^FRONTEND_PORT_HTTP=" .env | cut -d '=' -f2 | tr -d ' ' 2>/dev/null || echo "80")
    else
        FRONTEND_PORT="80"
    fi
    
    # 如果端口不是80，显示完整URL
    if [ "$FRONTEND_PORT" != "80" ] && [ ! -z "$FRONTEND_PORT" ]; then
        echo "  HTTP:  http://$SERVER_IP:$FRONTEND_PORT"
    else
        echo "  HTTP:  http://$SERVER_IP"
        echo "  或:    http://localhost"
    fi
    
    # 如果配置了域名，显示域名访问地址
    if [ -f .env ] && grep -q "^DOMAIN=" .env; then
        DOMAIN=$(grep "^DOMAIN=" .env | cut -d '=' -f2 | tr -d ' ')
        if [ ! -z "$DOMAIN" ] && [ "$DOMAIN" != "" ]; then
            if [ "$FRONTEND_PORT" != "80" ] && [ ! -z "$FRONTEND_PORT" ]; then
                echo "  域名:  http://$DOMAIN:$FRONTEND_PORT"
            else
                echo "  域名:  http://$DOMAIN"
            fi
        fi
    fi
    
    echo -e "\n${YELLOW}提示: 如果无法访问，请检查:${NC}"
    echo "  1. 防火墙是否开放了端口 $FRONTEND_PORT"
    echo "  2. 阿里云安全组是否配置了相应规则"
    echo "  3. 容器是否正常运行: $COMPOSE_CMD -f docker-compose.prod.yml ps"
}

# 主函数
main() {
    check_root
    check_docker
    check_ports
    create_directories
    check_env_file
    build_and_start
    show_status
}

# 执行主函数
main

