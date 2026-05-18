# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# zenhack's personal Prelude reexport package. Pulled in as a
# transitive dep of the vendored `lifetimes` under
# app-emulation/corvus's `vendor/lifetimes/`.
#
# Upstream pins `base ^>=4.12` which excludes the base shipped with
# GHC 9.8 (base-4.19). The package itself is just a re-export module
# with no upper-bound-sensitive code, so we bump the bound to <5
# in src_prepare — matches what stack 3.7.1 does when this lands as
# an extra-dep against an LTS that's later than the package's pin.

CABAL_FEATURES="lib profile haddock hoogle hscolour"
inherit haskell-cabal

DESCRIPTION="zenhack's personal Prelude (re-exports)"
HOMEPAGE="https://hackage.haskell.org/package/zenhack-prelude"

LICENSE="MIT"
SLOT="0/${PV}"
KEYWORDS="~amd64"

RDEPEND=">=dev-lang/ghc-9.0.2:="
DEPEND="${RDEPEND}
	>=dev-haskell/cabal-3.4.1.0
"

src_prepare() {
	# Relax base upper bound so GHC 9.8 / base-4.19 satisfies it.
	# `^>=4.12` → `>=4.12 && <4.13` per Cabal's caret-operator spec;
	# the package's two-line Prelude has no API drift across base
	# majors so widening to <5 is safe.
	sed -i 's/base ^>=4\.12/base >=4.12 \&\& <5/' \
		"${S}/zenhack-prelude.cabal" || die

	haskell-cabal_src_prepare
}
