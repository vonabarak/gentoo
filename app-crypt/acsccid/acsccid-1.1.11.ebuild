# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Driver for ACS CCID smart card readers"
HOMEPAGE="https://github.com/acshk/acsccid"
SRC_URI="https://github.com/acshk/acsccid/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64"

DEPEND="
	>=sys-apps/pcsc-lite-1.8.3
	>=dev-libs/libusb-1.0.9
	sys-devel/flex
	dev-lang/perl
	virtual/pkgconfig
"
RDEPEND="${DEPEND}"
BDEPEND=""

src_unpack() {
	default
	unpack ${A}
}

src_configure() {
	./bootstrap || die "Bootstrap script failed"
	econf
}

src_compile() {
	emake
}

src_install() {
	emake DESTDIR="${D}" install
}

pkg_postinst() {
	elog "The ACS CCID driver has been installed."
}
