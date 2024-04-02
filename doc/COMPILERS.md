# Bootstrapped Compilers

The initial compilers are built with the GCC resulting from the final bootstrap
stage (`stage-1/gcc`). For more infomation on the bootstrap process, see
[BOOTSTRAP.md](./BOOTSTRAP.md).

## GCC Native

GCC and binutils are built separately using the GCC toolchain from the final
bootstrap stage (`stage-1/gcc`). While GCC generally supports reproducible
builds, this is not necessarily the case if the build directory and toolchain
root are located in variable paths. To achieve reproducibility, we had to apply
a few patches that ensure build directory independence. Unfortunately, even
though we install via the `install-strip` target, not all binaries will be
stripped (e.g., `libgcc` ignores `install-strip`). Therefore, we need to
manually strip all libraries and binaries after building.

## GCC Musl

GCC with Musl support is built using the GCC toolchain from the final bootstrap
stage (`stage-1/gcc`). For building, we use the project
[*musl-cross-make*](https://github.com/richfelker/musl-cross-make), which
conveniently also supports building a cross-compiler. To avoid any fetches by
*musl-cross-make*, we stage the unpacked file trees to their expected target
destination (e.g., `gcc-13.orig`, `musl-latest.orig`, etc.). For some reason
*musl-cross-make* tries to modify files in `musl-latest.orig`, so we have to
provide a writable copy. Finally, we applied a few patches to support newer
binutils and GCC versions.

Unfortunately, *musl-cross-make* does not call the `install-strip` target.
Therefore, we apply manual stripping to achieve reproducibility.

Additionally, the alternative allocator object
[`mimalloc.o`](https://github.com/microsoft/mimalloc) is also built and added to
GCC's lib folder. Linking it can solve Musl's slowdowns with allocator
contention in multithreaded applications.

## GCC Musl Static

Static building is achieved by using the GCC 13.2.0 Musl toolchain
(`gcc-13.2.0-musl`) and a "fake" `cc`/`c++` executable that adds the flag
`-static` to each compiler call.

## Clang Native

Building Clang requires an existing GCC installation with recent C++ standard
library features (`gcc-13.2.0-native`) and build tools (`busybox`, `make`,
`cmake`, `python`). GCC is used to build Clang in a first step, before this
newly built Clang is used to build any of the remaining targets. To ensure that
the Clang from the first step can be used during the entire build process, GCC's
runtime libraries (`libgcc`, `libstdc++`) must be locatable by setting
`LD_LIBRARY_PATH=${GCC_TOOLCHAIN}/lib64`. For building reproducibly, it is
required to set `LIBCXXABI_ENABLE_ASSERTIONS` and `LIBUNWIND_ENABLE_ASSERTIONS`
to `OFF`, as both are enabled by default and cause leaking absolute paths to
the build directory.

Futhermore, this newly built Clang needs to link GCC's runtime objects
(`crt*.o`) for compiling its runtime libraries (`libc++`, `libc++abi`, and
`libunwind`). Therefore, we additionally need to set
`LDFLAGS=-gcc-toolchain=${GCC_TOOLCHAIN}` *after* Clang was built (note that
setting this option earlier will fail, due to it being an unknown option to the
GCC that is used to build Clang in the very first step).

Finally, we also have to patch Clang's `libc++`, because it is using `strto*_l`
functions that are [deliberately missing in musl
libc](https://www.openwall.com/lists/musl/2020/10/01/3).
