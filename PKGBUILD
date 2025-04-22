pkgname=nsis
pkgver=3.11
pkgrel=1
pkgdesc='A professional open source system to create Windows installers'
arch=('x86_64')
url='http://nsis.sourceforge.net'
license=('custom:zlib')
depends=('gcc-libs')
makedepends=('scons' 'mingw-w64-gcc' 'mingw-w64-zlib')
options=(!strip)
source=(http://downloads.sourceforge.net/project/nsis/NSIS%203/$pkgver/$pkgname-$pkgver-src.tar.bz2)
sha256sums=('19e72062676ebdc67c11dc032ba80b979cdbffd3886c60b04bb442cdd401ff4b')

prepare() {
  cd "$srcdir/$pkgname-$pkgver-src"
}

build() {
  cd "$srcdir/$pkgname-$pkgver-src"
  scons VERSION=$pkgver PREFIX=/usr PREFIX_CONF=/etc SKIPUTILS='NSIS Menu' STRIP_CP=false ZLIB_W32=/usr/i686-w64-mingw32/ NSIS_MAX_STRLEN=8192 NSIS_CONFIG_LOG=yes
}

package() {
  cd "$srcdir/$pkgname-$pkgver-src"
  scons VERSION=$pkgver PREFIX=/usr PREFIX_CONF=/etc SKIPUTILS='NSIS Menu' STRIP_CP=false ZLIB_W32=/usr/i686-w64-mingw32/ NSIS_MAX_STRLEN=8192 NSIS_CONFIG_LOG=yes PREFIX_DEST="$pkgdir" install
  install -Dm644 ${srcdir}/$pkgname-$pkgver-src/Docs/src/license.but "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
}
