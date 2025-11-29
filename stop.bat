@echo off
echo ========================================
echo 查询语句生成器 - 停止服务
echo ========================================
echo.

cd /d %~dp0
docker compose down

if %errorlevel% equ 0 (
    echo.
    echo ✓ 服务已停止
) else (
    echo.
    echo ✗ 停止服务时出错
)

echo.
pause

