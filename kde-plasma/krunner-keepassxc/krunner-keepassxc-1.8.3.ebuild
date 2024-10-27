# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="A krunner plugin to copy keepassxc entries to clipboard"
HOMEPAGE="https://github.com/naglfar/krunner-keepassxc"
SRC_URI="https://github.com/naglfar/krunner-keepassxc/archive/refs/tags/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64"
IUSE="systemd"

DISTUTILS_SINGLE_IMPL=1
DISTUTILS_USE_PEP517=poetry
PYTHON_COMPAT=( python3_{9..12} )

inherit distutils-r1 systemd

DEPEND="dev-lang/python"
RDEPEND="
	${DEPEND}
	$(python_gen_cond_dep '
		>=dev-python/pyotp-2.9.0[${PYTHON_USEDEP}]
		>=dev-python/dbus-python-1.3.2[${PYTHON_USEDEP}]
		>=dev-python/setproctitle-1.3.3[${PYTHON_USEDEP}]
		>=dev-python/cryptography-42.0.5[${PYTHON_USEDEP}]
		>=dev-python/xdg-base-dirs-6.0.0[${PYTHON_USEDEP}]
	')
	systemd? ( sys-apps/systemd )
"
BDEPEND=""

distutils_enable_tests unittest

src_prepare() {
	default

	# the name of module dev-python/xdg-base-dirs has changed from xdg to xdg_base_dirs
	sed -i 's|from xdg import xdg_config_home|from xdg_base_dirs import xdg_config_home|g' "${WORKDIR}/${P}/krunner_keepassxc/runner.py" || die
}

src_install() {
	distutils-r1_src_install

	local exec_dir="${D}/usr/libexec/krunner-keepassxc"
	mkdir -p ${exec_dir} || die
	mv "${D}/usr/bin/cli" ${exec_dir} || die
	mv "${D}/usr/bin/runner" ${exec_dir} || die
	rmdir "${D}/usr/bin"

	if use systemd; then
		systemd_douserunit "${FILESDIR}/krunner-keepassxc.service"
	else
		echo "ExecStart=${exec_dir}/runner" >> "${WORKDIR}/${P}/install/krunner-keepassxc_autostart.desktop"
		insinto /etc/xdg/autostart
		doins "${WORKDIR}/${P}/install/krunner-keepassxc_autostart.desktop"
	fi

	insinto /usr/share/krunner/dbusplugins
	doins "${WORKDIR}/${P}/install/krunner-keepassxc.desktop"

	dodoc README.md
}

pkg_postinst() {
	if use systemd; then
		elog "To enable the systemd service, run the following:"
		elog "systemctl --user enable --now krunner-keepassxc.service"
		elog "or the following to enable the service for all users:"
		elog "systemctl --global enable --now krunner-keepassxc.service"
	fi
}

