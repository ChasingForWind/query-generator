@echo off
echo ========================================
echo 启动开发模式
echo ========================================
echo.
echo 开发模式特点：
echo - 修改后端代码后自动生效（无需重启）
echo - 修改前端代码后需要运行 update-code.bat
echo - 适合开发调试使用
echo.

REM 检查 Docker 是否运行
docker ps >nul 2>&1
if %errorlevel% neq 0 (
    echo [错误] Docker 未运行，请先启动 Docker Desktop
    pause
    exit /b 1
)

cd /d %~dp0

echo [1/2] 停止现有服务...
docker compose down

echo.
echo [2/2] 启动开发模式服务...
docker compose -f docker-compose.dev.yml up -d --build

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo ✓ 开发模式启动成功！
    echo ========================================
    echo.
    echo 访问: http://localhost:8080
    echo.
    echo 开发模式说明：
    echo - 修改后端 Python 代码 → 自动生效（无需任何操作）
    echo - 修改前端 Vue 代码 → 运行 update-code.bat 更新
    echo.
    echo 停止服务: stop-dev.bat
    echo.
) else (
    echo.
    echo ✗ 启动失败
    echo.
)

pause

