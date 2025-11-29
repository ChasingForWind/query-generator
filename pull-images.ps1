# 手动拉取 Docker 镜像脚本
# 如果自动拉取失败，可以尝试手动拉取

Write-Host "开始拉取 Docker 镜像..." -ForegroundColor Green

# 尝试从不同源拉取镜像
$images = @(
    "python:3.11-slim",
    "node:18-alpine",
    "nginx:alpine"
)

foreach ($image in $images) {
    Write-Host "`n正在拉取: $image" -ForegroundColor Yellow
    
    # 尝试从官方源拉取
    Write-Host "尝试从 Docker Hub 拉取..." -ForegroundColor Cyan
    docker pull $image
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ 成功拉取: $image" -ForegroundColor Green
    } else {
        Write-Host "✗ 拉取失败: $image" -ForegroundColor Red
        Write-Host "提示: 请检查网络连接或配置代理" -ForegroundColor Yellow
    }
}

Write-Host "`n镜像拉取完成！" -ForegroundColor Green
Write-Host "如果所有镜像都拉取成功，可以运行: docker compose up -d" -ForegroundColor Cyan

