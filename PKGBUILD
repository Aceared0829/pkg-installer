# Maintainer: Acear <zzn1982638980@gmail.com>
pkgname=pkg-installer
pkgver=2.1.0
pkgrel=1
pkgdesc="Install .deb, .rpm, .AppImage and .flatpak packages on Arch Linux without root, into your home directory"
arch=('any')
url="https://github.com/Aceared0829/pkg-installer"
license=('MIT')
depends=('bash' 'libarchive' 'python-gobject' 'gtk4' 'libadwaita')
optdepends=(
  'dpkg: read .deb headers (falls back to bsdtar)'
  'rpm-tools: read .rpm headers (falls back to the built-in python parser)'
  'flatpak: install .flatpak bundles'
)
source=("$pkgname-$pkgver.tar.gz::$url/archive/v$pkgver.tar.gz")
sha256sums=('6b5812b3efe3698a59e362e07e290f42e7d174bb0e334e574eb92e682a387c82')

package() {
  install -Dm755 "$srcdir/$pkgname-$pkgver/bin/pkg2local"     "$pkgdir/usr/bin/pkg2local"
  install -Dm755 "$srcdir/$pkgname-$pkgver/bin/pkg-installer" "$pkgdir/usr/bin/pkg-installer"

  install -Dm644 "$srcdir/$pkgname-$pkgver/desktop/pkg-installer.desktop" \
    "$pkgdir/usr/share/applications/pkg-installer.desktop"
  sed -i -e "s|@EXEC@|/usr/bin/pkg-installer|g" \
         -e "s|@ICON@|pkg-installer|g" \
         "$pkgdir/usr/share/applications/pkg-installer.desktop"

  install -Dm644 "$srcdir/$pkgname-$pkgver/desktop/pkg-installer.svg" \
    "$pkgdir/usr/share/icons/hicolor/scalable/apps/pkg-installer.svg"
  install -Dm644 "$srcdir/$pkgname-$pkgver/docs/icon.png" \
    "$pkgdir/usr/share/icons/hicolor/256x256/apps/pkg-installer.png"

  install -Dm644 "$srcdir/$pkgname-$pkgver/LICENSE" "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
  install -Dm644 "$srcdir/$pkgname-$pkgver/README.md" "$pkgdir/usr/share/doc/$pkgname/README.md"
}
