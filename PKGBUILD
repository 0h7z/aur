# Maintainer: Daniele Basso <d dot bass05 at proton dot me>

## links:
# https://www.winehq.org
# https://gitlab.winehq.org/wine/wine
# https://gitlab.winehq.org/wine/wine-staging
# https://github.com/wine-staging/wine-staging

pkgname="wine-wow64"
pkgver=9.17
_pkgver="${pkgver/rc/-rc}"
pkgrel=1
pkgdesc="A compatibility layer for running Windows programs"
url="https://www.winehq.org"
license=('LGPL-2.1-or-later')
arch=('x86_64')

depends=(
  alsa-lib              #lib32-alsa-lib
  fontconfig            #lib32-fontconfig
  freetype2             #lib32-freetype2
  gettext               #lib32-gettext
  gnutls                #lib32-gnutls
  gst-plugins-base-libs #lib32-gst-plugins-base-libs
  libpcap               #lib32-libpcap
  libpulse              #lib32-libpulse
  libxcomposite         #lib32-libxcomposite
  libxcursor            #lib32-libxcursor
  libxi                 #lib32-libxi
  libxinerama           #lib32-libxinerama
  libxkbcommon          #lib32-libkbcommon
  libxrandr             #lib32-libxrandr
  opencl-icd-loader     #lib32-opencl-icd-loader
  pcsclite              #lib32-pcsclite
  sdl2                  #lib32-sdl2
  unixodbc              #lib32-unixodbc
  v4l-utils             #lib32-v4l-utils
  wayland               #lib32-wayland
  desktop-file-utils
  libgphoto2
)
makedepends=(
  libxxf86vm        #lib32-libxxf86vm
  mesa              #lib32-mesa
  mesa-libgl        #lib32-mesa-libgl
  vulkan-icd-loader #lib32-vulkan-icd-loader
  autoconf
  bison
  flex
  mingw-w64-gcc
  opencl-headers
  perl
  vulkan-headers
)
local _makeoptdeps=(
  ::alsa-plugins #lib32-alsa-plugins
  ::dosbox
  libcups::cups #lib32-libcups
  samba::samba
  sane::sane
)
for i in "${_makeoptdeps[@]}"; do
  [ -n "${i%%::*}" ] && makedepends+=("${i%%::*}")
  [ -n "${i##*::}" ] && optdepends+=("${i##*::}")
done

provides=("wine=$pkgver")
conflicts=("wine")

install="wine.install"
backup=("usr/lib/binfmt.d/wine.conf")

options=(staticlibs !lto)

source=(
  "https://dl.winehq.org/wine/source/${pkgver::1}.x/wine-$_pkgver.tar.xz"
  "30-win32-aliases.conf"
  "wine-binfmt.conf"
)
b2sums=(
  '36049b7ed096865a647cea9ac1def6cf2a35984a72ae192d402a40f34c8a97e967cee31724d84d422f835f272fcba9ba818e1e787f7940b18d835aa234b0c6b7'
  '45db34fb35a679dc191b4119603eba37b8008326bd4f7d6bd422fbbb2a74b675bdbc9f0cc6995ed0c564cf088b7ecd9fbe2d06d42ff8a4464828f3c4f188075b'
  'e9de76a32493c601ab32bde28a2c8f8aded12978057159dd9bf35eefbf82f2389a4d5e30170218956101331cf3e7452ae82ad0db6aad623651b0cc2174a61588'
)

build() {
  # Apply flags for cross-compilation
  export CROSSCFLAGS="-O2 -pipe"
  export CROSSCXXFLAGS="-O2 -pipe"
  export CROSSLDFLAGS="-Wl,-O1"

  mkdir -p build
  cd build
  ../wine-$_pkgver/configure \
    --disable-tests \
    --prefix=/usr \
    --libdir=/usr/lib \
    --with-wayland \
    --enable-archs=x86_64,i386
  make
}

package() {
  cd build
  make prefix="$pkgdir"/usr \
    libdir="$pkgdir"/usr/lib \
    dlldir="$pkgdir"/usr/lib/wine install

  ln -sf /usr/bin/wine "$pkgdir"/usr/bin/wine64

  # Font aliasing settings for Win32 applications
  install -Dm644 "$srcdir"/30-win32-aliases.conf -t "$pkgdir"/usr/share/fontconfig/conf.avail/
  install -d "$pkgdir"/usr/share/fontconfig/conf.default
  ln -s ../conf.avail/30-win32-aliases.conf "$pkgdir"/usr/share/fontconfig/conf.default/30-win32-aliases.conf

  install -Dm644 "$srcdir"/wine-binfmt.conf "$pkgdir"/usr/lib/binfmt.d/wine.conf
}

# vim:set ts=8 sts=2 sw=2 et:
