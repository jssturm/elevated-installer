# Elevated Applicant — Public Installer (Windows PowerShell)
# Downloads the latest app bundle from the private repo using a GitHub token.
# Usage: .\install.ps1
#   Or set $env:GITHUB_TOKEN before running.

param(
    [string]$Token = $env:GITHUB_TOKEN
)

$ErrorActionPreference = "Stop"

Write-Host "Elevated Applicant — Installer" -ForegroundColor Cyan
Write-Host ""

# ── Check deps ────────────────────────────────────────────────────────
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "Error: Node.js 20+ is required. Install from https://nodejs.org" -ForegroundColor Red
    exit 1
}

$nodeVersion = (node -v).TrimStart('v').Split('.')[0]
if ([int]$nodeVersion -lt 20) {
    Write-Host "Error: Node.js 20+ required. Found v$(node -v)." -ForegroundColor Red
    exit 1
}
Write-Host "  $([char]0x2713) Node.js $(node -v)" -ForegroundColor Green

# ── GitHub token ───────────────────────────────────────────────────────
if (-not $Token) {
    Write-Host ""
    Write-Host "  This installer downloads from a private GitHub repository."
    Write-Host "  Create a token at: https://github.com/settings/tokens"
    Write-Host "  (needs repo scope — or just 'read:packages' for releases)"
    Write-Host ""
    $Token = Read-Host -Prompt "  GitHub personal access token"
    if (-not $Token) {
        Write-Host "Error: GitHub token is required." -ForegroundColor Red
        exit 1
    }
}

if (-not $Token) {
    Write-Host "Error: GitHub token is required." -ForegroundColor Red
    exit 1
}

# ── Download latest release ────────────────────────────────────────────
$Repo = "jssturm/Elevated-Applicant"
$ReleaseApi = "https://api.github.com/repos/$Repo/releases/latest"
$InstallDir = "$env:USERPROFILE\Elevated-Applicant"

Write-Host "$([char]0x2192) Fetching latest release..." -ForegroundColor Cyan

$headers = @{
    "Authorization" = "token $Token"
    "Accept"        = "application/vnd.github+json"
}

try {
    $release = Invoke-RestMethod -Uri $ReleaseApi -Headers $headers
} catch {
    Write-Host "Error: Could not fetch release. Check your token and repo access." -ForegroundColor Red
    Write-Host "Status: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
    exit 1
}

Write-Host "  $([char]0x2713) Found $($release.tag_name)" -ForegroundColor Green

# Find the Windows asset
$asset = $release.assets | Where-Object { $_.name -like "*windows*" -or $_.name -like "*win*" }
if (-not $asset) {
    # Fall back to any tar.gz
    $asset = $release.assets | Where-Object { $_.name -like "*.tar.gz" -or $_.name -like "*.zip" } | Select-Object -First 1
}
if (-not $asset) {
    Write-Host "Error: No compatible release asset found." -ForegroundColor Red
    Write-Host "Available assets:" -ForegroundColor Yellow
    $release.assets | ForEach-Object { Write-Host "  - $($_.name)" }
    exit 1
}

# ── Download & extract ─────────────────────────────────────────────────
$TempDir = Join-Path $env:TEMP "elevated-installer-$(Get-Random)"
New-Item -ItemType Directory -Force -Path $TempDir | Out-Null

$DownloadPath = Join-Path $TempDir $asset.name
Write-Host "$([char]0x2192) Downloading $($asset.name)..." -ForegroundColor Cyan

$downloadHeaders = @{
    "Authorization" = "token $Token"
    "Accept"        = "application/octet-stream"
}

try {
    Invoke-WebRequest -Uri $asset.browser_download_url -Headers $downloadHeaders -OutFile $DownloadPath
} catch {
    Write-Host "Error: Download failed. Status: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
    Remove-Item -Recurse -Force $TempDir -ErrorAction SilentlyContinue
    exit 1
}

Write-Host "$([char]0x2192) Extracting to $InstallDir..." -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null

try {
    if ($DownloadPath -like "*.zip") {
        Expand-Archive -Path $DownloadPath -DestinationPath $InstallDir -Force
    } else {
        # tar.gz extraction
        tar -xzf $DownloadPath -C $InstallDir 2>$null
        if ($LASTEXITCODE -ne 0) {
            # Try with --strip-components
            tar -xzf $DownloadPath -C $InstallDir --strip-components=1 2>$null
        }
    }
} catch {
    Write-Host "Error: Extraction failed." -ForegroundColor Red
    Remove-Item -Recurse -Force $TempDir -ErrorAction SilentlyContinue
    exit 1
}

Remove-Item -Recurse -Force $TempDir -ErrorAction SilentlyContinue

# ── Install deps ───────────────────────────────────────────────────────
Write-Host "$([char]0x2192) Installing dependencies..." -ForegroundColor Cyan
Push-Location $InstallDir
try {
    npm install --silent 2>$null
} catch {
    Write-Host "  (warnings during install are normal)"
}
Pop-Location

Write-Host "$([char]0x2192) Setting up Playwright browser..." -ForegroundColor Cyan
Push-Location $InstallDir
try {
    npx playwright install chromium 2>$null
} catch {
    Write-Host "  (run 'npx playwright install chromium' manually if needed)"
}
Pop-Location

# ── Done ───────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "  Elevated Applicant installed!" -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Next steps:"
Write-Host "  1. cd $InstallDir"
Write-Host "  2. Open in your AI CLI: claude (or opencode, codex, gemini)"
Write-Host "  3. Or start the dashboard: npx elevated-applicant serve --open"
Write-Host ""
