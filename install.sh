#!/usr/bin/env bash
set -euo pipefail

# Elevated Applicant — Public Installer
# Downloads the latest app bundle from the private repo using a GitHub token.
# Usage: bash install.sh
#   GITHUB_TOKEN env var or prompted interactively.

RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

REPO="jssturm/Elevated-Applicant"
RELEASE_API="https://api.github.com/repos/$REPO/releases/latest"
INSTALL_DIR="${HOME}/Elevated-Applicant"

echo -e "${BOLD}Elevated Applicant — Installer${NC}"
echo ""

# ── Check deps ────────────────────────────────────────────────────────
command -v curl >/dev/null 2>&1 || { echo -e "${RED}Error: curl is required.${NC}"; exit 1; }
command -v tar >/dev/null 2>&1 || { echo -e "${RED}Error: tar is required.${NC}"; exit 1; }
command -v node >/dev/null 2>&1 || { echo -e "${RED}Error: Node.js 20+ is required. Install from https://nodejs.org${NC}"; exit 1; }

NODE_VERSION=$(node -v | sed 's/v//' | cut -d. -f1)
if [ "$NODE_VERSION" -lt 20 ]; then
  echo -e "${RED}Error: Node.js 20+ required. Found v$(node -v).${NC}"
  exit 1
fi
echo -e "  ${GREEN}✓${NC} Node.js $(node -v)"

# ── GitHub token ───────────────────────────────────────────────────────
if [ -n "${GITHUB_TOKEN:-}" ]; then
  TOKEN="$GITHUB_TOKEN"
else
  echo ""
  echo -e "  This installer downloads from a ${BOLD}private${NC} GitHub repository."
  echo -e "  Create a token at: ${CYAN}https://github.com/settings/tokens${NC}"
  echo -e "  (needs ${BOLD}repo${NC} scope — or just 'read:packages' for releases)"
  echo ""
  read -rsp "  GitHub personal access token: " TOKEN
  echo ""
fi

if [ -z "$TOKEN" ]; then
  echo -e "${RED}Error: GitHub token is required.${NC}"
  exit 1
fi

# ── Download latest release ────────────────────────────────────────────
echo -e "${CYAN}→${NC} Fetching latest release..."
RELEASE_JSON=$(curl -sf -H "Authorization: token $TOKEN" "$RELEASE_API") || {
  echo -e "${RED}Error: Could not fetch release. Check your token and repo access.${NC}"
  exit 1
}

# Find the Linux asset (.tar.gz) — prefer linux named, fall back to any .tar.gz
ASSET_URL=$(echo "$RELEASE_JSON" | grep -o '"url": *"[^"]*"' | head -1 | cut -d'"' -f4)
# Actually, we need to parse properly. Let's use a simpler approach:
# Get the asset API URL for a .tar.gz file
ASSET_URL=$(echo "$RELEASE_JSON" | python3 -c "
import json, sys
data = json.load(sys.stdin)
for a in data.get('assets', []):
    if '.tar.gz' in a.get('name', ''):
        print(a['url'])
        break
" 2>/dev/null)

if [ -z "$ASSET_URL" ]; then
  echo -e "${RED}Error: No Linux release asset found.${NC}"
  echo "Available assets:"
  echo "$RELEASE_JSON" | grep '"name"'
  exit 1
fi

VERSION=$(echo "$RELEASE_JSON" | grep '"tag_name"' | head -1 | cut -d'"' -f4)
echo -e "  ${GREEN}✓${NC} Found $VERSION"

# ── Download & extract ─────────────────────────────────────────────────
echo -e "${CYAN}→${NC} Downloading..."
TMP_DIR=$(mktemp -d)
curl -sfL -H "Authorization: token $TOKEN" -H "Accept: application/octet-stream" \
  -o "$TMP_DIR/bundle.tar.gz" "$ASSET_URL" || {
  echo -e "${RED}Error: Download failed.${NC}"
  rm -rf "$TMP_DIR"
  exit 1
}

echo -e "${CYAN}→${NC} Extracting to $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"
tar -xzf "$TMP_DIR/bundle.tar.gz" -C "$INSTALL_DIR" 2>/dev/null || {
  # Try stripping the top-level directory
  tar -xzf "$TMP_DIR/bundle.tar.gz" -C "$INSTALL_DIR" --strip-components=1 2>/dev/null || {
    echo -e "${RED}Error: Extraction failed.${NC}"
    rm -rf "$TMP_DIR"
    exit 1
  }
}
rm -rf "$TMP_DIR"

# ── Install deps ───────────────────────────────────────────────────────
echo -e "${CYAN}→${NC} Installing dependencies..."
cd "$INSTALL_DIR"
npm install --silent 2>/dev/null || echo -e "  (warnings during install are normal)"

echo -e "${CYAN}→${NC} Setting up Playwright browser (this may take a minute)..."
if npx playwright install chromium; then
  echo -e "  ${GREEN}✓${NC} Playwright Chromium installed"
else
  echo -e "  ${YELLOW}⚠${NC} Playwright install had issues. Run manually if you need PDFs:"
  echo -e "      cd $INSTALL_DIR && npx playwright install chromium"
fi

# ── Done ───────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}  Elevated Applicant installed!${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${BOLD}Next steps:${NC}"
echo -e "  1. cd $INSTALL_DIR"
echo -e "  2. Open in your AI CLI: ${GREEN}claude${NC} (or opencode, codex, gemini)"
echo -e "  3. Start the dashboard: ${GREEN}elevated-applicant serve --open${NC}"
echo ""
