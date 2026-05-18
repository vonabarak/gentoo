# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# Single-instance package: provides Default instances for
# Data.Vector. Pulled in as a transitive dep of the vendored
# haskell-capnp under app-emulation/corvus's `vendor/`. Not in
# Stackage LTS-23.28 and not in the ::haskell overlay; this ebuild
# fills the gap.
#
# Upstream pins `data-default-class ==0.0.*` (the 0.0.x line is
# what was on Hackage when this package was published in 2013). The
# haskell overlay only ships data-default-class-0.2.x, but the
# Default class API the instance file uses didn't change across the
# 0.0 → 0.2 line — just sed the upper bound and rely on cabal to
# resolve to whatever's available.

CABAL_FEATURES="lib profile haddock hoogle hscolour"
inherit haskell-cabal

DESCRIPTION="Default instances for Data.Vector"
HOMEPAGE="https://hackage.haskell.org/package/data-default-instances-vector"

LICENSE="BSD"
SLOT="0/${PV}"
KEYWORDS="~amd64"

RDEPEND=">=dev-haskell/data-default-class-0.0:=[profile?]
	>=dev-haskell/vector-0.10:=[profile?]
	>=dev-lang/ghc-9.0.2:=
"
DEPEND="${RDEPEND}
	>=dev-haskell/cabal-3.4.1.0
"

src_prepare() {
	# Widen data-default-class bound: `==0.0.*` → `>=0.0 && <1`.
	# The instance module uses only the unchanged Default class.
	sed -i \
		's/data-default-class \+==0\.0\.\*/data-default-class >=0.0 \&\& <1/' \
		"${S}/data-default-instances-vector.cabal" || die

	haskell-cabal_src_prepare
}
