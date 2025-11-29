#!/bin/bash

# SSL证书自动配置脚本（使用Let's Encrypt）
# 需要先安装certbot

set -e

echo "=========================================="
echo "SSL证书自动配置脚本"
echo "=========================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 检查certbot是否安装
check_certbot() {
    if ! command -v certbot &> /dev/null; then
        echo -e "${RED}错误: certbot未安装${NC}"
        echo "安装certbot:"
        echo "  Ubuntu/Debian: sudo apt-get update && sudo apt-get install certbot"
        echo "  CentOS/RHEL: sudo yum install certbot"
        exit 1
    fi
}

# 获取域名
get_domain() {
    if [ -f .env ] && grep -q "DOMAIN=" .env; then
        DOMAIN=$(grep "DOMAIN=" .env | cut -d '=' -f2 | tr -d ' ')
    fi
    
    if [ -z "$DOMAIN" ]; then
        read -p "请输入域名 (例如: example.com): " DOMAIN
    fi
    
    if [ -z "$DOMAIN" ]; then
        echo -e "${RED}错误: 域名不能为空${NC}"
        exit 1
    fi
}

# 申请证书
request_certificate() {
    echo -e "\n${GREEN}申请Let's Encrypt证书...${NC}"
    
    # 创建验证目录
    mkdir -p /var/www/certbot
    
    # 申请证书（standalone模式，需要先停止nginx）
    echo -e "${YELLOW}注意: 申请证书需要临时占用80端口，请确保80端口可用${NC}"
    read -p "是否继续? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
    
    # 停止nginx容器（如果正在运行）
    if docker compose version &> /dev/null; then
        COMPOSE_CMD="docker compose"
    else
        COMPOSE_CMD="docker-compose"
    fi
    
    $COMPOSE_CMD -f docker-compose.prod.yml stop frontend 2>/dev/null || true
    
    # 申请证书
    sudo certbot certonly --standalone \
        -d "$DOMAIN" \
        -d "www.$DOMAIN" \
        --email "admin@$DOMAIN" \
        --agree-tos \
        --non-interactive \
        --preferred-challenges http
    
    # 复制证书到项目目录
    echo -e "\n${GREEN}复制证书到项目目录...${NC}"
    mkdir -p ssl
    sudo cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem ssl/
    sudo cp /etc/letsencrypt/live/$DOMAIN/privkey.pem ssl/
    sudo chown -R $USER:$USER ssl/
    
    echo -e "${GREEN}✓ 证书申请完成${NC}"
}

# 配置自动续期
setup_renewal() {
    echo -e "\n${GREEN}配置证书自动续期...${NC}"
    
    # 创建续期脚本
    cat > renew-cert.sh << 'EOF'
#!/bin/bash
# 证书续期脚本

DOMAIN="your-domain.com"  # 修改为实际域名

# 续期证书
sudo certbot renew

# 复制新证书
sudo cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem ssl/
sudo cp /etc/letsencrypt/live/$DOMAIN/privkey.pem ssl/
sudo chown -R $USER:$USER ssl/

# 重启nginx容器
if docker compose version &> /dev/null; then
    docker compose -f docker-compose.prod.yml restart frontend
else
    docker-compose -f docker-compose.prod.yml restart frontend
fi
EOF
    
    chmod +x renew-cert.sh
    
    # 添加到crontab（每月1号凌晨3点检查续期）
    (crontab -l 2>/dev/null | grep -v "renew-cert.sh"; echo "0 3 1 * * $(pwd)/renew-cert.sh") | crontab -
    
    echo -e "${GREEN}✓ 自动续期配置完成${NC}"
    echo -e "${YELLOW}提示: 证书将在到期前自动续期${NC}"
}

# 更新nginx配置
update_nginx_config() {
    echo -e "\n${GREEN}更新nginx配置...${NC}"
    
    # 更新nginx-ssl.conf中的域名
    if [ -f frontend/nginx-ssl.conf ]; then
        sed -i "s/your-domain.com/$DOMAIN/g" frontend/nginx-ssl.conf
        echo -e "${GREEN}✓ nginx配置已更新${NC}"
    fi
    
    echo -e "${YELLOW}提示: 需要修改docker-compose.prod.yml，取消SSL相关volumes的注释${NC}"
}

# 主函数
main() {
    check_certbot
    get_domain
    request_certificate
    setup_renewal
    update_nginx_config
    
    echo -e "\n${GREEN}=========================================="
    echo "SSL证书配置完成！"
    echo "==========================================${NC}"
    echo -e "\n下一步:"
    echo "1. 修改 docker-compose.prod.yml，启用HTTPS配置"
    echo "2. 重启服务: docker compose -f docker-compose.prod.yml restart frontend"
    echo "3. 访问: https://$DOMAIN"
}

main

