# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit unpacker xdg

DESCRIPTION="Discover, download, and run local LLMs"
HOMEPAGE="https://lmstudio.ai/"
SRC_URI="https://installers.lmstudio.ai/linux/x64/${PV}-1/LM-Studio-${PV}-1-x64.deb"

S="${WORKDIR}"

LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="bindist mirror strip"
RDEPEND="virtual/libcrypt:="

# LM Studio is distributed as a prebuilt Electron application.
QA_DT_NEEDED="*"
QA_PREBUILT="*"
QA_SONAME="*"
# CUDA is supplied by the optional NVIDIA driver; the embedded Python loader
# resolves this library relative to its own directory.
REQUIRES_EXCLUDE='
	libcuda.so.1
	$ORIGIN/../lib/libpython3.11.so.1.0
'

src_unpack() {
	unpack_deb "${A}"
}

src_compile() {
	:
}

src_install() {
	cp -pPR "${S}"/. "${ED}" || die

	# The Debian desktop file uses a non-standard, lowercase Categories key.
	sed -i '/^category=/d' \
		"${ED}/usr/share/applications/ai.elementlabs.lmstudio.desktop" || die

	# Install upstream's compressed changelog through Gentoo's documentation
	# helper so that it is placed under /usr/share/doc/${PF} and recompressed
	# only once by docompress.
	gzip -cd usr/share/doc/lm-studio/changelog.gz > "${T}/changelog" || die
	rm -r "${ED}/usr/share/doc" || die
	dodoc "${T}/changelog"
}

pkg_postinst() {
	xdg_desktop_database_update
	xdg_icon_cache_update
}

pkg_postrm() {
	xdg_desktop_database_update
	xdg_icon_cache_update
}
