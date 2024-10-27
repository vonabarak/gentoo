# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="A dynamic tiling extension for KWin"
HOMEPAGE="https://github.com/anametologin/krohnkite"
SRC_URI="https://github.com/anametologin/krohnkite/archive/refs/tags/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64"

PATCHES=(
    "${FILESDIR}/global-install.patch"
)
DEPEND="
	kde-plasma/kwin:6
	kde-frameworks/kpackage:6
"
RDEPEND="${DEPEND}"
BDEPEND="
	dev-build/make
	app-arch/p7zip
	net-libs/nodejs
	dev-lang/typescript
"

src_prepare() {
	default
}

src_compile() {
	emake
	emake package
}

src_install() {
	emake DESTDIR="${D}/usr/share/kwin/scripts" install
	dodoc README.md
}
