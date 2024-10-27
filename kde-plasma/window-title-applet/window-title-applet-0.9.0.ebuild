# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="KDE Plasma 6 Window Title Applet"
HOMEPAGE="https://github.com/dhruv8sh/plasma6-window-title-applet"
SRC_URI="https://github.com/dhruv8sh/plasma6-window-title-applet/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64"
IUSE=""

DEPEND="kde-plasma/plasma-workspace"
RDEPEND="${DEPEND}"

src_unpack(){
	default
	mv ${WORKDIR}/plasma6-${P} ${WORKDIR}/${P} || die
}

src_install() {
	install_dir="${D}/usr/share/plasma/plasmoids/org.kde.windowtitle"
	mkdir -p ${install_dir}
	cp -R "${S}/contents" "${install_dir}" || die "Install failed!"
	cp "${S}/metadata.json" "${install_dir}" || die "Install failed!"
	dodoc README.md
}

