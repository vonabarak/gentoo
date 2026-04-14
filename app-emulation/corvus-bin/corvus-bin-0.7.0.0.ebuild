# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit bash-completion-r1

MY_PN="${PN/-bin/}"

DESCRIPTION="QEMU/KVM virtual machine management daemon with CLI client"
HOMEPAGE="https://github.com/vonabarak/corvus"
SRC_URI="https://github.com/vonabarak/${MY_PN}/releases/download/v${PV}/${MY_PN}-${PV}-linux-amd64.tar.gz -> ${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="amd64"
IUSE="bash-completion fish-completion systemd vde zsh-completion"

RDEPEND="
	app-emulation/qemu[vde?]
	net-dns/dnsmasq
	net-firewall/nftables
	net-misc/passt
	dev-db/postgresql
	app-emulation/virtiofsd
	net-misc/curl
	app-cdr/cdrtools
	vde? ( net-misc/vde )
	|| ( sys-firmware/edk2-bin sys-firmware/edk2 )
"

S="${WORKDIR}"

QA_PRESTRIPPED="usr/bin/corvus usr/bin/crv"

src_install() {
	dobin corvus
	dobin crv

	if use systemd; then
		sed -i 's|%h/.local/bin/corvus|/usr/bin/corvus|' corvus.service || die
		insinto /usr/lib/systemd/user
		doins corvus.service
	fi

	if use bash-completion; then
		./crv completion bash > crv.bash || die "Failed to generate bash completion"
		newbashcomp crv.bash crv
	fi

	if use zsh-completion; then
		./crv completion zsh > _crv || die "Failed to generate zsh completion"
		insinto /usr/share/zsh/site-functions
		doins _crv
	fi

	if use fish-completion; then
		./crv completion fish > crv.fish || die "Failed to generate fish completion"
		insinto /usr/share/fish/vendor_completions.d
		doins crv.fish
	fi
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
