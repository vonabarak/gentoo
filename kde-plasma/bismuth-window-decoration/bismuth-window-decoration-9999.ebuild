# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Bismuth window decoration for Plasma/KWin 6"
HOMEPAGE="https://github.com/ivan-cukic/kwin6-bismuth-decoration"
EGIT_REPO_URI="https://github.com/ivan-cukic/kwin6-bismuth-decoration.git"

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64"
IUSE=""

inherit git-r3 cmake

DEPEND="
	kde-plasma/kdecoration:6
	kde-plasma/kwin:6
	virtual/pkgconfig
	dev-build/cmake
"

RDEPEND="${DEPEND}"

src_configure() {
	cmake_args=(
		-DCMAKE_INSTALL_PREFIX=/usr
	)
	cmake_src_configure
}

