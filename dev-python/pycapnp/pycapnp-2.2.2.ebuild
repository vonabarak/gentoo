# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# pycapnp ships a custom PEP517 backend (_custom_build/backend.py)
# whose sole purpose is to translate `pip --config-settings` flags
# like `force-system-libcapnp=true` into setuptools `build_ext`
# argv. We don't need that translation: setup.py's auto-detect path
# (no flag set) probes `capnp` on PATH and uses its sibling
# include/lib dirs — which is exactly what dev-libs/capnproto
# provides. Repoint pyproject.toml at setuptools.build_meta in
# src_prepare so DISTUTILS_USE_PEP517=setuptools is honoured.

PYTHON_COMPAT=( python3_{10..14} )
DISTUTILS_USE_PEP517=setuptools

inherit distutils-r1

DESCRIPTION="Python wrapper for the Cap'n Proto C++ library"
HOMEPAGE="
	https://github.com/capnproto/pycapnp
	https://pypi.org/project/pycapnp/
"
SRC_URI="https://github.com/capnproto/${PN}/archive/refs/tags/v${PV}.tar.gz -> ${P}.gh.tar.gz"

LICENSE="BSD-2"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="dev-libs/capnproto"

DEPEND="${RDEPEND}"

BDEPEND="
	>=dev-python/cython-3.0[${PYTHON_USEDEP}]
	dev-python/pkgconfig[${PYTHON_USEDEP}]
"

distutils_enable_tests pytest

src_prepare() {
	# Replace the custom config-settings-translating backend with
	# vanilla setuptools.build_meta. The custom backend only forwards
	# `force-{system,bundled}-libcapnp` config_settings to setup.py;
	# we rely on setup.py's no-flag default (probe `capnp` on PATH)
	# instead, so the wrapper is dead code in this build.
	sed -i \
		-e 's|^build-backend = .*|build-backend = "setuptools.build_meta"|' \
		-e '/^backend-path = /d' \
		pyproject.toml || die

	distutils-r1_src_prepare
}
