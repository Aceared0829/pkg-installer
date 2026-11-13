#!/usr/bin/env bash
# install.sh — 把 pkg-installer + pkg2local 装进 ~/.local
#
#   ./install.sh              从本地仓库安装（可重复执行，覆盖升级）
#   ./install.sh --uninstall  卸载
#
# 也支持不 clone 直接跑：
#   curl -fsSL https://raw.githubusercontent.com/Aceared0829/pkg-installer/main/install.sh | bash
#
set -euo pipefail

REPO_RAW="${REPO_RAW:-https://raw.githubusercontent.com/Aceared0829/pkg-installer/main}"
PREFIX="${PREFIX:-$HOME/.local}"
BIN="$PREFIX/bin"
APPS="$PREFIX/share/applications"
ICONS="$PREFIX/share/icons/hicolor"

c_red=$'\033[31m'; c_grn=$'\033[32m'; c_yel=$'\033[33m'; c_off=$'\033[0m'
if [[ -n "${NO_COLOR:-}" || ! -t 1 ]]; then c_red=""; c_grn=""; c_yel=""; c_off=""; fi
ok()   { printf '%s✓%s %s\n' "$c_grn" "$c_off" "$*"; }
warn() { printf '%s!%s %s\n' "$c_yel" "$c_off" "$*"; }
die()  { printf '%s错误:%s %s\n' "$c_red" "$c_off" "$*" >&2; exit 1; }

# ─────────────── 卸载 ───────────────
if [[ "${1:-}" == "--uninstall" ]]; then
  rm -f "$BIN/pkg-installer" "$BIN/pkg2local"
  rm -f "$APPS/pkg-installer.desktop"
  rm -f "$ICONS/scalable/apps/pkg-installer.svg"
  rm -f "$ICONS/128x128/apps/pkg-installer.png"
  rm -f "$ICONS/256x256/apps/pkg-installer.png"
  # 1.x 时代的旧名字，顺手清掉，避免留下两个入口
  rm -f "$BIN/deb-installer" "$BIN/deb2local" "$APPS/deb-installer.desktop"
  rm -f "$ICONS/scalable/apps/deb-installer.svg" \
        "$ICONS/128x128/apps/deb-installer.png" \
        "$ICONS/256x256/apps/deb-installer.png"
  command -v update-desktop-database >/dev/null && update-desktop-database "$APPS" 2>/dev/null || true
  ok "已卸载（用这个工具装的应用留在 ~/.local/opt，需要的话手动删）"
  exit 0
fi

# ─────────────── 拿到源码 ───────────────
# 本地仓库模式：install.sh 旁边就是 bin/；管道模式：临时下载到一个工作目录
CLEANUP=""
resolve_src() {
  local self_dir=""
  if [[ -n "${BASH_SOURCE[0]:-}" && -f "${BASH_SOURCE[0]}" ]]; then
    self_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
  fi
  if [[ -n "$self_dir" && -f "$self_dir/bin/pkg2local" && -f "$self_dir/bin/pkg-installer" ]]; then
    SRC_DIR="$self_dir"
    echo "从本地仓库安装：$SRC_DIR"
    return
  fi

  echo "从 GitHub 下载：$REPO_RAW"
  local tmp
  tmp=$(mktemp -d)
  CLEANUP="$tmp"
  trap 'rm -rf "$CLEANUP"' EXIT
  local f
  for f in bin/pkg2local bin/pkg-installer desktop/pkg-installer.desktop desktop/pkg-installer.svg; do
    mkdir -p "$tmp/$(dirname "$f")"
    curl -fsSL "$REPO_RAW/$f" -o "$tmp/$f" \
      || die "下载失败：$REPO_RAW/$f"
  done
  SRC_DIR="$tmp"
}
resolve_src

# ─────────────── 依赖检查 ───────────────
echo "检查依赖..."
missing=()
command -v bsdtar >/dev/null || missing+=("libarchive")     # 解 .rpm

# .deb 和 .rpm 都只需要 libarchive：deb 走 bsdtar -xOf 读 control.tar.*，
# rpm 走 bsdtar 或内置 python 解包器。dpkg / rpm-tools 都是可选的加速项。
command -v python3 >/dev/null || missing+=("python")

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
  sudo pacman -S --needed libarchive python python-gobject gtk4 libadwaita"
  else
    die "缺这些：${missing[*]}
本项目只支持 Arch 系（需要 pacman + bsdtar）。"
  fi
fi
ok "依赖齐全"

# ─────────────── 安装 ───────────────
mkdir -p "$BIN" "$APPS" "$ICONS/scalable/apps"

install -m 755 "$SRC_DIR/bin/pkg2local"     "$BIN/pkg2local"
install -m 755 "$SRC_DIR/bin/pkg-installer" "$BIN/pkg-installer"
ok "$BIN/pkg2local"
ok "$BIN/pkg-installer"

# 桌面条目：把 @EXEC@ / @ICON@ 换成真实值
sed -e "s|@EXEC@|$BIN/pkg-installer|g" \
    -e "s|@ICON@|pkg-installer|g" \
    "$SRC_DIR/desktop/pkg-installer.desktop" > "$APPS/pkg-installer.desktop"
chmod 644 "$APPS/pkg-installer.desktop"
ok "$APPS/pkg-installer.desktop"

install -m 644 "$SRC_DIR/desktop/pkg-installer.svg" "$ICONS/scalable/apps/pkg-installer.svg"
# 有些面板（COSMIC 等）只认位图
if command -v rsvg-convert >/dev/null; then
  mkdir -p "$ICONS/128x128/apps" "$ICONS/256x256/apps"
  rsvg-convert -w 128 -h 128 "$SRC_DIR/desktop/pkg-installer.svg" -o "$ICONS/128x128/apps/pkg-installer.png"
  rsvg-convert -w 256 -h 256 "$SRC_DIR/desktop/pkg-installer.svg" -o "$ICONS/256x256/apps/pkg-installer.png"
fi
ok "$ICONS/scalable/apps/pkg-installer.svg"

command -v update-desktop-database >/dev/null && update-desktop-database "$APPS" 2>/dev/null || true
command -v gtk-update-icon-cache    >/dev/null && gtk-update-icon-cache -q -t -f "$ICONS" 2>/dev/null || true

# 把 .deb / .rpm / .flatpak 文件关联到这个程序
# （AppImage 没有统一的 MIME 类型，各系统的 shared-mime-info 里叫法不一，不注册）
if command -v xdg-mime >/dev/null; then
  for m in application/vnd.debian.binary-package application/x-deb \
           application/x-rpm application/x-redhat-package-manager \
           application/vnd.flatpak application/x-flatpak \
           application/vnd.flatpak.ref application/vnd.flatpak.repo; do
    xdg-mime default pkg-installer.desktop "$m" 2>/dev/null || true
  done
fi

# flatpak 是可选的，但装了 .flatpak 文件才用得上，提醒一句
if ! command -v flatpak >/dev/null; then
  warn "没装 flatpak —— 只能装 .deb / .rpm / .AppImage。要用 .flatpak 的话：sudo pacman -S flatpak"
fi

echo
ok "装好了"
echo "  打开界面:  pkg-installer"
echo "  命令行:    pkg2local 包.deb     （.rpm / .AppImage / .flatpak 一样）"
echo "  双击 .deb / .rpm / .flatpak 也会打开这个界面"
echo
case ":$PATH:" in
  *":$BIN:"*) ;;
  *) echo "  PATH 里没有 $BIN，加一行到 ~/.bashrc："
     echo "    export PATH=\"\$HOME/.local/bin:\$PATH\"" ;;
esac
