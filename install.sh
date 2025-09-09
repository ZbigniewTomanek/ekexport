#!/bin/sh
# ekexport installer (macOS arm64 only)
# Usage: curl -fsSL https://raw.githubusercontent.com/ZbigniewTomanek/ekexport/main/install.sh | sh

set -eu

REPO_OWNER="ZbigniewTomanek"
REPO_NAME="ekexport"
API_URL="https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/latest"
INSTALL_DIR="/usr/local/bin"
CMD_NAME="ekexport"

say() { printf "%s\n" "$*"; }
err() { printf "Error: %s\n" "$*" >&2; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    err "Required command '$1' not found in PATH."; exit 1;
  }
}

cleanup() { [ -n "${TMPDIR:-}" ] && [ -d "$TMPDIR" ] && rm -rf "$TMPDIR" || true; }
trap cleanup EXIT INT HUP

need_cmd uname
need_cmd curl
need_cmd tar
need_cmd install
need_cmd shasum

# OS check
OS=$(uname -s)
if [ "$OS" != "Darwin" ]; then
  err "This installer supports macOS (Darwin) only."; exit 1
fi

# macOS version check (require 13.0+)
if command -v sw_vers >/dev/null 2>&1; then
  VER=$(sw_vers -productVersion 2>/dev/null || echo "0")
else
  VER="0"
fi

major=$(printf "%s" "$VER" | cut -d. -f1 | grep -E '^[0-9]+$' || echo "0")
minor=$(printf "%s" "$VER" | cut -d. -f2 | grep -E '^[0-9]+$' || echo "0")
major=${major:-0}
minor=${minor:-0}

if ! printf "%s" "$major" | grep -qE '^[0-9]+$' || [ "$major" -lt 13 ]; then
  err "macOS 13 or newer is required (detected $VER)."; exit 1
fi

# Arch check (arm64 only)
ARCH=$(uname -m)
if [ "$ARCH" != "arm64" ]; then
  err "Only Apple Silicon (arm64) is supported by this installer. Detected: $ARCH"
  err "Please use an Apple Silicon Mac running macOS 13+."
  exit 1
fi

TMPDIR=$(mktemp -d 2>/dev/null || mktemp -d -t ekexport)

say "Fetching latest release info..."
JSON=$(curl -fsSL "$API_URL") || { err "Failed to query GitHub API."; exit 1; }

# Extract tag_name and asset URL for arm64 tarball without jq
TAG=$(printf "%s" "$JSON" | grep -o '"tag_name"[[:space:]]*:[[:space:]]*"[^"]*"' | head -n1 | sed 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')

ASSET_URL=$(printf "%s" "$JSON" \
  | grep -o '"browser_download_url"[[:space:]]*:[[:space:]]*"[^"]*"' \
  | grep "macos-arm64.tar.gz" \
  | head -n1 \
  | sed 's/.*"browser_download_url"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')

if [ -z "$ASSET_URL" ]; then
  err "Could not find arm64 release asset in latest release $TAG."; exit 1
fi

say "Latest version: $TAG"
say "Downloading binary..."
# Download using the asset's basename so checksum verification with `shasum -c`
# can reference the correct filename from SHA256SUMS.
BASENAME=$(basename "$ASSET_URL")
ASSET_FILE="$TMPDIR/$BASENAME"
curl -fsSL -o "$ASSET_FILE" "$ASSET_URL" || { err "Download failed."; exit 1; }

# Try to fetch checksums and verify (best-effort)
SUMS_URL=$(printf "%s" "$JSON" \
  | grep -o '"browser_download_url"[[:space:]]*:[[:space:]]*"[^"]*"' \
  | grep "SHA256SUMS" \
  | head -n1 \
  | sed 's/.*"browser_download_url"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')

if [ -n "$SUMS_URL" ]; then
  say "Verifying checksum..."
  curl -fsSL -o "$TMPDIR/SHA256SUMS" "$SUMS_URL" || true
  if [ -s "$TMPDIR/SHA256SUMS" ]; then
    # Verify in TMPDIR so `shasum -c` finds $BASENAME referenced in the sums file
    (
      cd "$TMPDIR"
      grep " $BASENAME\$" "$TMPDIR/SHA256SUMS" | shasum -a 256 -c -
    ) >/dev/null 2>&1 || { err "Checksum verification failed."; exit 1; }
  fi
fi

say "Extracting..."
tar -xzf "$ASSET_FILE" -C "$TMPDIR"

BIN_SRC="$TMPDIR/ekexport/$CMD_NAME"
if [ ! -x "$BIN_SRC" ]; then
  err "Extracted binary not found at $BIN_SRC"; exit 1
fi

TARGET="$INSTALL_DIR/$CMD_NAME"

# Create install dir only if missing; avoid sudo if it already exists
if [ ! -d "$INSTALL_DIR" ]; then
  if [ -w "$(dirname "$INSTALL_DIR")" ]; then
    mkdir -p "$INSTALL_DIR"
  else
    say "Using sudo to create $INSTALL_DIR"
    sudo mkdir -p "$INSTALL_DIR"
  fi
fi

if [ -w "$INSTALL_DIR" ]; then
  install -m 0755 "$BIN_SRC" "$TARGET"
else
  say "Using sudo to install into $INSTALL_DIR"
  if command -v sudo >/dev/null 2>&1; then
    sudo install -m 0755 "$BIN_SRC" "$TARGET"
  else
    err "Write permission to $INSTALL_DIR required and 'sudo' not available."; exit 1
  fi
fi

say "Installed: $TARGET"
say "Version: $TAG"
say "Run: $CMD_NAME --help"
