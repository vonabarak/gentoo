# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit git-r3

DESCRIPTION="VRAM-based filesystem for Linux"
HOMEPAGE="https://github.com/Overv/vramfs"
EGIT_REPO_URI="https://github.com/Overv/vramfs.git"

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64"

RDEPEND="
	sys-fs/fuse
	virtual/opencl
"
BDEPEND="
	dev-libs/clhpp
	dev-util/opencl-headers
	virtual/pkgconfig
"

# TODO: Modify Makefile to respect user flags

src_install() {
	dobin bin/vramfs
	dodoc README.md
}
