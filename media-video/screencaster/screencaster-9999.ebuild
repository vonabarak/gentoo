# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit git-r3

DESCRIPTION="A small utility to grab the X11 screen using ffmpeg"
HOMEPAGE="https://github.com/vonabarak/screencaster"
EGIT_REPO_URI="https://github.com/vonabarak/screencaster.git"

LICENSE="BSD"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE="vaapi"

RDEPEND="
	media-video/ffmpeg
	dev-python/QtPy
	x11-libs/libX11
	vaapi? ( media-video/ffmpeg[vaapi] )
"
DEPEND="${RDEPEND}"

src_install() {
	dobin screencaster
}

