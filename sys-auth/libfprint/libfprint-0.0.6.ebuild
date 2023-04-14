# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6

inherit rpm

DESCRIPTION=""
HOMEPAGE=""
SRC_URI="http://romolo.cmb.usc.edu/installs/SLES-11-SP3-SDK/CD2/suse/src/libfprint-0.0.6-18.20.1.src.rpm"

LICENSE=""
SLOT="0"
KEYWORDS="amd64"
IUSE=""

DEPEND=""
RDEPEND="${DEPEND}"

src_unpack () {
    rpm_src_unpack ${A}
    cd "${S}"
	rm ${WORKDIR}/libfprint-validity.patch
    EPATCH_SOURCE="${WORKDIR}" EPATCH_SUFFIX="patch" \
        EPATCH_FORCE="yes" epatch
    EPATCH_SOURCE="${FILESDIR}" EPATCH_SUFFIX="patch" \
        EPATCH_FORCE="yes" epatch
}

