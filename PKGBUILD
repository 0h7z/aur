_name=7-zip
pkgname=${_name}-full
pkgver=23.01
pkgrel=5
pkgdesc='File archiver with a high compression ratio (full package to replace p7zip)'
url='https://7-zip.org/'
license=('LGPL-2.1-or-later' 'BSD-3-Clause' 'LicenseRef-UnRAR')
arch=('x86_64' 'i686' 'aarch64' 'armv7h')
provides=("${_name}" 'p7zip' '7z.so')
conflicts=("${_name}" 'p7zip')
makedepends=('git' 'uasm')

_repo='7zip'
_url="https://github.com/ip7z/${_repo}"
_manarc="7z${pkgver//./}-linux-x64.tar.xz"

source=(
    "git+${_url}.git#tag=${pkgver}"
    "${_url}/releases/download/${pkgver}/${_manarc}" # to get the manual
    '01-make.patch'
    '02-lib-load-path.patch'
)

sha256sums=(
    '438b2500d17cbb84f532666d17a3d48775653f914ffa1365ec18a28f4eec1745'
    '23babcab045b78016e443f862363e4ab63c77d75bc715c0b3463f6134cbcf318'
    '59dee0da982a8da84af8f7b7a08868d4e8ccffd02be82b97834dd4024ddbd38b'
    'ac846e73d248cc51e3005d62d68f77a97c13d6baaae5c159e9fd35919921558d'
)

noextract=("${_manarc}")

prepare() {
    for p in *.patch; do
        patch -p1 -d "${_repo}" < "${p}"
    done
}

_make() {
    echo "Building '${1}'..."
    cd "${1}"
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
    CFLAGS_ADD="${CFLAGS}"
    LDFLAGS_ADD="${LDFLAGS}"
    CXXFLAGS_ADD="${CXXFLAGS}"
    set +a

    cd "${_repo}"
    local targets=('CPP/7zip/'{'UI/Console','Bundles/'{'Alone','Alone7z','Format7zF'}})
    for target in "${targets[@]}"; do
        (_make "${target}")
    done
}

build() {
    (_build)
}

package() {
    cd "${_repo}"

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
