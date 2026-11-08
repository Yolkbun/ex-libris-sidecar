# 生成侧车与完整版 Release 资产
#
#   powershell -NoProfile -File scripts/make-release.ps1 `
#       -Version 0.1.0 -PluginVersion 0.1.1 `
#       -PluginAssets "D:\Ex Libris\release\0.1.1\plugin"
#
# 产物：
#   release/sidecar-<Version>/fqsidecar.exe
#   release/ex-libris-full-<PluginVersion>.zip   （插件三件套 + bin/exe）
#   release/SHA256SUMS.txt

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Version,
    [Parameter(Mandatory = $true)][string]$PluginVersion,
    [Parameter(Mandatory = $true)][string]$PluginAssets
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$exe = Join-Path $root 'bin/fqsidecar.exe'
$out = Join-Path $root "release/sidecar-$Version"

if (-not (Test-Path $exe)) {
    throw 'bin/fqsidecar.exe 不存在，先运行 scripts/build-sidecar.ps1'
}
if (-not (Test-Path (Join-Path $PluginAssets 'main.js'))) {
    throw "PluginAssets 缺少 main.js：$PluginAssets"
}

New-Item -ItemType Directory -Force -Path $out | Out-Null
Copy-Item $exe $out -Force

$stage = Join-Path $root 'release/.stage/ex-libris'
if (Test-Path (Join-Path $root 'release/.stage')) {
    Remove-Item (Join-Path $root 'release/.stage') -Recurse -Force
}
New-Item -ItemType Directory -Force -Path (Join-Path $stage 'bin') | Out-Null
Copy-Item (Join-Path $PluginAssets 'main.js') $stage -Force
Copy-Item (Join-Path $PluginAssets 'manifest.json') $stage -Force
Copy-Item (Join-Path $PluginAssets 'styles.css') $stage -Force
Copy-Item $exe (Join-Path $stage 'bin/fqsidecar.exe') -Force

$fullZip = Join-Path $root "release/ex-libris-full-$PluginVersion.zip"
if (Test-Path $fullZip) { Remove-Item $fullZip -Force }
Compress-Archive -Path $stage -DestinationPath $fullZip -CompressionLevel Optimal
Remove-Item (Join-Path $root 'release/.stage') -Recurse -Force

$sums = Join-Path $root 'release/SHA256SUMS.txt'
$lines = @(
    (Get-FileHash $exe -Algorithm SHA256).Hash + '  fqsidecar.exe'
    (Get-FileHash $fullZip -Algorithm SHA256).Hash + "  ex-libris-full-$PluginVersion.zip"
)
$lines | Set-Content -Path $sums -Encoding ASCII

Write-Host "sidecar: $out/fqsidecar.exe"
Write-Host "full: $fullZip"
Write-Host "sums: $sums"
Get-Content $sums
