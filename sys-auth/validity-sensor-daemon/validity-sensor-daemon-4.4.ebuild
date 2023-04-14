# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6

inherit rpm

DESCRIPTION=""
HOMEPAGE=""
SRC_URI="Validity-Sensor-Setup-4.4-100.00.x86_64.rpm"

LICENSE=""
SLOT="0"
KEYWORDS="amd64"
IUSE=""

DEPEND="dev-libs/openssl"
RDEPEND="${DEPEND}"

src_unpack () {
	rpm_src_unpack ${A}
	mkdir -p "${S}"
	mv ${WORKDIR}/usr ${S}
	mv ${WORKDIR}/etc ${S}
	rm ${S}/etc/init.d/vcsFPServiceDaemon
	cp ${FILESDIR}/validity-sensor ${S}/etc/init.d/
}

src_configure() {
	true;
}

src_compile() {
	true;
}

src_install() {
	cp -vR ${S}/* ${D}/
}

