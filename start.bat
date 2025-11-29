@echo off
echo ========================================
echo 查询语句生成器 - 启动服务
echo ========================================
echo.

REM 检查 Docker 是否运行
docker ps >nul 2>&1
if %errorlevel% neq 0 (
    echo [错误] Docker 未运行，请先启动 Docker Desktop
    echo 等待 Docker 启动后，再次运行此脚本
    pause
    exit /b 1
)

echo [1/3] 检查 Docker 状态...
docker ps >nul 2>&1
if %errorlevel% equ 0 (
    echo ✓ Docker 正在运行
) else (
    echo ✗ Docker 未运行
    pause
    exit /b 1
)

echo.
echo [2/3] 进入项目目录...
cd /d %~dp0
echo 当前目录: %CD%

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

