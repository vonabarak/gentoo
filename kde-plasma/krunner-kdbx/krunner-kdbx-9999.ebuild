# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit git-r3

DESCRIPTION="KRunner plugin for KDBX database (KeePass/KeePassXC)"
HOMEPAGE="https://github.com/vonabarak/krunner-kdbx"
EGIT_REPO_URI="https://github.com/vonabarak/krunner-kdbx.git"

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64"
IUSE=""

DISTUTILS_SINGLE_IMPL=1
DISTUTILS_USE_PEP517=poetry
PYTHON_COMPAT=( python3_{10..13} )

inherit distutils-r1

DEPEND="dev-lang/python"
RDEPEND="
	${DEPEND}
	$(python_gen_cond_dep '
		>=dev-python/pyotp-2.9.0[${PYTHON_USEDEP}]
		>=dev-python/dbus-python-1.3.2[${PYTHON_USEDEP}]
		>=dev-python/setproctitle-1.3.3[${PYTHON_USEDEP}]
		>=dev-python/pykeepass-4.0.7[${PYTHON_USEDEP}]
	')
"
BDEPEND=""

src_prepare() {
	default
}

src_install() {
	distutils-r1_src_install

	local exec_dir="${D}/usr/libexec/"
	mkdir -p ${exec_dir} || die
	mv "${D}/usr/bin/krunner-kdbx" ${exec_dir} || die
	mv "${D}/usr/bin/krunner-kdbx-helper" ${exec_dir} || die
	rmdir "${D}/usr/bin"

	dodoc config.json

	insinto /usr/share/krunner/dbusplugins
	doins "${WORKDIR}/${P}/krunner-kdbx.desktop"

	insinto /usr/share/dbus-1/services
	doins "${WORKDIR}/${P}/org.kde.krunner_kdbx.service"

	dodoc README.md
}

pkg_postinst() {
	elog "Copy config.json file to ~/.config/krunner-kdbx"
	elog "and edit it to accordingly."
}

