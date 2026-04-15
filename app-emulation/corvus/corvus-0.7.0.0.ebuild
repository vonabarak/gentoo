# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit bash-completion-r1

DESCRIPTION="QEMU/KVM virtual machine management daemon with CLI client"
HOMEPAGE="https://github.com/vonabarak/corvus"
SRC_URI="https://github.com/vonabarak/${PN}/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="amd64"
IUSE="bash-completion fish-completion systemd vde zsh-completion"

# Stack downloads the LTS snapshot index and all Hackage dependencies at
# build time (the Haskell overlay does not yet package every Haskell
# library corvus depends on), so network access is required during
# src_compile. Both settings disable Portage's network sandbox:
#   - RESTRICT="network-sandbox" is the canonical way to allow network.
#   - PROPERTIES="live" is an additional hint for older portage versions.
RESTRICT="network-sandbox"
PROPERTIES="live"

# Stack installs its own GHC (LTS-23.28 resolver pins GHC 9.8.4) into
# ${STACK_ROOT}/programs. This avoids package-database conflicts between
# Gentoo's system GHC and Stack's snapshot unit IDs that break packages
# with internal sub-libraries (notably attoparsec).
BDEPEND="
	>=dev-haskell/stack-3.0.0
	virtual/pkgconfig
	dev-vcs/git
	sys-libs/ncurses
	net-misc/curl
"

RDEPEND="
	!!app-emulation/corvus-bin
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

DEPEND="${RDEPEND}
	dev-db/postgresql
"

QA_PRESTRIPPED="usr/bin/corvus usr/bin/crv"

# Stack downloads ~1 GB of Hackage dependencies on every build. The cache
# lives under ${T}/stack-root and is discarded after the build completes.

# Stack and Cabal write to ${HOME}/.cabal, ${HOME}/.ghc, ${HOME}/.local/bin,
# and various XDG paths. Portage's default HOME during src_compile points
# at a sandbox-restricted location; redirect everything into ${T} so the
# sandbox allows writes.
_stack_env() {
	export STACK_ROOT="${T}/stack-root"
	export HOME="${T}/home"
	export XDG_CACHE_HOME="${HOME}/.cache"
	export XDG_CONFIG_HOME="${HOME}/.config"
	export XDG_DATA_HOME="${HOME}/.local/share"
	export TMPDIR="${T}"
}

# dev-haskell/stack installs /usr/bin/stack; dev-haskell/stack-bin installs
# /usr/bin/stack-bin (and only symlinks it to /usr/bin/stack when its
# "symlink" USE flag is enabled). Pick whichever is available.
_stack_cmd() {
	if type -P stack >/dev/null 2>&1; then
		echo stack
	elif type -P stack-bin >/dev/null 2>&1; then
		echo stack-bin
	else
		die "Neither 'stack' nor 'stack-bin' found in PATH"
	fi
}

src_prepare() {
	default
	_stack_env
	mkdir -p "${STACK_ROOT}" "${HOME}" "${XDG_CACHE_HOME}" \
		"${XDG_CONFIG_HOME}" "${XDG_DATA_HOME}" || die
}

src_compile() {
	_stack_env
	# --system-ghc uses the Gentoo-installed GHC instead of downloading one.
	# --no-install-ghc prevents stack from trying to fetch GHC.
	# --no-system-ghc + --install-ghc: Stack manages its own GHC inside
	# ${STACK_ROOT}/programs. This is slower on the first build (~300 MB
	# GHC download) but gives Cabal a pristine package database that
	# matches what the stackage resolver expects.
	# --allow-different-user is needed because Portage runs src_compile as
	# "portage" but src_install as root, and Stack protects its root dir
	# against cross-user access unless this flag is set.
	$(_stack_cmd) build \
		--no-system-ghc \
		--install-ghc \
		--allow-different-user \
		|| die "stack build failed"
}

src_install() {
	_stack_env
	# Copy the built binaries from stack's local install root.
	local bindir
	bindir=$($(_stack_cmd) path --no-system-ghc --allow-different-user --local-install-root)/bin
	[[ -x "${bindir}/corvus" ]] || die "corvus binary not found in ${bindir}"
	[[ -x "${bindir}/crv" ]] || die "crv binary not found in ${bindir}"

	newbin "${bindir}/corvus" corvus
	newbin "${bindir}/crv" crv

	if use systemd; then
		sed -i 's|%h/.local/bin/corvus|/usr/bin/corvus|' corvus.service || die
		insinto /usr/lib/systemd/user
		doins corvus.service
	fi

	if use bash-completion; then
		"${bindir}/crv" --bash-completion-script /usr/bin/crv > crv.bash \
			|| die "Failed to generate bash completion"
		newbashcomp crv.bash crv
	fi

	if use zsh-completion; then
		"${bindir}/crv" --zsh-completion-script /usr/bin/crv > _crv \
			|| die "Failed to generate zsh completion"
		insinto /usr/share/zsh/site-functions
		doins _crv
	fi

	if use fish-completion; then
		"${bindir}/crv" --fish-completion-script /usr/bin/crv > crv.fish \
			|| die "Failed to generate fish completion"
		insinto /usr/share/fish/vendor_completions.d
		doins crv.fish
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
