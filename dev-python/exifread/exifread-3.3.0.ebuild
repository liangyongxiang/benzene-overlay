# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
#PYPI_NO_NORMALIZE=1
#PYPI_PN="ExifRead"
PYTHON_COMPAT=( python3_{{10..13},13t} )

inherit distutils-r1 #pypi

DESCRIPTION="Library to extract Exif information from digital camera image files"
HOMEPAGE="https://github.com/ianare/exif-py"
SRC_URI="https://github.com/ianare/exif-py/archive/refs/tags/${PV}.tar.gz -> ${P}.gh.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~x86"

S="${WORKDIR}/exif-py-${PV}"

distutils_enable_tests pytest

python_install() {
	rm -r "${BUILD_DIR}"/install/$(python_get_sitedir)/tests || die
	distutils-r1_python_install
}
