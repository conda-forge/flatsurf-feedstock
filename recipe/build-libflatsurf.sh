#!/usr/bin/env bash
set -ex

# Regenerate configure since our patches touch configure.ac
autoreconf -ivf

if [[ "$target_platform" == osx* ]]; then
    CXXFLAGS="$CXXFLAGS -fno-common"
    CXXFLAGS="$CXXFLAGS -std=c++17"
    # Use old symbol names for enable_if to pick up symbol names in exact-real correctly.
    # See https://github.com/flatsurf/sage-flatsurf/pull/345#issuecomment-2846128058
    CXXFLAGS="$CXXFLAGS -fclang-abi-compat=17"
    # macOS does not support std::uncaught_exceptions() before 10.12
    CXXFLAGS="$CXXFLAGS -DCATCH_CONFIG_NO_CPP17_UNCAUGHT_EXCEPTIONS"
    # re-enable mem_fun_ref in macOS when building with C++17 (used by dependency PPL.)
    CXXFLAGS="$CXXFLAGS -D_LIBCPP_ENABLE_CXX17_REMOVED_BINDERS"
    # Work around missing symbols in old SDK, https://conda-forge.org/docs/maintainer/knowledge_base.html#newer-c-features-with-old-sdk
    CXXFLAGS="${CXXFLAGS} -D_LIBCPP_DISABLE_AVAILABILITY"
fi

if [[ "$target_platform" == win* ]]; then
    cp $PREFIX/lib/gmp.lib $PREFIX/lib/gmpxx.lib
    CXXFLAGS="$CXXFLAGS -std=c++17"
fi

cd libflatsurf

# Get an updated config.sub and config.guess
cp $BUILD_PREFIX/share/gnuconfig/config.* .

./configure --prefix="$PREFIX" --without-benchmark --without-eantic --without-exactreal --without-byexample --without-version-script || (cat config.log; false)
[[ "$target_platform" == "win-64" ]] && patch_libtool

make -j${CPU_COUNT}
make install

if [[ "$target_platform" == win* ]]; then
    rm $PREFIX/lib/gmpxx.lib
fi
