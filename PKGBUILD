_name=7-zip
pkgname=${_name}-full
pkgver=24.06
pkgrel=1
pkgdesc='File archiver with a high compression ratio (full package to replace p7zip)'
url='https://7-zip.org/'
license=('LGPL-2.1-or-later' 'BSD-3-Clause' 'LicenseRef-UnRAR')
arch=('x86_64' 'i686' 'aarch64' 'armv7h')
provides=("${_name}" 'p7zip' '7z.so')
conflicts=('p7zip')
makedepends=('uasm')

_repo='7zip'
_snapshot="${_repo}-${pkgver}"
_url="https://github.com/ip7z/${_repo}"
_manarc="7z${pkgver//./}-linux-x64.tar.xz"

source=(
    "${_url}/archive/${pkgver}/${_snapshot}.tar.gz"
    "${_url}/releases/download/${pkgver}/${_manarc}" # to get the manual
    '01-make.patch'
    '02-lib-load-path.patch'
)

sha256sums=(
    '0e0d3e2b1baaba81d8b6f5d26e55152fdea4a2453d79ef2d96f3a31405f0ad46'
    '807bd858433b13215abc915cbb9ccdc806fc7b421418a4088a194e1729a6a6b2'
    'f54dfe73ad045f200d5512dfd4387ef626068662a5af6e17d81052996544af54'
    '338b732445d3cfa416e40384bd9f0596506aa4b464b3f86aa971af4cfa6084c7'
)

noextract=("${_manarc}")

prepare() {
    for p in *.patch; do
        patch -p1 -d "${_snapshot}" < "${p}"
    done
}

_make() {
    echo "Building '${1}'..."
    cd "${_snapshot}/${1}"
    mkdir -p '_o'
    make -sf 'makefile.gcc'
}

_build() {
    local -A platforms=(['x86_64']='x64' ['i686']='x86' ['aarch64']='arm64' ['armv7h']='arm')

    set -a
    PLATFORM="${platforms["${CARCH}"]}"
    [ "${CARCH}" = 'x86_64' ] && IS_X64=1
    [ "${CARCH}" = 'i686' ] && IS_X86=1
    [ "${CARCH}" = 'aarch64' ] && IS_ARM64=1
    USE_ASM=1
    CFLAGS_WARN='-Wno-error'
    CFLAGS_USER="${CFLAGS}"
    CXXFLAGS_USER="${CXXFLAGS}"
    LDFLAGS_USER="${LDFLAGS}"
    set +a

    for target in "$@"; do
        (_make "${target}")
    done
}

build() {
    (_build 'CPP/7zip/'{'UI/Console','Bundles/'{'Alone','Alone7z','Format7zF'}})
}

package() {
    cd "${_snapshot}"

    install -Dm755 -t "${pkgdir}/usr/bin" \
        'CPP/7zip/'{'UI/Console/_o/7z','Bundles/'{'Alone/_o/7za','Alone7z/_o/7zr'}}

    install -Dm644 -t "${pkgdir}/usr/lib" \
        'CPP/7zip/Bundles/Format7zF/_o/7z.so'

    install -Dm644 -t "${pkgdir}/usr/share/licenses/${pkgname}" \
        'DOC/unRarLicense.txt'

    local doc="${pkgdir}/usr/share/doc/${pkgname}"
    install -Dm644 -t "${doc}" \
        'DOC/'{'7zC.txt','7zFormat.txt','lzma.txt','Methods.txt','readme.txt','src-history.txt'}

    bsdtar -C "${doc}" -xf "${srcdir}/${_manarc}" 'MANUAL'
}
