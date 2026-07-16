# Elevated Applicant — Public Installer (Windows PowerShell)
# Usage: irm https://raw.githubusercontent.com/jssturm/elevated-installer/main/install.ps1 | iex

# Wrap everything in a function so we can always pause at the end
function Install-ElevatedApplicant {
    Write-Host ""
    Write-Host "=================================================" -ForegroundColor Cyan
    Write-Host "  Elevated Applicant — Installer" -ForegroundColor Green
    Write-Host "=================================================" -ForegroundColor Cyan
    Write-Host ""

    $Token = $env:GITHUB_TOKEN

    # ── Check Node.js ──────────────────────────────────────────────────
    if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
        Write-Host "ERROR: Node.js 20+ is required." -ForegroundColor Red
        Write-Host "Download from https://nodejs.org" -ForegroundColor Yellow
        return
    }

    $nodeVersion = (node -v).TrimStart('v').Split('.')[0]
    if ([int]$nodeVersion -lt 20) {
        Write-Host "ERROR: Node.js 20+ required. Found v$(node -v)." -ForegroundColor Red
        return
    }
    Write-Host "  OK  Node.js $(node -v)" -ForegroundColor Green

    # ── Check for tar (needed for extraction) ──────────────────────────
    $hasTar = Get-Command tar -ErrorAction SilentlyContinue
    if (-not $hasTar) {
        Write-Host "  NOTE: 'tar' not found. Will use .zip files instead." -ForegroundColor Yellow
    }

    # ── GitHub token ───────────────────────────────────────────────────
    if (-not $Token) {
        Write-Host ""
        Write-Host "  This installer downloads from a private GitHub repository."
        Write-Host "  Create a token at: https://github.com/settings/tokens"
        Write-Host "  (needs 'repo' scope)"
        Write-Host ""
        $Token = Read-Host -Prompt "  GitHub personal access token"
        if (-not $Token) {
            Write-Host "ERROR: GitHub token is required." -ForegroundColor Red
            return
        }
    }

    # ── Download latest release ────────────────────────────────────────
    $Repo = "jssturm/Elevated-Applicant"
    $ReleaseApi = "https://api.github.com/repos/$Repo/releases/latest"
    $InstallDir = "$env:USERPROFILE\Elevated-Applicant"

    Write-Host ""
    Write-Host "  Fetching latest release..." -ForegroundColor Cyan

    $headers = @{
        "Authorization" = "token $Token"
        "Accept"        = "application/vnd.github+json"
        "User-Agent"    = "elevated-installer"
    }

    try {
        $release = Invoke-RestMethod -Uri $ReleaseApi -Headers $headers -ErrorAction Stop
    } catch {
        Write-Host "ERROR: Could not fetch release." -ForegroundColor Red
        $statusCode = if ($_.Exception.Response) { $_.Exception.Response.StatusCode.value__ } else { "unknown" }
        Write-Host "  Status: $statusCode" -ForegroundColor Red
        Write-Host "  Check that your token is valid and has 'repo' scope." -ForegroundColor Yellow
        Write-Host "  Token scopes: https://github.com/settings/tokens" -ForegroundColor Yellow
        return
    }

    Write-Host "  OK   Found $($release.tag_name) ($($release.assets.Count) assets)" -ForegroundColor Green

    # Find a compatible asset: prefer .zip (Windows-friendly), fall back to .tar.gz
    $asset = $null
    foreach ($a in $release.assets) {
        if ($a.name -like "*.zip") { $asset = $a; break }
    }
    if (-not $asset) {
        foreach ($a in $release.assets) {
            if ($a.name -like "*.tar.gz") { $asset = $a; break }
        }
    }

    if (-not $asset) {
        Write-Host "ERROR: No compatible release asset found (.zip or .tar.gz)." -ForegroundColor Red
        Write-Host "Available assets:" -ForegroundColor Yellow
        foreach ($a in $release.assets) { Write-Host "  - $($a.name) ($([math]::Round($a.size/1MB, 1)) MB)" }
        return
    }

    Write-Host "  Using: $($asset.name) ($([math]::Round($asset.size/1MB, 1)) MB)" -ForegroundColor Cyan

    # ── Download ───────────────────────────────────────────────────────
    $TempDir = Join-Path $env:TEMP "elevated-installer-$(Get-Random)"
    New-Item -ItemType Directory -Force -Path $TempDir | Out-Null
    $DownloadPath = Join-Path $TempDir $asset.name

    Write-Host "  Downloading..." -ForegroundColor Cyan
    $downloadHeaders = @{
        "Authorization" = "token $Token"
        "Accept"        = "application/octet-stream"
        "User-Agent"    = "elevated-installer"
    }

    try {
        Invoke-WebRequest -Uri $asset.browser_download_url -Headers $downloadHeaders -OutFile $DownloadPath -ErrorAction Stop
    } catch {
        Write-Host "ERROR: Download failed." -ForegroundColor Red
        $statusCode = if ($_.Exception.Response) { $_.Exception.Response.StatusCode.value__ } else { "unknown" }
        Write-Host "  Status: $statusCode" -ForegroundColor Red
        Remove-Item -Recurse -Force $TempDir -ErrorAction SilentlyContinue
        return
    }
    Write-Host "  OK   Downloaded" -ForegroundColor Green

    # ── Extract ────────────────────────────────────────────────────────
    Write-Host "  Extracting to $InstallDir..." -ForegroundColor Cyan
    New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null

    $extractOk = $false
    try {
        if ($DownloadPath -like "*.zip") {
            Expand-Archive -Path $DownloadPath -DestinationPath $InstallDir -Force -ErrorAction Stop
            $extractOk = $true
        } elseif ($hasTar -and ($DownloadPath -like "*.tar.gz")) {
            tar -xzf $DownloadPath -C $InstallDir 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) { $extractOk = $true }
            else {
                tar -xzf $DownloadPath -C $InstallDir --strip-components=1 2>&1 | Out-Null
                if ($LASTEXITCODE -eq 0) { $extractOk = $true }
            }
        }
    } catch {
        Write-Host "  Extract error: $_" -ForegroundColor Yellow
    }

    if (-not $extractOk) {
        Write-Host "ERROR: Could not extract $($asset.name)." -ForegroundColor Red
        if (-not $hasTar -and ($DownloadPath -like "*.tar.gz")) {
            Write-Host "  This file requires 'tar'. The release may need a .zip version." -ForegroundColor Yellow
        }
        Remove-Item -Recurse -Force $TempDir -ErrorAction SilentlyContinue
        return
    }

    Remove-Item -Recurse -Force $TempDir -ErrorAction SilentlyContinue
    Write-Host "  OK   Extracted" -ForegroundColor Green

    # ── Install deps ───────────────────────────────────────────────────
    Write-Host "  Installing npm dependencies..." -ForegroundColor Cyan
    Push-Location $InstallDir
    try {
        npm install --silent 2>&1 | Out-Null
        Write-Host "  OK   Dependencies installed" -ForegroundColor Green
    } catch {
        Write-Host "  NOTE: npm install had warnings (this is normal)" -ForegroundColor Yellow
    }
    Pop-Location

    # ── Playwright ─────────────────────────────────────────────────────
    Write-Host "  Setting up Playwright browser..." -ForegroundColor Cyan
    Push-Location $InstallDir
    try {
        npx playwright install chromium 2>&1 | Out-Null
        Write-Host "  OK   Playwright Chromium installed" -ForegroundColor Green
    } catch {
        Write-Host "  NOTE: Run 'npx playwright install chromium' manually if PDF generation is needed" -ForegroundColor Yellow
    }
    Pop-Location

    # ── Done ───────────────────────────────────────────────────────────
    Write-Host ""
    Write-Host "=================================================" -ForegroundColor Cyan
    Write-Host "  Elevated Applicant installed!" -ForegroundColor Green
    Write-Host "=================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Location: $InstallDir" -ForegroundColor White
    Write-Host ""
    Write-Host "  Next steps:" -ForegroundColor White
    Write-Host "    1. cd $InstallDir" -ForegroundColor Cyan
    Write-Host "    2. Add your CV as cv.md" -ForegroundColor Cyan
    Write-Host "    3. Open in an AI CLI: claude (or opencode, codex, gemini)" -ForegroundColor Cyan
    Write-Host ""
}

# Run and always pause so the window doesn't close
Install-ElevatedApplicant
Write-Host "Press Enter to close..." -ForegroundColor Gray
Read-Host
