# Build the static site that goes to Cloudflare Pages.
#
#   builds/web/   raw Godot web export (gitignored, ~48 MB)
#   dist/         deploy folder: everything except index.wasm, plus
#                 index.wasm.gz, _headers and functions/_middleware.js
#
# .SYNOPSIS
#   Exports the Godot project for the web and assembles the dist/ folder.
param(
    [string]$Preset = 'Web'
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $root

. (Join-Path $PSScriptRoot 'find_godot.ps1')
$godot = Find-Godot $root
Write-Host "godot: $godot"

$buildDir = Join-Path $root 'builds\web'
$distDir = Join-Path $root 'dist'
New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

# Godot treats every folder in the project as a resource source. Without these
# markers it imports dist/, node_modules/ and .wrangler/ and the exported .pck
# grows by the size of the previous build (it once reached 28 MB this way).
foreach ($generated in 'dist', 'builds', 'node_modules', '.wrangler') {
    $dir = Join-Path $root $generated
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $ignore = Join-Path $dir '.gdignore'
    if (-not (Test-Path -LiteralPath $ignore)) { New-Item -ItemType File -Path $ignore | Out-Null }
}

Write-Host '=== import'
& $godot --headless --path $root --import | Out-Null
if ($LASTEXITCODE -ne 0) { throw "godot --import failed ($LASTEXITCODE)" }

Write-Host '=== export'
& $godot --headless --path $root --export-release $Preset (Join-Path $buildDir 'index.html') | Out-Null
if ($LASTEXITCODE -ne 0) { throw "godot --export-release failed ($LASTEXITCODE)" }

$indexHtml = Join-Path $buildDir 'index.html'
$wasm = Join-Path $buildDir 'index.wasm'
if (-not (Test-Path -LiteralPath $indexHtml)) { throw 'export produced no index.html' }
if (-not (Test-Path -LiteralPath $wasm)) { throw 'export produced no index.wasm' }

Write-Host '=== assemble dist'
if (Test-Path -LiteralPath $distDir) { Remove-Item -LiteralPath $distDir -Recurse -Force }
New-Item -ItemType Directory -Force -Path $distDir | Out-Null

Get-ChildItem -LiteralPath $buildDir -File |
    Where-Object { $_.Name -ne 'index.wasm' -and $_.Extension -ne '.import' } |
    ForEach-Object { Copy-Item -LiteralPath $_.FullName -Destination $distDir -Force }

& node (Join-Path $root 'tools\gzip.js') $wasm (Join-Path $distDir 'index.wasm.gz')
if ($LASTEXITCODE -ne 0) { throw 'gzip step failed' }

& node (Join-Path $root 'tools\patch_shell.js') (Join-Path $distDir 'index.html')
if ($LASTEXITCODE -ne 0) { throw 'shell patch failed' }

Copy-Item -LiteralPath (Join-Path $root 'web\_headers') -Destination (Join-Path $distDir '_headers') -Force
Copy-Item -LiteralPath (Join-Path $root 'web\_worker.js') -Destination (Join-Path $distDir '_worker.js') -Force

# dist/ was deleted and recreated above, which also deleted its .gdignore; put it
# back or the next `godot --import` (tests/run.ps1) imports dist/*.png and drops
# .import sidecars into the deploy folder.
New-Item -ItemType File -Path (Join-Path $distDir '.gdignore') -Force | Out-Null

$total = (Get-ChildItem -LiteralPath $distDir -Recurse -File | Measure-Object Length -Sum).Sum
$biggest = Get-ChildItem -LiteralPath $distDir -Recurse -File | Sort-Object Length -Descending | Select-Object -First 1
Write-Host ''
Write-Host ("dist: {0} files, {1:N1} MB total, largest {2:N2} MB ({3})" -f `
    (Get-ChildItem -LiteralPath $distDir -Recurse -File).Count, ($total / 1MB), ($biggest.Length / 1MB), $biggest.Name)

if ($biggest.Length -gt 25MB) {
    throw "largest asset exceeds the Cloudflare Pages 25 MiB limit: $($biggest.Name)"
}
Write-Host 'BUILD PASS'
