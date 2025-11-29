@echo off
echo ========================================
echo 停止开发模式服务
echo ========================================
echo.

cd /d %~dp0

docker compose -f docker-compose.dev.yml down

if %errorlevel% equ 0 (
    echo.
    echo ✓ 开发模式服务已停止
    echo.
) else (
    echo.
    echo ✗ 停止服务时出错
    echo.
)

pause

