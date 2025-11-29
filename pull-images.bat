@echo off
echo 开始拉取 Docker 镜像...
echo.

echo 正在拉取 python:3.11-slim...
docker pull python:3.11-slim
if %errorlevel% neq 0 (
    echo 拉取失败，请检查网络连接
    pause
    exit /b 1
)

echo.
echo 正在拉取 node:18-alpine...
docker pull node:18-alpine
if %errorlevel% neq 0 (
    echo 拉取失败，请检查网络连接
    pause
    exit /b 1
)

echo.
echo 正在拉取 nginx:alpine...
docker pull nginx:alpine
if %errorlevel% neq 0 (
    echo 拉取失败，请检查网络连接
    pause
    exit /b 1
)

echo.
echo 所有镜像拉取成功！
echo 现在可以运行: docker compose up -d
pause

