# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# Binary release of corvus: drops the four stripped Haskell
# binaries plus the Python client + admin CLI (as a wheel) and
# all docs / yaml examples / Cap'n Proto schemas straight from
# the bundled release tarball — no Haskell toolchain required.
# Mirror of app-emulation/corvus's component USE flags so the
# install set is identical between the two packages.
#
# Source ebuild: app-emulation/corvus-${PV}.

PYTHON_COMPAT=( python3_{10..14} )

inherit bash-completion-r1 python-r1

MY_PN="${PN/-bin/}"

DESCRIPTION="QEMU/KVM virtual machine management daemon with CLI client (prebuilt)"
HOMEPAGE="https://github.com/vonabarak/corvus"
SRC_URI="https://github.com/vonabarak/${MY_PN}/releases/download/v${PV}/${MY_PN}-${PV}-linux-amd64.tar.gz -> ${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="amd64"

# Same set of component flags as app-emulation/corvus so a user
# switching between the source and binary packages doesn't need
# to relearn the toggles. At least one component must be enabled.
IUSE="+admin bash-completion +cli +daemon fish-completion +netd +node +python vde zsh-completion"

REQUIRED_USE="
	|| ( admin cli daemon netd node )
	admin? ( python )
	python? ( ${PYTHON_REQUIRED_USE} )
"

RDEPEND="
	!!app-emulation/corvus
	|| ( sys-firmware/edk2-bin sys-firmware/edk2 )
	daemon? (
		dev-db/postgresql
	)
	node? (
		app-emulation/qemu[spice,usb,usbredir,virtfs,passt,vde?]
		app-emulation/virtiofsd
		app-cdr/cdrtools
		net-misc/curl
	)
	netd? (
		net-dns/dnsmasq
		net-firewall/nftables
		net-misc/passt
		vde? ( net-misc/vde )
	)
	python? (
		${PYTHON_DEPS}
		$(python_gen_cond_dep '
			>=dev-python/pycapnp-2.2[${PYTHON_USEDEP}]
			dev-python/pyyaml[${PYTHON_USEDEP}]
		')
	)
	admin? (
		$(python_gen_cond_dep '
			>=dev-python/cryptography-42[${PYTHON_USEDEP}]
			>=dev-python/click-8[${PYTHON_USEDEP}]
			>=dev-python/jinja2-3[${PYTHON_USEDEP}]
		')
	)
"

DEPEND="${RDEPEND}"

BDEPEND="
	python? ( app-arch/unzip )
"

# Tarball top-level dir is ${MY_PN}-${PV}-linux-amd64, not ${P}.
S="${WORKDIR}/${MY_PN}-${PV}-linux-amd64"

# The binaries are pre-stripped by the release workflow; tell
# portage's QA pass to skip them so the merge doesn't warn.
QA_PRESTRIPPED="usr/bin/corvus usr/bin/crv usr/bin/corvus-netd usr/bin/corvus-nodeagent"

# Extract the Python wheel into ${T}/wheel so we can copy the
# unpacked corvus_client / corvus_admin packages into each
# enabled Python impl's site-packages.
_corvus_unpack_wheel() {
	local wheel="${S}/python/${MY_PN}-${PV}-py3-none-any.whl"
	[[ -f "${wheel}" ]] || die "expected wheel not found: ${wheel}"
	mkdir -p "${T}/wheel" || die
	unzip -q -o "${wheel}" -d "${T}/wheel" || die "unzip ${wheel}"
}

_corvus_install_python_module() {
	python_domodule "${T}/wheel/corvus_client"
}

_corvus_install_admin_module() {
	python_domodule "${T}/wheel/corvus_admin"
}

# Entry-point shim that imports `corvus_admin.cli:main` — mirrors
# the wheel's [project.scripts] declaration. The source ebuild
# uses the same shape.
_corvus_install_admin_wrapper() {
	cat > "${T}/corvus-admin" <<-'EOF' || die
		#!/usr/bin/env python3
		import sys
		from corvus_admin.cli import main
		sys.exit(main())
	EOF
	python_newscript "${T}/corvus-admin" corvus-admin
}

src_install() {
	# Binaries — install only what the operator asked for.
	use daemon && dobin bin/corvus
	use cli && dobin bin/crv
	use netd && dobin bin/corvus-netd
	use node && dobin bin/corvus-nodeagent

	if use cli; then
		if use bash-completion; then
			newbashcomp completions/bash/crv crv
		fi
		if use zsh-completion; then
			insinto /usr/share/zsh/site-functions
			doins completions/zsh/_crv
		fi
		if use fish-completion; then
			insinto /usr/share/fish/vendor_completions.d
			doins completions/fish/crv.fish
		fi
	fi

	if use python || use admin; then
		_corvus_unpack_wheel
	fi
	if use python; then
		python_foreach_impl _corvus_install_python_module
	fi
	if use admin; then
		python_foreach_impl _corvus_install_admin_module
		python_foreach_impl _corvus_install_admin_wrapper
	fi

	dodoc README.md INSTALL.md VERSION
	dodoc -r doc

	# Apply YAML examples + Cap'n Proto schemas live under
	# /usr/share/corvus/ so operators can copy them without
	# hunting through /usr/share/doc/.
	insinto /usr/share/${MY_PN}
	doins -r yaml schema
}

pkg_postinst() {
	if use daemon; then
		elog "The corvus daemon needs a PostgreSQL database. Bootstrap one with:"
		elog "  createdb corvus"
		elog ""
	fi
	if use admin; then
		elog "For a turn-key single-node setup (CA + certs + systemd units +"
		elog "service bring-up + node registration), run:"
		elog "  corvus-admin quickstart"
		elog ""
	fi
	if use cli; then
		elog "Manage VMs with the crv CLI:"
		elog "  crv vm list"
		elog "  crv disk list"
		elog ""
	fi
	if use python; then
		elog "Python client module is installed; use it from Python with:"
		elog "  from corvus_client import Client"
		elog ""
	fi
	if use node || use netd; then
		elog "User namespaces must be enabled in the kernel (CONFIG_USER_NS=y)"
		elog "for unprivileged virtual networking."
	fi
	elog "YAML examples and Cap'n Proto schemas are at /usr/share/${MY_PN}/."
}
