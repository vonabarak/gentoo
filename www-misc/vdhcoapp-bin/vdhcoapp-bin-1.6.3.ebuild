# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

BN="net.downloadhelper.coapp"
MY_PN="${PN/-bin/}"

DESCRIPTION="Companion application for Video DownloadHelper browser add-on"
HOMEPAGE="https://www.downloadhelper.net/"
SRC_URI="https://github.com/mi-g/${MY_PN}/releases/download/v${PV}/${BN}-${PV}-1_amd64.tar.gz"
#SRC_URI="https://github.com/mi-g/vdhcoapp/releases/download/v1.6.2/net.downloadhelper.coapp-1.6.2-1_amd64.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="chrome +firefox"

RDEPEND="dev-lang/orc media-video/ffmpeg[amr,mp3,opus,theora,vorbis,webp,x264,x265]"
DEPEND="${RDEPEND}"

S="${WORKDIR}/${BN}-${PV}"

src_install() {
	dobin bin/${BN}-linux-64
	insinto /usr/share/"${MY_PN}"
	doins config.json
}
