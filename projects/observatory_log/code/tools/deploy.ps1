# Deploy to Cloudflare Pages
#
#   npm run deploy
#   npm run deploy -- -ProjectName my-game
#
# Needs: Node 20+, `npx wrangler login` done once, and a dist/ built by
# tools/build_web.ps1 (this script builds it if index.html is missing).
param(
    [string]$ProjectName = 'observation-log',
    [string]$Branch = 'main'
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $root

if (-not (Test-Path -LiteralPath (Join-Path $root 'dist\index.html'))) {
    Write-Host 'dist/ is missing - building it first'
    & (Join-Path $PSScriptRoot 'build_web.ps1')
    if ($LASTEXITCODE -ne 0) { throw 'build failed' }
}

Write-Host '=== auth'
$who = (& npx wrangler whoami 2>&1 | Out-String)
if ($who -match 'not authenticated|You are not logged in|Please log in') {
    Write-Host 'Not logged in. Run:  npx wrangler login' -ForegroundColor Yellow
    exit 2
}

Write-Host "=== deploy dist/ -> $ProjectName ($Branch)"
# wrangler warns on stderr when the worktree is dirty; with
# $ErrorActionPreference='Stop' PowerShell turns that into a failure, so relax it
# for this one native call and let $LASTEXITCODE decide.
$ErrorActionPreference = 'Continue'
$out = (& npx wrangler pages deploy dist --project-name $ProjectName --branch $Branch --commit-dirty=true 2>&1 | Out-String)
Write-Host $out
$code = $LASTEXITCODE
if ($code -ne 0) {
    if ($code -eq 1) {
        Write-Host ''
        Write-Host 'If this failed with "Pages only supports files up to 25 MiB":' -ForegroundColor Yellow
        Write-Host '  the raw wasm was deployed instead of the gzipped one. Re-run npm run build:web'
        Write-Host '  and check that dist/index.wasm.gz exists and dist/index.wasm does not.'
    }
    exit $code
}

# Cloudflare appends a suffix to the project subdomain, so read the URL back
# instead of guessing https://<project>.pages.dev.
$url = ([regex]::Matches($out, 'https://[A-Za-z0-9.-]+\.pages\.dev') | Select-Object -Last 1).Value
Write-Host ''
if ($url) {
    Write-Host "Live: $url" -ForegroundColor Green
    Write-Host 'The stable production URL is shown in the dashboard (Workers & Pages -> your project).'
    Write-Host "Re-run the browser checks against it:"
    Write-Host "  `$env:GAME_URL='$url'; npx playwright test"
} else {
    Write-Host 'Deployment finished but no pages.dev URL was found in the output.'
}
