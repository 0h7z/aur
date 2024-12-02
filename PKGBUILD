# Maintainer: Heptazhou <zhou at 0h7z dot com>

# Maintainer: Daniele Basso <d dot bass05 at proton dot me>

## links:
# https://www.winehq.org
# https://gitlab.winehq.org/wine/wine
# https://gitlab.winehq.org/wine/wine-staging
# https://github.com/wine-staging/wine-staging

pkgname=wine64 # wine-wow64
pkgver=10.0
_pkgver="${pkgver/rc/-rc}"
pkgrel=1
pkgdesc="A compatibility layer for running Windows programs"
url="https://www.winehq.org"
license=(LGPL-2.1-or-later)
arch=(x86_64)

depends=(
	alsa-lib
	fontconfig
	freetype2
	gettext
	gnutls
	gst-plugins-base-libs
	libpcap
	libpulse
	libxcomposite
	libxcursor
	libxi
	libxinerama
	libxkbcommon
	libxrandr
	opencl-icd-loader
	pcsclite
	sdl2
	unixodbc
	v4l-utils
	# wayland
	desktop-file-utils
	libgphoto2
)
makedepends=(
	libxxf86vm
	mesa
	mesa-libgl
	vulkan-icd-loader
	autoconf
	bison
	flex
	mingw-w64-gcc
	opencl-headers
	perl
	vulkan-headers
)
local _makeoptdeps=(
	::alsa-plugins
	::dosbox
	libcups::cups
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

options=(staticlibs strip !debug !lto)

source=(
	"https://dl.winehq.org/wine/source/${pkgver}/wine-$_pkgver.tar.xz"
	"30-win32-aliases.conf"
	"wine-binfmt.conf"
)
b2sums=(
	"92178cf484cf33e9f3b8340429ee8e68c36e0d25eee4a892f059ab73f103cfcb9eb15e1883bc9fd8c8fe311d4ccbb56582d1f780da7b1406a7839a13addd29ae"
	"45db34fb35a679dc191b4119603eba37b8008326bd4f7d6bd422fbbb2a74b675bdbc9f0cc6995ed0c564cf088b7ecd9fbe2d06d42ff8a4464828f3c4f188075b"
	"e9de76a32493c601ab32bde28a2c8f8aded12978057159dd9bf35eefbf82f2389a4d5e30170218956101331cf3e7452ae82ad0db6aad623651b0cc2174a61588"
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
		--enable-archs=x86_64
	make
}

package() {
	cd build
	make prefix="$pkgdir"/usr \
		libdir="$pkgdir"/usr/lib \
		dlldir="$pkgdir"/usr/lib/wine install

	ln -s "$pkgdir"/usr/bin/wine{64,} -r

	# Font aliasing settings for Win32 applications
	install -Dm644 "$srcdir"/30-win32-aliases.conf -t "$pkgdir"/usr/share/fontconfig/conf.avail/
	install -d "$pkgdir"/usr/share/fontconfig/conf.default
	ln -s ../conf.avail/30-win32-aliases.conf "$pkgdir"/usr/share/fontconfig/conf.default/30-win32-aliases.conf

	x86_64-w64-mingw32-strip --strip-unneeded "$pkgdir"/usr/lib/wine/x86_64-windows/*.dll

	install -Dm644 "$srcdir"/wine-binfmt.conf "$pkgdir"/usr/lib/binfmt.d/wine.conf
}
