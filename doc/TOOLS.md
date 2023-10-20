# Bootstrapped Tools

All tools are statically built with the GCC 13.2.0 with musl support
(`gcc-13.2.0-musl`). Note that dynamically linking with this compiler will not work on
non-musl systems. Therefore, all *configure checks* and *build steps* must use
static linking. For more information on the compilers, see
[COMPILERS.md](./COMPILERS.md).

## Busybox

Busybox is compiled statically by setting `LDFLAGS='-static'`. It strictly
requires GCC for building, which can be set via `HOSTCC` and `HOSTCXX`. It
employs *internal checks* to verify that the compilers are working. However,
those checks seem to ignore `LDFLAGS`, which causes them to fail on non-musl
systems. Therefore, we had to forcefully set the compilers to `"${CC} -static"`
and `"${CXX} -static"`.

For reproducibility, we additionally had to set `SOURCE_DATE_EPOCH=0`.

## Make

Make is compiled statically by setting `LDFLAGS='-static'`. For some reason, the
binary likes to record the absolute path to the C++ compiler on the build
machine (despite not even using C++). To achieve reproducibility, we set
`CXX='unused'`.

## CMake

CMake is compiled statically with bundled dependencies. The only dependency that
is not bundled with CMake's sources is `libssl`. We use the C++ library
`boringssl` to satisfy that dependency. However, CMake expects `libssl` to be a
C library (not C++), which is solved via a small patch. For reproducibility, we
had to redefine `__FILE__` to `__FILE_NAME__`, which is supported since GCC 12.

## Python

Python is compiled statically with default modules built in. See [Building
Python Statically](https://wiki.python.org/moin/BuildStatically) for full
details. Missing modules are:
- `nis`: deprecated module that caused the static build to fail
- `ssl`: unsupported, due to missing `libssl` C library

Furthermore, the Python binary likes to record its build time and date, so we
had to set `SOURCE_DATE_EPOCH=0` to achieve reproducibility.

