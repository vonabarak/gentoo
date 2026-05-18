# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# Corvus is a Stack project, but hpack generates a standard corvus.cabal
# file that is checked into the source tarball. The haskell-cabal eclass
# builds the package with cabal-install like any other Haskell package:
# dependencies come from the ::haskell overlay, the network sandbox stays
# on, and profiling/haddock/etc. work as usual.
#
# The Cap'n Proto Haskell binding (`capnp`) and `lifetimes` are vendored
# under `vendor/haskell-capnp/capnp/` and `vendor/lifetimes/`. Upstream
# `zenhack/haskell-capnp` is unmaintained since 2023-06; the in-tree
# copies carry GHC 9.8 / LTS-23.28 compatibility patches. We build them
# before corvus into a private package DB (${T}/vendor-pkg-db) and point
# corvus's configure at that DB via CABAL_EXTRA_CONFIGURE_FLAGS.
#
# Optional Python client (USE=python) installs the pure-Python
# `corvus_client` package (speaks Cap'n Proto RPC via pycapnp) into
# every enabled Python impl's site-packages.

PYTHON_COMPAT=( python3_{10..14} )

CABAL_FEATURES="lib profile"
inherit bash-completion-r1 haskell-cabal python-r1

DESCRIPTION="QEMU/KVM virtual machine management daemon with CLI client"
HOMEPAGE="https://github.com/vonabarak/corvus"
SRC_URI="https://github.com/vonabarak/${PN}/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64"
IUSE="bash-completion fish-completion python systemd vde zsh-completion"

REQUIRED_USE="python? ( ${PYTHON_REQUIRED_USE} )"

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
	python? (
		${PYTHON_DEPS}
		$(python_gen_cond_dep '
			>=dev-python/pycapnp-2.2[${PYTHON_USEDEP}]
			dev-python/pyyaml[${PYTHON_USEDEP}]
		')
	)
	|| ( sys-firmware/edk2-bin sys-firmware/edk2 )
"

# Haskell library dependencies. Versions reflect what is available in
# the ::haskell overlay; upper bounds are relaxed so cabal picks
# whatever is installed. binary, bytestring, containers, directory,
# filepath, process, template-haskell, time, and unix are GHC boot
# libraries provided by dev-lang/ghc -- no separate packages needed.
#
# `ansi-terminal`, `supervisors`, and `data-default` were added when
# the wire protocol moved to Cap'n Proto post-0.9. The Cap'n Proto
# Haskell binding (`capnp`) and `lifetimes` are vendored — do NOT
# add `dev-haskell/capnp` or `dev-haskell/lifetimes` here.
#
# Transitive deps of the vendored packages (bifunctors, bytes,
# data-default-instances-vector, focus, list-t, monad-stm,
# pretty-show, primitive, safe-exceptions, stm-containers,
# wl-pprint-text, zenhack-prelude) need to be visible to the
# vendored builds; some of those (data-default-instances-vector,
# monad-stm, supervisors, zenhack-prelude) live in the ::vonabarak
# overlay because LTS-23.28 doesn't carry them.
HASKELL_DEPEND="
	>=dev-haskell/aeson-2.2:=[profile?]
	>=dev-haskell/aeson-qq-0.8:=[profile?]
	>=dev-haskell/ansi-terminal-1.0:=[profile?]
	>=dev-haskell/async-2.2:=[profile?]
	>=dev-haskell/base64-bytestring-1.2:=[profile?]
	>=dev-haskell/bifunctors-5.6:=[profile?]
	>=dev-haskell/bytes-0.17:=[profile?]
	>=dev-haskell/data-default-0.7:=[profile?]
	>=dev-haskell/data-default-instances-vector-0.0.1:=[profile?]
	>=dev-haskell/esqueleto-3.5:=[profile?]
	>=dev-haskell/exceptions-0.10:=[profile?]
	>=dev-haskell/focus-1.0:=[profile?]
	>=dev-haskell/gitrev-1.3:=[profile?]
	>=dev-haskell/haskell-src-meta-0.8:=[profile?]
	>=dev-haskell/list-t-1.0:=[profile?]
	>=dev-haskell/monad-logger-0.3:=[profile?]
	>=dev-haskell/monad-stm-0.1:=[profile?]
	>=dev-haskell/mtl-2.3:=[profile?]
	>=dev-haskell/network-3.2:=[profile?]
	>=dev-haskell/network-simple-0.4:=[profile?]
	>=dev-haskell/optparse-applicative-0.18:=[profile?]
	>=dev-haskell/persistent-2.14:=[profile?]
	>=dev-haskell/persistent-postgresql-2.13:=[profile?]
	>=dev-haskell/pretty-show-1.10:=[profile?]
	>=dev-haskell/primitive-0.8:=[profile?]
	>=dev-haskell/random-1.2:=[profile?]
	>=dev-haskell/resource-pool-0.4:=[profile?]
	>=dev-haskell/safe-exceptions-0.1.7:=[profile?]
	>=dev-haskell/stm-2.5:=[profile?]
	>=dev-haskell/stm-containers-1.2:=[profile?]
	>=dev-haskell/supervisors-0.2:=[profile?]
	>=dev-haskell/temporary-1.3:=[profile?]
	>=dev-haskell/text-2.0:=[profile?]
	>=dev-haskell/unliftio-core-0.2:=[profile?]
	>=dev-haskell/vector-0.13:=[profile?]
	>=dev-haskell/wl-pprint-text-1.2:=[profile?]
	>=dev-haskell/yaml-0.11:=[profile?]
	>=dev-haskell/zenhack-prelude-0.1.1:=[profile?]
"

DEPEND="${RDEPEND}
	${HASKELL_DEPEND}
	>=dev-lang/ghc-9.4
	>=dev-haskell/cabal-3.8
	dev-db/postgresql
"

RDEPEND+=" ${HASKELL_DEPEND}"

# Path to the private package DB that holds the vendored Haskell
# packages. Populated in src_configure, referenced via
# CABAL_EXTRA_CONFIGURE_FLAGS so corvus's own Setup.hs configure can
# resolve `capnp` and `lifetimes`.
CORVUS_VENDOR_DB="${T}/vendor-pkg-db"

# Build + register a vendored Haskell package into ${CORVUS_VENDOR_DB}.
# Args: $1 = absolute path to the package directory.
_corvus_build_vendored() {
	local pkg_dir="$1"
	local pkg_name="${pkg_dir##*/}"
	einfo "Building vendored Haskell package: ${pkg_name}"

	# Stock Setup.hs for build-type: Simple. Cabal Setup.hs files
	# aren't checked into the source tree for these packages.
	cat > "${pkg_dir}/Setup.hs" <<-EOF || die
		import Distribution.Simple
		main = defaultMain
	EOF

	pushd "${pkg_dir}" > /dev/null || die "pushd ${pkg_dir}"

	# --package-db=clear + global keeps the configure honest;
	# --package-db=${CORVUS_VENDOR_DB} lets the second iteration
	# (capnp) find the first (lifetimes).
	runhaskell Setup.hs configure \
		--package-db=clear \
		--package-db=global \
		--package-db="${CORVUS_VENDOR_DB}" \
		--prefix="${T}/vendor-prefix" \
		--libdir="${T}/vendor-prefix/lib" \
		--libsubdir='$compiler/$pkgid' \
		--datadir="${T}/vendor-prefix/share" \
		--datasubdir='$pkgid' \
		--disable-tests \
		--disable-benchmarks \
		|| die "configure ${pkg_name}"

	runhaskell Setup.hs build \
		|| die "build ${pkg_name}"

	# install copies files directly to --prefix (no destdir
	# indirection so the registered .conf paths match the
	# on-disk layout) AND registers into the last --package-db
	# specified at configure time (our private vendor DB).
	runhaskell Setup.hs install \
		|| die "install ${pkg_name}"

	popd > /dev/null
}

src_prepare() {
	# Strip fourmolu from build-depends in the cabal file: it's
	# listed in package.yaml but never imported anywhere (only used
	# as a CLI formatter tool via `make format`), and
	# dev-haskell/fourmolu is masked in the haskell overlay.
	sed -i '/^\s*,\s*fourmolu\s*$/d' "${S}/corvus.cabal" || die

	# Widen the vendored capnp's data-default bound: capnp.cabal
	# pins `^>= 0.7.1` (= >=0.7.1 && <0.8) but the haskell overlay
	# ships data-default-0.8.0.2 — the API surface the code uses
	# is unchanged across the 0.7 → 0.8 split.
	sed -i -E \
		's/data-default[[:space:]]+\^>=[[:space:]]*0\.7\.1/data-default >=0.7.1 \&\& <1/' \
		"${S}/vendor/haskell-capnp/capnp/capnp.cabal" || die

	haskell-cabal_src_prepare
}

src_configure() {
	# Build the vendored Haskell packages into a private DB.
	# Order matters: capnp depends on lifetimes.
	# Note: `ghc-pkg init` takes the DB path as a positional arg.
	ghc-pkg init "${CORVUS_VENDOR_DB}" || die "init vendor pkg-db"
	_corvus_build_vendored "${S}/vendor/lifetimes"
	_corvus_build_vendored "${S}/vendor/haskell-capnp/capnp"

	# Point corvus's configure at the private DB so cabal-install
	# resolves capnp + lifetimes against the vendored builds.
	#
	# --disable-executable-dynamic: statically link the vendored
	# Haskell libs into the corvus / crv binaries. Without this
	# GHC's default dynamic-link path bakes the build-time
	# ${T}/vendor-prefix/lib/... rpath into the binaries; that
	# path is gone after the merge so /usr/bin/crv would die at
	# runtime with "cannot open shared object file" for
	# libHScapnp.so. Static linking removes the .so dependency.
	CABAL_EXTRA_CONFIGURE_FLAGS+=" --package-db=${CORVUS_VENDOR_DB}"
	CABAL_EXTRA_CONFIGURE_FLAGS+=" --disable-executable-dynamic"

	haskell-cabal_src_configure
}

_corvus_install_python_module() {
	python_domodule "${S}/python/corvus_client"
}

src_install() {
	haskell-cabal_src_install

	if use systemd; then
		sed -i 's|%h/.local/bin/corvus|/usr/bin/corvus|' "${S}/corvus.service" || die
		insinto /usr/lib/systemd/user
		doins "${S}/corvus.service"
	fi

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
