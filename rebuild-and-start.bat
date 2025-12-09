@echo off
echo ========================================
echo 重新构建并启动服务（测试跳转功能）
echo ========================================
echo.

REM 检查 Docker 是否运行
docker ps >nul 2>&1
if %errorlevel% neq 0 (
    echo [错误] Docker 未运行，请先启动 Docker Desktop
    pause
    exit /b 1
)

cd /d %~dp0

echo [1/3] 停止现有容器...
docker compose down

echo.
echo [2/3] 重新构建镜像（前端代码已更新）...
docker compose build --no-cache frontend

echo.
echo [3/3] 启动服务...
docker compose up -d

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo ✓ 服务启动成功！
    echo ========================================
    echo.
    echo 访问地址: http://localhost:8080
    echo.
    echo 测试步骤：
    echo 1. 打开浏览器访问 http://localhost:8080
    echo 2. 输入 goodsId、skuId、simGoodsId、simSkuId
    echo 3. 点击"跳转"按钮测试跳转功能
    echo.
    echo 查看服务状态: docker compose ps
    echo 查看日志: docker compose logs -f
    echo 停止服务: docker compose down
    echo.
) else (
    echo.
    echo ✗ 服务启动失败，请检查错误信息
    echo.
)

pause




