# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# Single ebuild for the live tree, source releases, and prebuilt
# releases. Two switches drive the variants:
#
#   * ${PV} == 9999  — live ebuild: pull main from GitHub via git-r3.
#     The live ebuild never offers the `binary` flag (it is absent
#     from IUSE below), so it always builds from source.
#
#   * binary USE flag (versioned only) — when enabled, drop the four
#     stripped Haskell binaries + the Python wheel straight from the
#     `-linux-amd64` release tarball; no Haskell toolchain required.
#     When disabled, compile from the source release tarball exactly
#     like the live ebuild.
#
# `inherit` runs at metadata time, before USE is known, so
# haskell-cabal is always inherited for non-live versions even in
# binary mode (it is harmless: the GHC-oriented phases pkg_setup /
# src_configure / src_compile / pkg_postrm short-circuit on
# `use binary`, and the fresh RDEPEND/DEPEND assignments below
# clobber the eclass's auto-injected dev-lang/ghc dependency).
#
# The Cap'n Proto Haskell binding (`capnp`) and `lifetimes` are
# vendored under `vendor/haskell-capnp/capnp/` and `vendor/lifetimes/`.
# Upstream `zenhack/haskell-capnp` is unmaintained since 2023-06; the
# in-tree copies carry GHC 9.8 / LTS-23.28 compatibility patches. We
# build them before corvus into a private package DB
# (${T}/vendor-pkg-db) and point corvus's configure at that DB via
# CABAL_EXTRA_CONFIGURE_FLAGS.

PYTHON_COMPAT=( python3_{10..14} )

# "lib" only (no "profile"): the haskell-cabal eclass injects an
# *unconditional* `dev-lang/ghc:=` into RDEPEND when the profile
# feature is set, and that injection survives the ebuild's own
# RDEPEND assignment — which would drag the GHC toolchain into the
# prebuilt (binary) install, defeating the point of it. We instead
# add dev-lang/ghc to the source-only RDEPEND by hand below. Profiling
# was effectively unusable anyway: the vendored capnp / lifetimes are
# built without profiling libs.
CABAL_FEATURES="lib"
if [[ ${PV} == 9999 ]]; then
	inherit bash-completion-r1 haskell-cabal git-r3 python-r1
else
	inherit bash-completion-r1 haskell-cabal python-r1
fi

DESCRIPTION="QEMU/KVM virtual machine management daemon with CLI client"
HOMEPAGE="https://github.com/vonabarak/corvus"
LICENSE="BSD"
SLOT="0"

# Component USE flags select which executables to install:
#   daemon — corvus (VM management daemon)
#   node   — corvus-nodeagent (per-host privileged agent)
#   netd   — corvus-netd (per-host network agent)
#   cli    — crv (command-line client)
#   admin  — corvus-admin (Python certificate / deploy CLI; needs python)
#   web    — corvus-web (FastAPI/uvicorn HTTP+WS gateway, ships the
#            React SPA; needs python). In a source build the SPA is
#            built with npm; in a binary build it comes prebuilt in
#            the wheel.
#
# At least one of these must be enabled. Shell completions and the
# Python client library follow their own flags below.
_CORVUS_COMPONENTS="+admin bash-completion +cli +daemon fish-completion +netd +node +python vde +web zsh-completion"

REQUIRED_USE="
	|| ( admin cli daemon netd node web )
	admin? ( python )
	web? ( python )
	python? ( ${PYTHON_REQUIRED_USE} )
"

# Runtime dependencies shared by the source and binary variants. The
# Haskell library closure (HASKELL_DEPEND) is appended per-variant
# below; only source builds need it.
COMMON_RDEPEND="
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
	web? (
		$(python_gen_cond_dep '
			>=dev-python/fastapi-0.115[${PYTHON_USEDEP}]
			>=dev-python/uvicorn-0.30[${PYTHON_USEDEP}]
			>=dev-python/prometheus-client-0.20[${PYTHON_USEDEP}]
			dev-python/websockets[${PYTHON_USEDEP}]
		')
	)
"

HASKELL_DEPEND="
	>=dev-haskell/aeson-2.2:=
	>=dev-haskell/aeson-qq-0.8:=
	>=dev-haskell/ansi-terminal-1.0:=
	>=dev-haskell/asn1-types-0.3:=
	>=dev-haskell/async-2.2:=
	>=dev-haskell/base64-bytestring-1.2:=
	>=dev-haskell/bifunctors-5.6:=
	>=dev-haskell/bytes-0.17:=
	>=dev-haskell/crypton-x509-1.7:=
	>=dev-haskell/crypton-x509-store-1.6:=
	>=dev-haskell/crypton-x509-validation-1.6:=
	>=dev-haskell/data-default-0.7:=
	>=dev-haskell/data-default-instances-vector-0.0.1:=
	>=dev-haskell/exceptions-0.10:=
	>=dev-haskell/focus-1.0:=
	>=dev-haskell/gitrev-1.3:=
	>=dev-haskell/haskell-src-meta-0.8:=
	>=dev-haskell/list-t-1.0:=
	>=dev-haskell/monad-logger-0.3:=
	>=dev-haskell/monad-stm-0.1:=
	>=dev-haskell/mtl-2.3:=
	>=dev-haskell/network-3.2:=
	>=dev-haskell/network-simple-0.4:=
	>=dev-haskell/optparse-applicative-0.18:=
	>=dev-haskell/persistent-2.14:=
	>=dev-haskell/persistent-postgresql-2.13:=
	>=dev-haskell/pretty-show-1.10:=
	>=dev-haskell/primitive-0.8:=
	>=dev-haskell/random-1.2:=
	>=dev-haskell/resource-pool-0.4:=
	>=dev-haskell/safe-exceptions-0.1.7:=
	>=dev-haskell/stm-2.5:=
	>=dev-haskell/stm-containers-1.2:=
	>=dev-haskell/supervisors-0.2:=
	>=dev-haskell/temporary-1.3:=
	>=dev-haskell/text-2.0:=
	>=dev-haskell/tls-2.1:=
	>=dev-haskell/vector-0.13:=
	>=dev-haskell/wl-pprint-text-1.2:=
	>=dev-haskell/yaml-0.11:=
	>=dev-haskell/zenhack-prelude-0.1.1:=
"

if [[ ${PV} == 9999 ]]; then
	EGIT_REPO_URI="https://github.com/vonabarak/corvus.git"
	PROPERTIES="live"
	IUSE="${_CORVUS_COMPONENTS}"

	# The web frontend is built with `npm ci && npm run build`, which
	# fetches packages from the npm registry — the Portage network
	# sandbox would block that. Live-ebuild semantics already require
	# network for git-r3, so this is consistent.
	RESTRICT="web? ( network-sandbox )"

	RDEPEND="
		!!app-emulation/corvus-bin
		${COMMON_RDEPEND}
		${HASKELL_DEPEND}
		dev-lang/ghc:=
	"
	DEPEND="
		${RDEPEND}
		>=dev-lang/ghc-9.4
		>=dev-haskell/cabal-3.8
	"
	# Node.js + npm is only needed at build time to bundle the SPA into
	# python/corvus_web/static/. Runtime serving is pure Python (uvicorn).
	BDEPEND="web? ( net-libs/nodejs[npm] )"
else
	SRC_URI="
		!binary? ( https://github.com/vonabarak/${PN}/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz )
		binary? ( https://github.com/vonabarak/${PN}/releases/download/v${PV}/${PN}-${PV}-linux-amd64.tar.gz -> ${P}-linux-amd64.tar.gz )
	"
	KEYWORDS="~amd64"
	IUSE="+binary ${_CORVUS_COMPONENTS}"

	# Only the source web build needs the network (npm registry); the
	# binary variant ships the SPA prebuilt inside the wheel.
	RESTRICT="!binary? ( web? ( network-sandbox ) )"

	# The release binaries are pre-stripped by the upstream workflow;
	# tell portage's QA pass to skip them so the merge doesn't warn.
	QA_PRESTRIPPED="usr/bin/corvus usr/bin/crv usr/bin/corvus-netd usr/bin/corvus-nodeagent"

	RDEPEND="
		!!app-emulation/corvus-bin
		${COMMON_RDEPEND}
		!binary? (
			${HASKELL_DEPEND}
			dev-lang/ghc:=
		)
	"
	DEPEND="
		${COMMON_RDEPEND}
		!binary? (
			${HASKELL_DEPEND}
			>=dev-lang/ghc-9.4
			>=dev-haskell/cabal-3.8
		)
	"
	BDEPEND="
		!binary? ( web? ( net-libs/nodejs[npm] ) )
		binary? ( app-arch/unzip )
	"
fi

CORVUS_VENDOR_DB="${T}/vendor-pkg-db"

# True when this build installs the prebuilt release rather than
# compiling from source. Always false for the live ebuild (no `binary`
# flag in IUSE), so `use binary` is only evaluated where it is valid.
_corvus_is_binary() {
	in_iuse binary && use binary
}

# Build + register a vendored Haskell package into ${CORVUS_VENDOR_DB}.
# Args: $1 = absolute path to the package directory.
_corvus_build_vendored() {
	local pkg_dir="$1"
	local pkg_name="${pkg_dir##*/}"
	einfo "Building vendored Haskell package: ${pkg_name}"

	# Stock Setup.hs for build-type: Simple. The vendored packages
	# don't ship one.
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

	# install copies files directly to --prefix (no destdir indirection
	# so the registered .conf paths match the on-disk layout) AND
	# registers into the last --package-db specified at configure time
	# (our private vendor DB).
	runhaskell Setup.hs install \
		|| die "install ${pkg_name}"

	popd > /dev/null
}

# Extract the Python wheel from the binary release tarball into
# ${T}/wheel so the unpacked corvus_* packages can be copied into each
# enabled Python impl's site-packages.
_corvus_unpack_wheel() {
	local wheel="${S}/python/${PN}-${PV}-py3-none-any.whl"
	[[ -f ${wheel} ]] || die "expected wheel not found: ${wheel}"
	mkdir -p "${T}/wheel" || die
	unzip -q -o "${wheel}" -d "${T}/wheel" || die "unzip ${wheel}"
}

_corvus_install_python_module() {
	if _corvus_is_binary; then
		python_domodule "${T}/wheel/corvus_client"
	else
		# python/corvus_client/schema is a directory symlink to
		# ../../schema so the source client and the wheel both see the
		# canonical .capnp files. python_domodule preserves symlinks
		# (it's doins underneath), which would leave a dangling
		# .../corvus_client/schema in the install — at import time
		# corvus_client/_schema.py errors out with "schema directory not
		# found". Stage a dereferenced copy (cp -rL) and install from
		# that so the schema files ship as a real directory.
		local stage="${T}/python-stage-${EPYTHON}"
		rm -rf "${stage}" || die
		mkdir -p "${stage}" || die
		cp -rL "${S}/python/corvus_client" "${stage}/corvus_client" || die
		python_domodule "${stage}/corvus_client"
	fi
}

_corvus_install_admin_module() {
	if _corvus_is_binary; then
		python_domodule "${T}/wheel/corvus_admin"
	else
		python_domodule "${S}/python/corvus_admin"
	fi
}

_corvus_install_admin_wrapper() {
	cat > "${T}/corvus-admin" <<-'EOF' || die
		#!/usr/bin/env python3
		import sys
		from corvus_admin.cli import main
		sys.exit(main())
	EOF
	python_newscript "${T}/corvus-admin" corvus-admin
}

_corvus_install_web_module() {
	# Ships the SPA bundle alongside the Python sources because
	# corvus_web.config locates static assets via
	# Path(__file__).parent / "static". A source build populated
	# static/ via `emake web-build`; the wheel embeds it as package
	# data.
	if _corvus_is_binary; then
		python_domodule "${T}/wheel/corvus_web"
	else
		python_domodule "${S}/python/corvus_web"
	fi
}

_corvus_install_web_wrapper() {
	cat > "${T}/corvus-web" <<-'EOF' || die
		#!/usr/bin/env python3
		import sys
		from corvus_web.cli import main
		sys.exit(main())
	EOF
	python_newscript "${T}/corvus-web" corvus-web
}

pkg_setup() {
	# haskell-cabal's pkg_setup configures the GHC environment; a
	# prebuilt install has no toolchain, so skip it entirely.
	_corvus_is_binary && return
	haskell-cabal_pkg_setup
}

src_unpack() {
	if [[ ${PV} == 9999 ]]; then
		git-r3_src_unpack
	elif use binary; then
		default
		# The binary tarball's top-level dir is ${PN}-${PV}-linux-amd64;
		# rename it to ${P} so the default ${S} (=${WORKDIR}/${P}) and
		# every later phase resolve without a per-variant S override.
		mv "${WORKDIR}/${PN}-${PV}-linux-amd64" "${S}" || die
	else
		default
	fi
}

src_prepare() {
	if _corvus_is_binary; then
		default
		return
	fi

	# Widen the vendored capnp's data-default bound: capnp.cabal pins
	# `^>= 0.7.1` (= >=0.7.1 && <0.8) but the haskell overlay ships
	# data-default-0.8.0.2 — the API surface the code uses is unchanged
	# across the 0.7 -> 0.8 split.
	sed -i -E \
		's/data-default[[:space:]]+\^>=[[:space:]]*0\.7\.1/data-default >=0.7.1 \&\& <1/' \
		"${S}/vendor/haskell-capnp/capnp/capnp.cabal" || die

	haskell-cabal_src_prepare
}

src_configure() {
	_corvus_is_binary && return

	# Build the vendored Haskell packages into a private DB. Order
	# matters: capnp depends on lifetimes.
	ghc-pkg init "${CORVUS_VENDOR_DB}" || die "init vendor pkg-db"
	_corvus_build_vendored "${S}/vendor/lifetimes"
	_corvus_build_vendored "${S}/vendor/haskell-capnp/capnp"

	# Point corvus's configure at the private DB so cabal-install
	# resolves capnp + lifetimes against the vendored builds.
	#
	# --disable-executable-dynamic: statically link the vendored Haskell
	# libs into the corvus / crv binaries. Without it GHC bakes the
	# build-time ${T}/vendor-prefix/lib/... rpath into the binaries;
	# that path is gone after the merge so /usr/bin/crv would die at
	# runtime with "cannot open shared object file" for libHScapnp.so.
	CABAL_EXTRA_CONFIGURE_FLAGS+=" --package-db=${CORVUS_VENDOR_DB}"
	CABAL_EXTRA_CONFIGURE_FLAGS+=" --disable-executable-dynamic"

	haskell-cabal_src_configure
}

src_compile() {
	_corvus_is_binary && return

	haskell-cabal_src_compile

	if use web; then
		# `make web-build` runs `npm ci` (or `npm install` if the
		# lockfile is stale) followed by `npm run build`, then copies
		# frontend/dist/ into python/corvus_web/static/ — which is where
		# corvus_web.config locates the SPA bundle.
		emake web-build NPM=npm
	fi
}

# Source variant: install the freshly compiled binaries + generated
# shell completions.
_corvus_install_source() {
	haskell-cabal_src_install

	# The Haskell build always produces all four binaries (they share
	# the same library closure). Drop the ones the user didn't ask for
	# so the install set tracks the enabled USE flags.
	use daemon || rm -f "${ED}/usr/bin/corvus" || die
	use node || rm -f "${ED}/usr/bin/corvus-nodeagent" || die
	use netd || rm -f "${ED}/usr/bin/corvus-netd" || die
	use cli || rm -f "${ED}/usr/bin/crv" || die

	if use cli; then
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
	fi

	if use admin; then
		# Generate completion scripts off the source tree. Output is
		# pure shell so it does not depend on which Python impl we pick;
		# python_setup grabs any one of the enabled ones.
		if use bash-completion || use zsh-completion || use fish-completion; then
			python_setup
			if use bash-completion; then
				PYTHONPATH="${S}/python" "${EPYTHON}" -m corvus_admin completion bash \
					> "${T}/corvus-admin.bash" || die "Failed to generate bash completion"
				newbashcomp "${T}/corvus-admin.bash" corvus-admin
			fi

			if use zsh-completion; then
				PYTHONPATH="${S}/python" "${EPYTHON}" -m corvus_admin completion zsh \
					> "${T}/_corvus-admin" || die "Failed to generate zsh completion"
				insinto /usr/share/zsh/site-functions
				doins "${T}/_corvus-admin"
			fi

			if use fish-completion; then
				PYTHONPATH="${S}/python" "${EPYTHON}" -m corvus_admin completion fish \
					> "${T}/corvus-admin.fish" || die "Failed to generate fish completion"
				insinto /usr/share/fish/vendor_completions.d
				doins "${T}/corvus-admin.fish"
			fi
		fi
	fi
}

# Binary variant: install the prebuilt binaries + the shell completions
# shipped in the release tarball.
_corvus_install_binary() {
	use daemon && dobin bin/corvus
	use cli && dobin bin/crv
	use netd && dobin bin/corvus-netd
	use node && dobin bin/corvus-nodeagent

	if use cli; then
		use bash-completion && newbashcomp completions/bash/crv crv
		if use zsh-completion; then
			insinto /usr/share/zsh/site-functions
			doins completions/zsh/_crv
		fi
		if use fish-completion; then
			insinto /usr/share/fish/vendor_completions.d
			doins completions/fish/crv.fish
		fi
	fi

	if use admin; then
		use bash-completion && newbashcomp completions/bash/corvus-admin corvus-admin
		if use zsh-completion; then
			insinto /usr/share/zsh/site-functions
			doins completions/zsh/_corvus-admin
		fi
		if use fish-completion; then
			insinto /usr/share/fish/vendor_completions.d
			doins completions/fish/corvus-admin.fish
		fi
	fi
}

src_install() {
	if _corvus_is_binary; then
		_corvus_install_binary
	else
		_corvus_install_source
	fi

	# Python modules + entry-point shims for the enabled components.
	# Source builds install from the tree (corvus_client via a
	# dereferenced staging copy); binary builds install from the
	# unpacked wheel.
	if use python || use admin || use web; then
		_corvus_is_binary && _corvus_unpack_wheel
		use python && python_foreach_impl _corvus_install_python_module
		if use web; then
			python_foreach_impl _corvus_install_web_module
			python_foreach_impl _corvus_install_web_wrapper
		fi
		if use admin; then
			python_foreach_impl _corvus_install_admin_module
			python_foreach_impl _corvus_install_admin_wrapper
		fi
	fi

	dodoc README.md
	dodoc -r doc
	# The binary tarball also ships an install pointer + version stamp.
	_corvus_is_binary && dodoc INSTALL.md VERSION

	# YAML examples + Cap'n Proto schemas under /usr/share/corvus/ so
	# operators can copy them without hunting through /usr/share/doc/.
	# Identical layout regardless of source vs binary.
	insinto /usr/share/${PN}
	doins -r yaml schema
}

pkg_postrm() {
	# haskell-cabal's pkg_postrm recaches the GHC package DB; only
	# meaningful when we registered Haskell libraries (source build).
	_corvus_is_binary && return
	haskell-cabal_pkg_postrm
}

pkg_postinst() {
	if use daemon; then
		elog "Corvus daemon requires a PostgreSQL database."
		elog "Create one with: createdb corvus"
		elog ""
		elog "Start the daemon:"
		elog "  corvus --database postgresql://localhost/corvus"
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
	if use web; then
		elog "corvus-web serves a browser UI plus a REST + WebSocket bridge"
		elog "in front of the corvus daemon (defaults to http://127.0.0.1:8080):"
		elog "  corvus-web"
		elog ""
	fi
	if use admin; then
		elog "corvus-admin manages mTLS certificates for daemon, node, and netd."
		elog "For a turn-key single-node setup (CA + certs + systemd units +"
		elog "service bring-up + node registration), run:"
		elog "  corvus-admin quickstart"
		elog ""
		elog "Or initialise the CA only:"
		elog "  corvus-admin init"
		elog ""
	fi
	if use node || use netd; then
		elog "User namespaces must be enabled in the kernel (CONFIG_USER_NS=y)"
		elog "for unprivileged virtual networking."
	fi
}
