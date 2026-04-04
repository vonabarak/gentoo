# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

MY_PN="${PN/-bin/}"

DESCRIPTION="QEMU/KVM virtual machine management daemon with CLI client"
HOMEPAGE="https://github.com/vonabarak/corvus"
SRC_URI="https://github.com/vonabarak/${MY_PN}/releases/download/v${PV}/${MY_PN}-${PV}-linux-amd64.tar.gz -> ${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="amd64"
IUSE="systemd"

RDEPEND="
	app-emulation/qemu
	net-dns/dnsmasq
	net-firewall/nftables
	net-misc/passt
	dev-db/postgresql
	app-emulation/virtiofsd
"

S="${WORKDIR}"

QA_PRESTRIPPED="usr/bin/corvus usr/bin/crv"

src_install() {
	dobin corvus
	dobin crv

	if use systemd; then
		insinto /usr/lib/systemd/user
		doins corvus.service
	fi

	dodoc example-apply.yml
}

pkg_postinst() {
	elog "Corvus requires a PostgreSQL database."
	elog "Create one with: createdb corvus"
	elog ""
	elog "Start the daemon:"
	elog "  corvus --database postgresql://localhost/corvus"
	elog ""
	if use systemd; then
		elog "Or as a systemd user service:"
		elog "  systemctl --user enable --now corvus.service"
		elog ""
	fi
	elog "Manage VMs with the crv CLI:"
	elog "  crv vm list"
	elog "  crv disk list"
	elog ""
	elog "User namespaces must be enabled in the kernel (CONFIG_USER_NS=y)"
	elog "for unprivileged virtual networking."
}
