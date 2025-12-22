# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=poetry
PYTHON_COMPAT=( python3_{10..14} )
inherit distutils-r1

DESCRIPTION="Python module for accessing XDG Base Directory paths"
HOMEPAGE="https://github.com/srstevenson/xdg-base-dirs"
SRC_URI="https://github.com/srstevenson/xdg-base-dirs/archive/refs/tags/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="ISC"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

DEPEND=""
RDEPEND="${DEPEND}"

src_prepare() {
	default
}

src_install() {
	distutils-r1_src_install
}

