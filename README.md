# Elevated Applicant — Installer

**One command to install Elevated Applicant** — an AI-powered job search command center that discovers jobs across 78+ engines, evaluates your fit, generates ATS-optimized documents, and tracks every application. All local, all private.

> 📖 **What is Elevated Applicant?** → [elevated-applicant.vercel.app/app](https://elevated-applicant.vercel.app/app)

---

## Quick Install

### macOS / Linux / WSL

```bash
curl -fsSL -o install.sh https://raw.githubusercontent.com/jssturm/elevated-installer/main/install.sh
bash install.sh
```

### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/jssturm/elevated-installer/main/install.ps1 | iex
```

The installer will prompt you for a **GitHub personal access token** — this is required to download the app from its private repository.

---

## Creating a GitHub Token

1. Go to [github.com/settings/tokens](https://github.com/settings/tokens)
2. Click **Generate new token** → **Classic**
3. Give it a name (e.g. "Elevated Applicant")
4. Under **Select scopes**, check **`repo`** (full control of private repositories)
5. Click **Generate token** and copy it
6. Paste the token when the installer prompts you

> 🔒 Your token is used only to download the app. It is never stored, logged, or transmitted anywhere else.

---

## Requirements

| Requirement | Details |
|-------------|---------|
| **Node.js 20+** | [Download from nodejs.org](https://nodejs.org) |
| **GitHub token** | Classic token with `repo` scope |
| **Disk space** | ~1–2 GB (includes the built web dashboard and Playwright Chromium) |
| **AI CLI (optional)** | Claude Code, OpenCode, Codex, Gemini, Qwen, or Grok Build — for AI-powered evaluation |

---

## What Gets Installed

- The Elevated Applicant application files (CLI + web app)
- All npm dependencies
- The full web dashboard, built locally for production
- Playwright Chromium browser (for PDF generation)
- Initial configuration templates (`profile.yml`, `portals.yml`)

Everything lives in `~/Elevated-Applicant`. No files are placed anywhere else on your system.

---

## After Install

```bash
cd ~/Elevated-Applicant

# Start the web dashboard — the default experience
elevated-applicant serve --open   # opens http://127.0.0.1:3000

# Optional: open in your AI coding assistant for a conversational workflow
claude        # Claude Code
opencode      # OpenCode
codex         # Codex CLI
gemini        # Gemini CLI
```

The dashboard walks you through CV upload, profile configuration, target roles, and job discovery. Prefer the terminal? An AI coding CLI gives you the same setup conversationally — no manual YAML editing required either way.

---

## Troubleshooting

**"Permission denied" when running install.sh**
```bash
chmod +x install.sh && bash install.sh
```

**"Node.js 20+ is required"**
Install or upgrade from [nodejs.org](https://nodejs.org). Verify with `node -v`.

**"Could not fetch release"**
- Make sure your GitHub token has `repo` scope
- Verify the token hasn't expired
- Ensure your GitHub account has access to the private repository

**Playwright browser install failed**
```bash
cd ~/Elevated-Applicant && npx playwright install chromium
```

---

## Uninstalling

```bash
rm -rf ~/Elevated-Applicant
```

No other files are modified on your system.

---

## License

The installer scripts are MIT licensed. The Elevated Applicant application is proprietary — see its license terms after installation.
