# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# Structured-concurrency supervisor tree, used by the vendored
# haskell-capnp under app-emulation/corvus's `vendor/`. Not in
# Stackage LTS-23.28; stack.yaml lists it as an extra-dep.

CABAL_FEATURES="lib profile haddock hoogle hscolour"
inherit haskell-cabal

DESCRIPTION="Structured concurrency supervisor trees"
HOMEPAGE="https://hackage.haskell.org/package/supervisors"

LICENSE="MIT"
SLOT="0/${PV}"
KEYWORDS="~amd64"

RDEPEND=">=dev-haskell/async-2.2.1:=[profile?]
	>=dev-haskell/safe-exceptions-0.1.7:=[profile?]
	>=dev-lang/ghc-9.0.2:=
"
DEPEND="${RDEPEND}
	>=dev-haskell/cabal-3.4.1.0
"
