# dev-env — Windows 一键安装引导
# 用法:
#   irm https://github.com/lilyco-42/dev-env/releases/latest/download/install.ps1 | iex
$ErrorActionPreference = "Stop"
$repo = "lilyco-42/dev-env"
$url = "https://github.com/$repo/releases/latest/download/dev-env.nu"
$bin = Join-Path $env:LOCALAPPDATA "bin"

Write-Host "==> dev-env 安装引导"

if (-not (Get-Command nu -ErrorAction SilentlyContinue)) {
  Write-Host "==> 安装 nushell ..."
  if (Get-Command winget -ErrorAction SilentlyContinue) {
    winget install --id nushell.nushell --silent --accept-package-agreements --accept-source-agreements
  } elseif (Get-Command scoop -ErrorAction SilentlyContinue) {
    scoop install nushell
  } else {
    Write-Error "未找到 winget/scoop, 请先手动安装 nushell: winget install nushell"
  }
}

New-Item -ItemType Directory -Force -Path $bin | Out-Null
Write-Host "==> 下载 dev-env.nu ..."
$dst = Join-Path $bin "dev-env.nu"
Invoke-WebRequest -Uri $url -OutFile $dst

Write-Host "==> 运行 dev-env ..."
& nu $dst @args
exit $LASTEXITCODE
