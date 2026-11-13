#!/usr/bin/env bash
# install.sh — 把 deb-installer + deb2local 装进 ~/.local
#
#   ./install.sh              安装（可重复执行，覆盖升级）
#   ./install.sh --uninstall  卸载
#
set -euo pipefail

SRC_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PREFIX="${PREFIX:-$HOME/.local}"
BIN="$PREFIX/bin"
APPS="$PREFIX/share/applications"
ICONS="$PREFIX/share/icons/hicolor"

c_red=$'\033[31m'; c_grn=$'\033[32m'; c_yel=$'\033[33m'; c_off=$'\033[0m'
[[ -n "${NO_COLOR:-}" || ! -t 1 ]] && c_red=""; c_grn=""; c_yel=""; c_off=""
ok()   { printf '%s✓%s %s\n' "$c_grn" "$c_off" "$*"; }
warn() { printf '%s!%s %s\n' "$c_yel" "$c_off" "$*"; }
die()  { printf '%s错误:%s %s\n' "$c_red" "$c_off" "$*" >&2; exit 1; }

# ─────────────── 卸载 ───────────────
if [[ "${1:-}" == "--uninstall" ]]; then
  rm -f "$BIN/deb-installer" "$BIN/deb2local"
  rm -f "$APPS/deb-installer.desktop"
  rm -f "$ICONS"/scalable/apps/deb-installer.svg
  rm -f "$ICONS"/128x128/apps/deb-installer.png
  rm -f "$ICONS"/256x256/apps/deb-installer.png
  command -v update-desktop-database >/dev/null && update-desktop-database "$APPS" 2>/dev/null || true
  ok "已卸载（用 deb 装的应用留在 ~/.local/opt，需要的话手动删）"
  exit 0
fi

# ─────────────── 依赖检查 ───────────────
echo "检查依赖..."
missing=()
command -v dpkg-deb >/dev/null || missing+=("dpkg")
command -v pacman   >/dev/null || missing+=("pacman")

have_gi=0
if command -v python3 >/dev/null; then
  python3 - <<'PY' 2>/dev/null && have_gi=1
import gi
gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Gtk, Adw
PY
fi
[[ $have_gi -eq 1 ]] || missing+=("python-gobject" "gtk4" "libadwaita")

if [[ ${#missing[@]} -gt 0 ]]; then
  if command -v pacman >/dev/null; then
    die "缺这些包，先补上：
  sudo pacman -S --needed dpkg python-gobject gtk4 libadwaita"
  else
    die "缺这些：${missing[*]}
本项目只支持 Arch 系（需要 pacman + dpkg-deb）。"
  fi
fi
ok "依赖齐全"

# ─────────────── 安装 ───────────────
mkdir -p "$BIN" "$APPS" \
  "$ICONS/scalable/apps" "$ICONS/128x128/apps" "$ICONS/256x256/apps"

install -m 755 "$SRC_DIR/bin/deb2local"     "$BIN/deb2local"
install -m 755 "$SRC_DIR/bin/deb-installer" "$BIN/deb-installer"
ok "$BIN/deb2local"
ok "$BIN/deb-installer"

# 桌面条目：把 @EXEC@ / @ICON@ 换成真实路径
sed -e "s|@EXEC@|$BIN/deb-installer|g" \
    -e "s|@ICON@|deb-installer|g" \
    "$SRC_DIR/desktop/deb-installer.desktop" > "$APPS/deb-installer.desktop"
chmod 644 "$APPS/deb-installer.desktop"
ok "$APPS/deb-installer.desktop"

install -m 644 "$SRC_DIR/desktop/deb-installer.svg" "$ICONS/scalable/apps/deb-installer.svg"
# 有些面板（COSMIC 等）只认位图
if command -v rsvg-convert >/dev/null; then
  rsvg-convert -w 128 -h 128 "$SRC_DIR/desktop/deb-installer.svg" -o "$ICONS/128x128/apps/deb-installer.png"
  rsvg-convert -w 256 -h 256 "$SRC_DIR/desktop/deb-installer.svg" -o "$ICONS/256x256/apps/deb-installer.png"
fi
ok "$ICONS/scalable/apps/deb-installer.svg"

command -v update-desktop-database >/dev/null && update-desktop-database "$APPS" 2>/dev/null || true
command -v gtk-update-icon-cache    >/dev/null && gtk-update-icon-cache -q -t -f "$ICONS" 2>/dev/null || true

# 把 .deb 文件关联到这个程序
if command -v xdg-mime >/dev/null; then
  xdg-mime default deb-installer.desktop application/vnd.debian.binary-package 2>/dev/null || true
  xdg-mime default deb-installer.desktop application/x-deb 2>/dev/null || true
fi

echo
ok "装好了"
echo "  打开界面:  deb-installer"
echo "  命令行:    deb2local 包.deb"
echo "  双击 .deb 也会打开这个界面"
echo
echo "  PATH 里有 ~/.local/bin 吗？没有的话加一行到 ~/.bashrc："
echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
