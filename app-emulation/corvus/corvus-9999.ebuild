# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# Live ebuild: pulls the latest main branch from GitHub at every emerge.
# Set EGIT_OVERRIDE_BRANCH_VONABARAK_CORVUS / EGIT_COMMIT_VONABARAK_CORVUS
# to pin to a specific branch or commit.
#
# Optional Python client (USE=python) builds an abi3 native extension
# from the same tree. Because cbits/python_ext.c compiles against
# Py_LIMITED_API = 0x030A0000, one .so works on every Python 3.10+ —
# so we only need one Python impl's headers at build time even though
# the resulting module is installed into every enabled target's
# site-packages.

PYTHON_COMPAT=( python3_{11..14} )

CABAL_FEATURES="lib profile"
inherit bash-completion-r1 haskell-cabal git-r3 python-r1

DESCRIPTION="QEMU/KVM virtual machine management daemon with CLI client"
HOMEPAGE="https://github.com/vonabarak/corvus"
EGIT_REPO_URI="https://github.com/vonabarak/corvus.git"

LICENSE="BSD"
SLOT="0"
KEYWORDS=""
IUSE="bash-completion fish-completion python systemd vde zsh-completion"
PROPERTIES="live"

REQUIRED_USE="python? ( ${PYTHON_REQUIRED_USE} )"

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
	python? ( ${PYTHON_DEPS} )
	|| ( sys-firmware/edk2-bin sys-firmware/edk2 )
"

# Haskell library dependencies, same as the stable ebuild.
#
# ginger and file-embed are only pulled in when USE=python enables the
# cabal flag 'python-client'; without that flag the foreign-library and
# the gen-python-client executable are not built, and these libs are
# unreferenced.
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
	python? (
		>=dev-haskell/file-embed-0.0.15:=[profile?]
		>=dev-haskell/ginger-0.10:=[profile?]
	)
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

	if use python; then
		# The foreign-library stanza hardcodes /usr/include/python3.13 and
		# pkgconfig-depends: python-3.13 because upstream builds against a
		# pinned dev venv. Rewrite both to the Python impl python-r1
		# selects via python_setup — because Py_LIMITED_API = 0x030A0000
		# is set, the resulting .so is ABI-compatible with every Python
		# 3.10+ regardless of which impl's headers we compile against.
		python_setup
		local py_ver=${EPYTHON#python}  # python3.12 -> 3.12

		sed -i \
			-e "s|/usr/include/python3\.13|$(python_get_includedir)|g" \
			-e "s|python-3\.13|python-${py_ver}|g" \
			"${S}/corvus.cabal" || die "failed to rewrite Python include path"
	fi

	haskell-cabal_src_prepare
}

src_configure() {
	# Toggle the cabal flag that gates the Python FFI components so that
	# ginger and file-embed aren't pulled in when USE=python is off.
	CABAL_EXTRA_CONFIGURE_FLAGS+=" $(cabal_flag python python-client)"
	haskell-cabal_src_configure
}

src_compile() {
	haskell-cabal_src_compile

	if use python; then
		# Locate the foreign library produced by cabal's Setup.hs build.
		# The exact path depends on the Cabal version in use; search
		# under the standard build trees.
		local solib
		solib=$(find dist dist-newstyle -type f -name 'libcorvus-python.so*' \
			-not -name '*.prof' 2>/dev/null | head -n 1)
		[[ -n "${solib}" ]] || die "libcorvus-python.so not found after build"

		# Install as the abi3 extension the corvus_client package imports.
		cp "${solib}" "${S}/python/corvus_client/_corvus.abi3.so" \
			|| die "copy of foreign library into python package failed"

		# Regenerate _generated.py (which is .gitignored upstream) so
		# the live checkout install picks up the current Request/Response
		# surface.
		local genbin
		genbin=$(find dist dist-newstyle -type f -executable \
			-name 'gen-python-client' 2>/dev/null | head -n 1)
		[[ -n "${genbin}" ]] || die "gen-python-client executable not found"
		"${genbin}" > "${S}/python/corvus_client/_generated.py" \
			|| die "codegen of _generated.py failed"
	fi
}

_corvus_install_python_module() {
	python_domodule "${S}/python/corvus_client"
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

	if use python; then
		python_foreach_impl _corvus_install_python_module
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
	if use python; then
		elog "Python client module is installed; use it from Python with:"
		elog "  from corvus_client import Client"
		elog ""
	fi
	elog "User namespaces must be enabled in the kernel (CONFIG_USER_NS=y)"
	elog "for unprivileged virtual networking."
}
