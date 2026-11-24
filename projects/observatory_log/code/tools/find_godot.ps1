# Shared by the launcher and test runner. Windows PowerShell 5.1 compatible.
function Find-Godot {
    param([string]$ProjectRoot)
    $candidates = @()
    if ($env:GODOT_EXE) {
        if (-not (Test-Path -LiteralPath $env:GODOT_EXE -PathType Leaf)) {
            throw 'GODOT_EXE does not point to an executable.'
        }
        $candidates = @($env:GODOT_EXE)
    } else {
        foreach ($dir in @($ProjectRoot, (Join-Path $ProjectRoot 'engine'))) {
            if (Test-Path -LiteralPath $dir) {
                $candidates += @(Get-ChildItem -LiteralPath $dir -Filter '*.exe' -File |
                    Where-Object { $_.Name -match '^(Godot.*|godot4)\.exe$' } |
                    Sort-Object @{Expression={$_.Name -match '_console\.exe$'}; Descending=$true}, Name |
                    Select-Object -ExpandProperty FullName)
            }
        }
        foreach ($name in @('godot', 'godot4')) {
            $cmd = Get-Command $name -CommandType Application -ErrorAction SilentlyContinue
            if ($cmd) { $candidates += $cmd.Source }
        }
        if ($env:LOCALAPPDATA) {
            $packages = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages'
            if (Test-Path -LiteralPath $packages) {
                foreach ($pkg in @(Get-ChildItem -LiteralPath $packages -Directory -Filter 'GodotEngine.GodotEngine_*')) {
                    $candidates += @(Get-ChildItem -LiteralPath $pkg.FullName -Recurse -File -Filter 'Godot*.exe' |
                        Sort-Object @{Expression={$_.Name -match '_console\.exe$'}; Descending=$true}, Name |
                        Select-Object -ExpandProperty FullName)
                }
            }
        }
    }
    foreach ($candidate in @($candidates | Select-Object -Unique)) {
        $version = (& $candidate --version 2>&1 | Out-String).Trim()
        if ($LASTEXITCODE -eq 0 -and $version -match '^4\.(\d+)\.') {
            if ([int]$Matches[1] -ge 6) { return $candidate }
        }
    }
    throw 'Godot 4.6+ was not found. Put the Godot executable in game\engine, install Godot via WinGet, or set GODOT_EXE to its full path.'
}
