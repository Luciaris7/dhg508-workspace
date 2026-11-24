param([string]$what = 'check', [string[]]$extra = @())
# .\tests\run.ps1 all | check | import | play | shots | <scene path>
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$result = 0
$sandbox = $null
$oldAppData = $env:APPDATA
$oldLocal = $env:LOCALAPPDATA
$oldXdg = $env:XDG_DATA_HOME
try {
    . (Join-Path $root 'tools\find_godot.ps1')
    $godot = Find-Godot $root
    $logs = Join-Path $PSScriptRoot '_logs'
    New-Item -ItemType Directory -Force -Path $logs | Out-Null
    Set-Content -LiteralPath (Join-Path $logs '.gdignore') -Value ''
    if ($what -ne 'import') {
        $sandbox = Join-Path ([IO.Path]::GetTempPath()) ('audience-tests-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $sandbox | Out-Null
        $env:APPDATA = $sandbox
        $env:LOCALAPPDATA = $sandbox
        $env:XDG_DATA_HOME = $sandbox
    }
    function Invoke-Gate([string]$Name, [string[]]$GodotArgs, [string]$Marker) {
        Write-Host "=== $Name"
        $ErrorActionPreference = 'Continue'
        $output = @(& $godot --headless --path $root @GodotArgs 2>&1)
        $code = $LASTEXITCODE
        $text = $output | Out-String
        $diagnostic = $text -replace '(?m)^ERROR: \d+ resources still in use at exit.*$', ''
        $output | Set-Content -LiteralPath (Join-Path $logs ($Name + '.log')) -Encoding UTF8
        $output | Where-Object { "$_" -match 'CHECK|PASS|FAIL|ERROR|EPHEM|MENU|MOTION|ENDINGS|DAY5|DREAM|UFO' } | ForEach-Object { Write-Host "$_" }
        if ($code -ne 0 -or ($Marker -and $text -notmatch $Marker) -or $diagnostic -match '(?m)^ERROR:|SCRIPT ERROR:|^FAIL\s') {
            throw "Gate '$Name' failed (exit $code). See tests\_logs\$Name.log"
        }
    }
    Invoke-Gate 'import' @('--import') ''
    $fixed = @('--fixed-fps', '60', '--quit-after', '36000')
    switch ($what) {
        'all' {
            Invoke-Gate 'check' ($fixed + @('res://tests/check.tscn')) 'CHECK: \d+ files, 0 failed'
            Invoke-Gate 'ephem' ($fixed + @('res://tests/ephem_test.tscn')) 'EPHEM PASS'
            Invoke-Gate 'motion' ($fixed + @('res://tests/motion_test.tscn')) 'MOTION PASS'
            Invoke-Gate 'menu' ($fixed + @('res://tests/menu_test.tscn')) 'MENU PASS'
            Invoke-Gate 'endings' ($fixed + @('res://tests/ending_test.tscn')) 'ENDINGS PASS'
            Invoke-Gate 'day5' ($fixed + @('res://tests/day5_test.tscn')) 'DAY5 PASS'
            Invoke-Gate 'dream' ($fixed + @('res://tests/dream_test.tscn')) 'DREAM PASS'
            Invoke-Gate 'ufo' ($fixed + @('res://tests/ufo_test.tscn')) 'UFO PASS'
            Invoke-Gate 'cheat' ($fixed + @('res://tests/cheat_test.tscn')) 'CHEAT PASS'
            # one full playthrough per ending (docs/MYSTERY_BIBLE.md section 6)
            Invoke-Gate 'play-en' ($fixed + @('res://tests/playthrough.tscn', '--', 'answers=ynnnyyy', 'lang=en', 'route=bad')) 'PLAYTHROUGH PASS'
            Invoke-Gate 'play-zh' ($fixed + @('res://tests/playthrough.tscn', '--', 'answers=yyyynyy', 'lang=zh', 'route=normal')) 'PLAYTHROUGH PASS'
            Invoke-Gate 'play-good' ($fixed + @('res://tests/playthrough.tscn', '--', 'answers=ynnyyyy', 'lang=en', 'route=good')) 'PLAYTHROUGH PASS'
        }
        'endings' { Invoke-Gate 'endings' ($fixed + @('res://tests/ending_test.tscn')) 'ENDINGS PASS' }
        'day5' { Invoke-Gate 'day5' ($fixed + @('res://tests/day5_test.tscn')) 'DAY5 PASS' }
        'check' { Invoke-Gate 'check' ($fixed + @('res://tests/check.tscn')) 'CHECK: \d+ files, 0 failed' }
        'import' { }
        'play' { Invoke-Gate 'play' ($fixed + @('res://tests/playthrough.tscn', '--') + $extra) 'PLAYTHROUGH PASS' }
        'shots' {
            & $godot --path $root res://tests/shots.tscn -- @extra
            if ($LASTEXITCODE -ne 0) { throw 'Screenshot capture failed.' }
        }
        default { Invoke-Gate 'custom' ($fixed + @($what, '--') + $extra) '' }
    }
    Write-Host 'TEST RUN PASS'
} catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
    $result = 1
} finally {
    $env:APPDATA = $oldAppData
    $env:LOCALAPPDATA = $oldLocal
    $env:XDG_DATA_HOME = $oldXdg
    if ($sandbox) { Remove-Item -LiteralPath $sandbox -Recurse -Force -ErrorAction SilentlyContinue }
}
exit $result
