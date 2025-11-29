@echo off
echo ========================================
echo 更新代码 - 快速生效
echo ========================================
echo.
echo 此脚本会重新构建前端和后端代码并重启容器
echo Docker 缓存机制会加速构建过程。
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
docker compose stop

echo.
echo [2/3] 重新构建并启动后端（使用缓存加速）...
docker compose up -d --build backend

if %errorlevel% neq 0 (
    echo ✗ 后端更新失败
    pause
    exit /b 1
)

echo.
echo [3/3] 重新构建并启动前端（使用缓存加速）...
docker compose up -d --build frontend

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo ✓ 代码更新成功！
    echo ========================================
    echo.
    echo 访问: http://localhost:8080
    echo.
    echo 说明：
    echo - 修改前端 Vue 代码：Docker 会使用缓存，很快完成
    echo - 修改后端 Python 代码：Docker 会使用缓存，很快完成
    echo - 修改了依赖文件（package.json 或 requirements.txt）才会重新下载
    echo.
) else (
    echo.
    echo ✗ 更新失败
    echo.
)

pause

