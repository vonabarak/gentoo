# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Open-source PKCS#11 module for Serbian ID smart cards (Gemalto)"
HOMEPAGE="https://github.com/ubavic/srb-id-pkcs11"
EGIT_REPO_URI="https://github.com/ubavic/srb-id-pkcs11.git"

declare -g -r -A ZBS_DEPENDENCIES=(
	[base-0.1.0-rhH4pnYnBQAwcgeqIX63Yqx2TsUr5ubNf8jYE5BhE4Dn.tar.gz]='https://github.com/kofi-q/base-z/archive/fd20656c029dff054bb19d7da65291624ff23865.tar.gz'
	[pcsc-0.1.0-sAX2fnAiBgAsMiOGdcAebgI55RHphGaBCQbx4m_P9xtU.tar.gz]='https://github.com/kofi-q/pcsc-z/archive/72ca6c7a07f4ec7d42dee3502b7ccdb5993b3858.tar.gz'
)

PKCS11_BASE_URI="https://docs.oasis-open.org/pkcs11/pkcs11-base/v2.40/errata01/os/include/pkcs11-v2.40"

ZIG_SLOT="0.15"
inherit zig git-r3

LICENSE="Unlicense"
SLOT="0"
KEYWORDS=""
IUSE=""

BDEPEND="dev-lang/zig"
DEPEND="sys-apps/pcsc-lite"
RDEPEND="${DEPEND}"

SRC_URI="
	${ZBS_DEPENDENCIES_SRC_URI}
	${PKCS11_BASE_URI}/pkcs11.h -> pkcs11-v2.40-pkcs11.h
	${PKCS11_BASE_URI}/pkcs11f.h -> pkcs11-v2.40-pkcs11f.h
	${PKCS11_BASE_URI}/pkcs11t.h -> pkcs11-v2.40-pkcs11t.h
"

PATCHES=(
	"${FILESDIR}/no-download-headers.patch"
)

src_unpack() {
	git-r3_src_unpack
	zig_src_unpack
}

src_prepare() {
	zig_src_prepare

	# Copy PKCS#11 headers to source tree
	local pkcs11_dir="${S}/include"
	mkdir -p "${pkcs11_dir}" || die
	cp "${DISTDIR}/pkcs11-v2.40-pkcs11.h" "${pkcs11_dir}/pkcs11.h" || die
	cp "${DISTDIR}/pkcs11-v2.40-pkcs11f.h" "${pkcs11_dir}/pkcs11f.h" || die
	cp "${DISTDIR}/pkcs11-v2.40-pkcs11t.h" "${pkcs11_dir}/pkcs11t.h" || die
}

pkg_postinst() {
	elog "Installed PKCS#11 module:"
	elog "  /usr/$(get_libdir)/libsrb-id-pkcs11.so"
	elog
	elog "Ensure pcscd is running and your reader is visible in pcsc_scan."
	elog
	elog "To register in an NSS DB (LibreOffice/Firefox-style), e.g.:"
	elog "  modutil -dbdir sql:\$HOME/.pki/nssdb \\"
	elog "    -add \"Srb ID PKCS11\" \\"
	elog "    -libfile /usr/$(get_libdir)/libsrb-id-pkcs11.so"
}
