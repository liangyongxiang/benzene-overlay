# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_EXT=1
DISTUTILS_OPTIONAL=1
DISTUTILS_SINGLE_IMPL=1
DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{10..12} )

inherit distutils-r1 cmake multilib

DESCRIPTION="C++ tiny version of mamba, the fast conda package installer"
HOMEPAGE="https://github.com/mamba-org/mamba"
SRC_URI="https://github.com/mamba-org/mamba/archive/refs/tags/${P}.tar.gz"

LICENSE="BSD"
SLOT="0/2"
KEYWORDS="~amd64"	# cli11, libsolv no arm64; libsolv no x86
IUSE="python"
PROPERTIES="test_network"
RESTRICT="test"
REQUIRED_USE="python? ( ${PYTHON_REQUIRED_USE} )"

DEPEND="app-arch/libarchive:=
	app-arch/zstd:=
	dev-cpp/cli11
	dev-cpp/nlohmann_json
	dev-cpp/reproc:=
	dev-cpp/tl-expected
	dev-cpp/yaml-cpp:=
	dev-libs/libfmt:=
	dev-libs/spdlog
	net-misc/curl
	sys-libs/libsolv:=
	python? ( ${PYTHON_DEPS} )
"
RDEPEND="${DEPEND}
	!dev-util/mamba
	!dev-util/micromamba-bin
"
BDEPEND="python? (
		${PYTHON_DEPS}
		${DISTUTILS_DEPS}
		$(python_gen_cond_dep 'dev-python/pybind11[${PYTHON_USEDEP}]')
	)
	test? (
		app-shells/dash
		app-shells/tcsh
		app-shells/zsh
		$(python_gen_cond_dep '
			dev-python/pytest-lazy-fixture[${PYTHON_USEDEP}]
			dev-python/pytest-xprocess[${PYTHON_USEDEP}]
		')
	)
"

S="${WORKDIR}/mamba-${P}"

distutils_enable_tests pytest

EPYTEST_IGNORE=(
	# No module named 'conda_package_handling'
	# Depends on dev-python/zstandard[${PYTHON_USEDEP}]
	micromamba/tests/test_package.py
)

src_prepare() {
	cmake_src_prepare
	use python && { sed -i \
		"s|\${CMAKE_CURRENT_SOURCE_DIR}|\${CMAKE_INSTALL_PREFIX}\/$(python_get_sitedir | sed -e 's|/usr/||')|" \
		libmambapy/CMakeLists.txt || die ; pushd libmambapy || die ; distutils-r1_src_prepare ;
	}
}

src_configure() {
	cat > "${T}"/zstdConfig.cmake <<-EOF || die
		add_library(zstd::libzstd_shared SHARED IMPORTED)
		set_target_properties(zstd::libzstd_shared PROPERTIES
			IMPORTED_LOCATION "${EPREFIX}/usr/$(get_libdir)/libzstd$(get_libname)")
	EOF
	local mycmakeargs=(
		-DCMAKE_BUILD_TYPE=Release
		-DCMAKE_INSTALL_PREFIX="${EPREFIX}/usr"
		-DCMAKE_POSITION_INDEPENDENT_CODE=ON
		-DBUILD_LIBMAMBA=ON
		-DBUILD_LIBMAMBAPY=$(usex python)
		-DBUILD_LIBMAMBA_TESTS=NO
		-DBUILD_MAMBA_PACKAGE=OFF
		-DBUILD_MICROMAMBA=ON
		-DBUILD_SHARED=ON
		-DBUILD_STATIC=OFF
		-Dzstd_DIR="${T}"
	)
	cmake_src_configure
}

src_compile() {
	cmake_src_compile
	use python && { pushd libmambapy || die ; distutils-r1_src_compile ; }
}

src_install() {
	cmake_src_install
	use python && { pushd libmambapy || die ; distutils-r1_src_install ; }
}

src_test() {
	mkdir -p "${T}"/{.mamba,.conda} || die
	MAMBA_ROOT_PREFIX="${T}/.mamba" CONDA_PREFIX="${T}/.conda" \
	TEST_MAMBA_EXE="${BUILD_DIR}"/${PN}/${PN} epytest micromamba/tests
}
