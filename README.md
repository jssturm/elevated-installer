# Elevated Applicant — Installer

**One-command installer for Elevated Applicant** — the AI-powered job search command center.

This is a public installer. It downloads the app from a private repository — you'll need a GitHub personal access token with `repo` or `read:packages` scope.

## Quick Install

### macOS / Linux / WSL:
```bash
curl -fsSL -o install.sh https://raw.githubusercontent.com/jssturm/elevated-installer/main/install.sh
bash install.sh
```

### Windows (PowerShell):
```powershell
Invoke-WebRequest -Uri https://raw.githubusercontent.com/jssturm/elevated-installer/main/install.ps1 -OutFile install.ps1
.\install.ps1
```

You'll be prompted for a GitHub token. Create one at https://github.com/settings/tokens (needs `repo` scope).

## What this installs

- The Elevated Applicant CLI (`elevated-applicant`)
- All dependencies (Node.js packages, Playwright Chromium)
- Initial configuration templates

## Requirements

- **Node.js 20+**
- **GitHub personal access token** (to access the private repo)

## After Install

```bash
cd ~/Elevated-Applicant
claude        # or: opencode, codex, gemini
```

The AI assistant will walk you through CV upload, profile config, and job discovery.
