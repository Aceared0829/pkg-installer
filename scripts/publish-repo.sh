#!/usr/bin/env bash
# publish-repo.sh — 把某个 release 里的包发布到 gh-pages 上的 pacman 仓库
#
#   ./scripts/publish-repo.sh v2.2.0
#
# 干的事情和 .github/workflows/publish-repo.yml 一样，只是在本机跑：
# 从 release 下载 .pkg.tar.zst → repo-add 进 gh-pages 的 x86_64/ → 推回去。
#
# 为什么要有这个脚本：GitHub Actions 在这台账号上因为账单问题跑不起来，
# 每次作业都在 setup 阶段被拒（"The job was not started because your account
# is locked due to a billing issue"），日志都拿不到。workflow 留着，等账单
# 恢复就能直接用；在那之前用这个脚本发。
#
# 为什么下载而不是本地编译：release 上的包和仓库里的必须是同一个文件。
# 重新 makepkg 会带上新的 builddate，同一个版本号会产出 sha256 不同的两个
# 包，两边就对不上。
set -euo pipefail

REPO="Aceared0829/pkg-installer"
TAG="${1:-}"

if [[ -z "$TAG" ]]; then
  echo "用法: $0 <tag>     例如 $0 v2.2.0" >&2
  exit 2
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

echo "== 取 release $TAG 里的包 =="
urls=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/tags/$TAG" \
  | grep -o '"browser_download_url": *"[^"]*\.pkg\.tar\.zst"' \
  | sed 's/.*"\(https[^"]*\)"/\1/')
if [[ -z "$urls" ]]; then
  echo "错误: $TAG 这个 release 没有附 .pkg.tar.zst" >&2
  exit 1
fi

cd "$WORK"
while read -r u; do
  echo "  $u"
  curl -fsSLO "$u"
done <<< "$urls"
ls -l ./*.pkg.tar.zst
sha256sum ./*.pkg.tar.zst

echo "== 检出 gh-pages =="
git clone --quiet --branch gh-pages --depth 1 \
  "https://github.com/$REPO.git" pages
cd pages
mkdir -p x86_64
cp "$WORK"/*.pkg.tar.zst x86_64/

echo "== repo-add =="
cd x86_64
for f in *.pkg.tar.zst; do
  repo-add --quiet pkg-installer.db.tar.gz "$f"
done
# GitHub Pages 是静态托管，符号链接会变成一小段文本文件，摊平成实体文件
rm -f pkg-installer.db pkg-installer.files
cp pkg-installer.db.tar.gz    pkg-installer.db
cp pkg-installer.files.tar.gz pkg-installer.files

cd ..
git add -A x86_64
if git diff --cached --quiet; then
  echo "仓库已经是最新，没有改动"
  exit 0
fi
git -c user.name="Aceared0829" -c user.email="zzn1982638980@gmail.com" \
  commit -q -m "repo: 发布 $TAG"
git push origin gh-pages
echo "== 完成：https://aceared0829.github.io/pkg-installer/x86_64 =="
