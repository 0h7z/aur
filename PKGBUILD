# Maintainer: Daniele Basso <d dot bass05 at proton dot me>

## links:
# https://www.winehq.org
# https://gitlab.winehq.org/wine/wine
# https://gitlab.winehq.org/wine/wine-staging
# https://github.com/wine-staging/wine-staging

pkgname="wine-wow64"
pkgver=9.20
_pkgver="${pkgver/rc/-rc}"
pkgrel=1
pkgdesc="A compatibility layer for running Windows programs"
url="https://www.winehq.org"
license=('LGPL-2.1-or-later')
arch=('x86_64')

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
	wayland
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

options=(staticlibs !lto)

source=(
	"https://dl.winehq.org/wine/source/${pkgver::1}.x/wine-$_pkgver.tar.xz"
	"30-win32-aliases.conf"
	"wine-binfmt.conf"
)
b2sums=(
	'f2fef5c941284a5f89f92696cb242641ad88ea8a4388dd6d72977d9696ab63c1632b91b678567525527c80e30ad5ef2971e5bcf700e4f2d7db9bf3357488ed34'
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
