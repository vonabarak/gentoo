# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# Live ebuild: pulls the latest main branch from GitHub at every emerge.
# Set EGIT_OVERRIDE_BRANCH_VONABARAK_CORVUS / EGIT_COMMIT_VONABARAK_CORVUS
# to pin to a specific branch or commit.

CABAL_FEATURES="lib profile"
inherit bash-completion-r1 haskell-cabal git-r3

DESCRIPTION="QEMU/KVM virtual machine management daemon with CLI client"
HOMEPAGE="https://github.com/vonabarak/corvus"
EGIT_REPO_URI="https://github.com/vonabarak/corvus.git"

LICENSE="BSD"
SLOT="0"
KEYWORDS=""
IUSE="bash-completion fish-completion systemd vde zsh-completion"
PROPERTIES="live"

# Runtime dependencies: external tools the daemon invokes at runtime.
# !!app-emulation/corvus-bin blocks the binary package (same files).
RDEPEND="
	!!app-emulation/corvus-bin
	app-emulation/qemu[spice,usb,usbredir,virtfs,passt,vde?]
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

# Haskell library dependencies, same as the stable ebuild.
HASKELL_DEPEND="
	>=dev-haskell/aeson-2.2:=[profile?]
	>=dev-haskell/aeson-qq-0.8:=[profile?]
	>=dev-haskell/async-2.2:=[profile?]
	>=dev-haskell/base64-bytestring-1.2:=[profile?]
	>=dev-haskell/esqueleto-3.5:=[profile?]
	>=dev-haskell/exceptions-0.10:=[profile?]
	>=dev-haskell/gitrev-1.3:=[profile?]
	>=dev-haskell/haskell-src-meta-0.8:=[profile?]
	>=dev-haskell/monad-logger-0.3:=[profile?]
	>=dev-haskell/mtl-2.3:=[profile?]
	>=dev-haskell/network-3.2:=[profile?]
	>=dev-haskell/network-simple-0.4:=[profile?]
	>=dev-haskell/optparse-applicative-0.18:=[profile?]
	>=dev-haskell/persistent-2.14:=[profile?]
	>=dev-haskell/persistent-postgresql-2.13:=[profile?]
	>=dev-haskell/random-1.2:=[profile?]
	>=dev-haskell/resource-pool-0.4:=[profile?]
	>=dev-haskell/stm-2.5:=[profile?]
	>=dev-haskell/temporary-1.3:=[profile?]
	>=dev-haskell/text-2.0:=[profile?]
	>=dev-haskell/unliftio-core-0.2:=[profile?]
	>=dev-haskell/vector-0.13:=[profile?]
	>=dev-haskell/yaml-0.11:=[profile?]
"

DEPEND="${RDEPEND}
	${HASKELL_DEPEND}
	>=dev-lang/ghc-9.4
	>=dev-haskell/cabal-3.8
	dev-db/postgresql
"

RDEPEND+=" ${HASKELL_DEPEND}"

src_unpack() {
	git-r3_src_unpack
}

src_prepare() {
	# Strip fourmolu from build-depends in the cabal file; it is listed in
	# package.yaml but never imported anywhere (only used as a CLI formatter
	# tool via `make format`), and dev-haskell/fourmolu is masked in the
	# haskell overlay.
	sed -i '/^\s*,\s*fourmolu\s*$/d' "${S}/corvus.cabal" || die
	haskell-cabal_src_prepare
}

src_install() {
	haskell-cabal_src_install

	# corvus.service from the source tree (referenced by the systemd USE flag).
	if use systemd; then
		sed -i 's|%h/.local/bin/corvus|/usr/bin/corvus|' "${S}/corvus.service" || die
		insinto /usr/lib/systemd/user
		doins "${S}/corvus.service"
	fi

	# Shell completions: crv emits them itself at runtime.
	if use bash-completion; then
		"${ED}/usr/bin/crv" --bash-completion-script /usr/bin/crv \
			> "${T}/crv.bash" || die "Failed to generate bash completion"
		newbashcomp "${T}/crv.bash" crv
	fi

	if use zsh-completion; then
		"${ED}/usr/bin/crv" --zsh-completion-script /usr/bin/crv \
			> "${T}/_crv" || die "Failed to generate zsh completion"
		insinto /usr/share/zsh/site-functions
		doins "${T}/_crv"
	fi

	if use fish-completion; then
		"${ED}/usr/bin/crv" --fish-completion-script /usr/bin/crv \
			> "${T}/crv.fish" || die "Failed to generate fish completion"
		insinto /usr/share/fish/vendor_completions.d
		doins "${T}/crv.fish"
	fi

	dodoc README.md
	dodoc -r doc
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
