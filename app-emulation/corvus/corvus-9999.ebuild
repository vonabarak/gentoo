# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# Live ebuild: pulls the latest main branch from GitHub at every emerge.
# Set EGIT_OVERRIDE_BRANCH_VONABARAK_CORVUS / EGIT_COMMIT_VONABARAK_CORVUS
# to pin to a specific branch or commit.
#
# The Cap'n Proto Haskell binding (`capnp`) and `lifetimes` are vendored
# under `vendor/haskell-capnp/capnp/` and `vendor/lifetimes/`. Upstream
# `zenhack/haskell-capnp` is unmaintained since 2023-06; the in-tree
# copies carry GHC 9.8 / LTS-23.28 compatibility patches. We build them
# before corvus into a private package DB (${T}/vendor-pkg-db) and point
# corvus's configure at that DB via CABAL_EXTRA_CONFIGURE_FLAGS.

PYTHON_COMPAT=( python3_{10..14} )

CABAL_FEATURES="lib profile"
inherit bash-completion-r1 haskell-cabal git-r3 python-r1

DESCRIPTION="QEMU/KVM virtual machine management daemon with CLI client"
HOMEPAGE="https://github.com/vonabarak/corvus"
EGIT_REPO_URI="https://github.com/vonabarak/corvus.git"

LICENSE="BSD"
SLOT="0"
KEYWORDS=""

# Component USE flags select which executables to install:
#   daemon — corvus (VM management daemon)
#   node   — corvus-nodeagent (per-host privileged agent)
#   netd   — corvus-netd (per-host network agent)
#   cli    — crv (command-line client)
#   admin  — corvus-admin (Python certificate / deploy CLI; needs python)
#   web    — corvus-web (FastAPI/uvicorn HTTP+WS gateway, ships the
#            React SPA built with npm; needs python)
#
# At least one of these must be enabled. Shell completions and the
# Python client library follow their own flags below.
IUSE="+admin bash-completion +cli +daemon fish-completion +netd +node +python vde +web zsh-completion"
PROPERTIES="live"

# The web frontend is built with `npm ci && npm run build`, which
# fetches packages from the npm registry — the Portage network
# sandbox would block that. Live-ebuild semantics already require
# network for git-r3, so this is consistent.
RESTRICT="web? ( network-sandbox )"

REQUIRED_USE="
	|| ( admin cli daemon netd node web )
	admin? ( python )
	web? ( python )
	python? ( ${PYTHON_REQUIRED_USE} )
"

# Runtime dependencies per component. The Haskell binaries share a
# common Haskell library closure (HASKELL_DEPEND, applied at the
# bottom); only the external system-level deps are component-gated.
RDEPEND="
	!!app-emulation/corvus-bin
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
	>=dev-haskell/aeson-2.2:=[profile?]
	>=dev-haskell/aeson-qq-0.8:=[profile?]
	>=dev-haskell/ansi-terminal-1.0:=[profile?]
	>=dev-haskell/asn1-types-0.3:=[profile?]
	>=dev-haskell/async-2.2:=[profile?]
	>=dev-haskell/base64-bytestring-1.2:=[profile?]
	>=dev-haskell/bifunctors-5.6:=[profile?]
	>=dev-haskell/bytes-0.17:=[profile?]
	>=dev-haskell/crypton-x509-1.7:=[profile?]
	>=dev-haskell/crypton-x509-store-1.6:=[profile?]
	>=dev-haskell/crypton-x509-validation-1.6:=[profile?]
	>=dev-haskell/data-default-0.7:=[profile?]
	>=dev-haskell/data-default-instances-vector-0.0.1:=[profile?]
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
	>=dev-haskell/tls-2.1:=[profile?]
	>=dev-haskell/vector-0.13:=[profile?]
	>=dev-haskell/wl-pprint-text-1.2:=[profile?]
	>=dev-haskell/yaml-0.11:=[profile?]
	>=dev-haskell/zenhack-prelude-0.1.1:=[profile?]
"

DEPEND="${RDEPEND}
	${HASKELL_DEPEND}
	>=dev-lang/ghc-9.4
	>=dev-haskell/cabal-3.8
	daemon? ( dev-db/postgresql )
"

# Node.js + npm is only needed at build time to bundle the SPA into
# python/corvus_web/static/. Runtime serving is pure Python (uvicorn).
BDEPEND="web? ( net-libs/nodejs[npm] )"

RDEPEND+=" ${HASKELL_DEPEND}"

CORVUS_VENDOR_DB="${T}/vendor-pkg-db"

_corvus_build_vendored() {
	local pkg_dir="$1"
	local pkg_name="${pkg_dir##*/}"
	einfo "Building vendored Haskell package: ${pkg_name}"

	cat > "${pkg_dir}/Setup.hs" <<-EOF || die
		import Distribution.Simple
		main = defaultMain
	EOF

	pushd "${pkg_dir}" > /dev/null || die "pushd ${pkg_dir}"

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

	runhaskell Setup.hs install \
		|| die "install ${pkg_name}"

	popd > /dev/null
}

src_unpack() {
	git-r3_src_unpack
}

src_prepare() {
	sed -i -E \
		's/data-default[[:space:]]+\^>=[[:space:]]*0\.7\.1/data-default >=0.7.1 \&\& <1/' \
		"${S}/vendor/haskell-capnp/capnp/capnp.cabal" || die

	haskell-cabal_src_prepare
}

src_configure() {
	ghc-pkg init "${CORVUS_VENDOR_DB}" || die "init vendor pkg-db"
	_corvus_build_vendored "${S}/vendor/lifetimes"
	_corvus_build_vendored "${S}/vendor/haskell-capnp/capnp"

	# --disable-executable-dynamic: statically link the vendored
	# Haskell libs into the corvus / crv binaries. Without it GHC
	# bakes ${T}/vendor-prefix/lib/... into the binary's rpath
	# and /usr/bin/crv fails at runtime once that build dir is
	# gone.
	CABAL_EXTRA_CONFIGURE_FLAGS+=" --package-db=${CORVUS_VENDOR_DB}"
	CABAL_EXTRA_CONFIGURE_FLAGS+=" --disable-executable-dynamic"

	haskell-cabal_src_configure
}

src_compile() {
	haskell-cabal_src_compile

	if use web; then
		# `make web-build` runs `npm ci` (or `npm install` if the
		# lockfile is stale) followed by `npm run build`, then
		# copies frontend/dist/ into python/corvus_web/static/ —
		# which is where corvus_web.config locates the SPA bundle.
		emake web-build NPM=npm
	fi
}

_corvus_install_python_module() {
	# python/corvus_client/schema is a directory symlink to ../../schema
	# so the live Python client and the wheel both see the canonical
	# .capnp files. python_domodule preserves symlinks (it's doins
	# underneath), which would leave a dangling
	# /usr/lib/pythonX.Y/site-packages/corvus_client/schema in the
	# install — at import time corvus_client/_schema.py errors out
	# with "schema directory not found". Stage a dereferenced copy
	# (cp -rL) and install from that so the schema files ship as a
	# real directory.
	local stage="${T}/python-stage-${EPYTHON}"
	rm -rf "${stage}" || die
	mkdir -p "${stage}" || die
	cp -rL "${S}/python/corvus_client" "${stage}/corvus_client" || die
	python_domodule "${stage}/corvus_client"
}

_corvus_install_admin_module() {
	python_domodule "${S}/python/corvus_admin"
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
	# Path(__file__).parent / "static".
	python_domodule "${S}/python/corvus_web"
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

src_install() {
	haskell-cabal_src_install

	# The Haskell build always produces all four binaries (they share
	# the same library closure). Drop the ones the user didn't ask
	# for so the install set tracks the enabled USE flags.
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

	if use python; then
		python_foreach_impl _corvus_install_python_module
	fi

	if use web; then
		python_foreach_impl _corvus_install_web_module
		python_foreach_impl _corvus_install_web_wrapper
	fi

	if use admin; then
		python_foreach_impl _corvus_install_admin_module
		python_foreach_impl _corvus_install_admin_wrapper

		# Generate completion scripts off the source tree. Output is
		# pure shell so it does not depend on which Python impl we
		# pick; python_setup grabs any one of the enabled ones.
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

	dodoc README.md
	dodoc -r doc
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
