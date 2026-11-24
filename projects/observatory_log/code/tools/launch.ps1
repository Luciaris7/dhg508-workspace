$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
try {
    . (Join-Path $PSScriptRoot 'find_godot.ps1')
    $godot = Find-Godot $root
    & $godot --headless --path $root --import
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    & $godot --path $root
    exit $LASTEXITCODE
} catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
