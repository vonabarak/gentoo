# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# Tiny library: STM in a MonadIO-friendly wrapper. Pulled in as a
# transitive dep of the vendored haskell-capnp under
# app-emulation/corvus's `vendor/haskell-capnp/capnp/` — Stackage
# LTS-23.28 doesn't include it, so stack.yaml lists it as an
# extra-dep and the ::haskell overlay doesn't carry an ebuild.

CABAL_FEATURES="lib profile haddock hoogle hscolour"
inherit haskell-cabal

DESCRIPTION="STM in a MonadIO-friendly wrapper"
HOMEPAGE="https://hackage.haskell.org/package/monad-stm"

LICENSE="BSD"
SLOT="0/${PV}"
KEYWORDS="~amd64"

RDEPEND=">=dev-lang/ghc-9.0.2:="
DEPEND="${RDEPEND}
	>=dev-haskell/cabal-3.4.1.0
"
