# Bootstrappable Toolchain

This repository provides compiler toolchains and additional build tools that are
acquired via [**Bootstrappable Builds**](https://bootstrappable.org/). *For
details about the bootstrap process, see [BOOTSTRAP.md](./doc/BOOTSTRAP.md).*

Available compiler toolchains are:

- `gcc-latest-native`
- `gcc-14.2.0-native`
- `gcc-13.3.0-native`
- `clang-latest-native`
- `clang-19.1.1-native`
- `clang-18.1.8-native`
- `clang-17.0.6-native`
- `clang-16.0.6-native`
- `gcc-latest-musl`
- `gcc-14.2.0-musl`
- `gcc-13.3.0-musl`
- `gcc-latest-musl-static`
- `gcc-14.2.0-musl-static`
- `gcc-13.3.0-musl-static`

*For details about how these compilers are built, see
[COMPILERS.md](./doc/COMPILERS.md).*

Available build tools are:

- `busybox-latest`
- `busybox-1.36.1`
- `make-latest`
- `make-4.4.1`
- `cmake-latest`
- `cmake-3.27.1`
- `python-latest`
- `python-3.12.0`
- `tools-all` (bundle of all latest tools)

*All tools are statically linked so that they can run on systems without any
existing C library. For details about how these tools are built, see
[TOOLS.md](./doc/TOOLS.md).*

Details about toolchain variants:

- `<compiler>-native`: *native* compiler
    - runs on the build host
    - **supports native compilation for the host architecture**
- `<compiler>-musl`: *cross* compiler with musl support
    - runs on the build host
    - **links against bundled *musl libc***  
      (*note that dynamically linked binaries require a working musl ld+libc on
      the target system*)
    - **supports fully static linking (unlike *glibc* toolchains)**
    - **supports cross-compilation for project's `TARGET_ARCH`**
- `<compiler>-musl-static`: statically linked *cross* compiler with musl support
    - runs on systems without any existing C library
    - **links against bundled *musl libc***  
      (*note that dynamically linked binaries require a working musl ld+libc on
      the target system*)
    - **supports fully static linking (unlike *glibc* toolchains)**
    - **supports cross-compilation for project's `TARGET_ARCH`**
- `<toolchain>+tools` (e.g., `gcc-latest-native+tools`)  
    - `<toolchain>` bundled with all latest tools (see `tools-all` above)

All `musl` variants support cross-compilation. In your project, make sure
that the variables `ARCH` and `TARGET_ARCH` are set to one of the following
values: `x86`, `x86_64`, `arm`, or `arm64`.

## Usage

All provided toolchains can be
1. imported to an existing
[Justbuild](https://github.com/just-buildsystem/justbuild) project, or
2. installed to local disk to obtain a portable toolchain.

### 1. Importing toolchains to Justbuild projects

If your project includes its toolchain via an open name (usually a repository
named `toolchain`), you can create that repository by importing any of the
provided toolchains (e.g., `gcc-latest-musl+tools`) with the tool
`just-import-git`:

~~~ sh
$ just-import-git -C repos.template.json --as toolchain -b master \
    https://github.com/just-buildsystem/bootstrappable-toolchain gcc-latest-musl+tools \
    > repos.json
~~~

### 2. Obtaining a portable toolchain

You can install a portable version of any provided toolchain (e.g.,
`gcc-latest-musl`) to your local disk with:

~~~ sh
$ just-mr --main gcc-latest-musl install toolchain -D'{"ARCH":"x86_64"}' -o /opt/gcc
~~~

*Note that the configuration variable `ARCH` should be set to the build host
architecture.*

For installing a *cross compiler*, you can additionally set `BUILD_ARCH` to
specify the architecture the compiler should build for:

~~~ sh
$ just-mr --main gcc-latest-musl install toolchain \
    -D'{"ARCH":"x86_64","BUILD_ARCH":"arm64"}' -o /opt/gcc-for-arm64
~~~

For installing a *crossed native compiler*, you have to also set the variable
`TARGET_ARCH` (the architecture the compiler is build for) to the same value as
`BUILD_ARCH`:

~~~ sh
$ just-mr --main gcc-latest-musl install toolchain \
    -D'{"ARCH":"x86_64","TARGET_ARCH":"arm64","BUILD_ARCH":"arm64"}' -o /opt/arm64-gcc-for-arm64
~~~

## Initial requirements

For bootstrapping the toolchains, the build host must be a Linux system with:

1. C compiler (e.g., TinyCC, old GCC)
2. POSIX-compliant shell located at `/bin/sh`

The C compiler for bootstrapping can be specified by setting the fields
`BOOTSTRAP_CC`, `BOOTSTRAP_CFLAGS`, and `BOOTSTRAP_PATH` in configuration
variable `TOOLCHAIN_CONFIG` (e.g., on command line `-D'{"TOOLCHAIN_CONFIG":
{"BOOTSTRAP_CC": "gcc"}}'`). If not set, the C compiler is assumed to be `cc`
available in the search paths `/bin` or `/usr/bin`.

*Note that currently supported build hosts are required to be an `x86_64`
architecture and use either the GNU or musl C library.*

## Toolchain Targets

All toolchains provide the following target:
- `["", "toolchain"]`:
  The portable toolchain file tree (e.g., `bin`, `lib`, etc.)  
  Set `BUILD_ARCH` to specify the target architecture for cross-compilers.

All compiler toolchains additionally provide:
- `["CC", "defaults"]`:
  The `CC` toolchain definition for use with
  [rules-cc](https://github.com/just-buildsystem/rules-cc)

All tool toolchains (including `<toolchain>+tools`) provide:
- `["CC/foreign", "defaults"]`:
  The `CC/foreign` toolchain definition for use with
  [rules-cc](https://github.com/just-buildsystem/rules-cc)

The `busybox` toolchains (including `<toolchain>+tools`) additionally provide:
- `["patch", "defaults"]`:
  The `patch` toolchain definition for use with
  [rules-cc](https://github.com/just-buildsystem/rules-cc)

## Configuration Variables

The toolchains can be configured via the variable `TOOLCHAIN_CONFIG`, which
contains an object that may specify multiple fields.

Fields for building the toolchains:

- `BOOTSTRAP_CC`:
  The initial C compiler for bootstrapping (default: `"cc"`)
- `BOOTSTRAP_CFLAGS`:
  The initial C compile flags for bootstrapping (default: `["-w"]`)
- `BOOTSTRAP_PATH`:
  Search path for the initial C compiler (default: `["/bin", "/usr/bin"]`)
- `HOST_SYSTEM_HDR_DIR`:
  Header directory of the C library on the build host (default: not set)
- `HOST_SYSTEM_LIB_DIR`:
  Library directory of the C library on the build host (default: not set)
- `HOST_DYNAMIC_LINKER`:
  Absolute path to the dynamic linker on the build host (default: not set)
- `BOOTSTRAP_WRAP_CC`:
  If true, when using the bootstrap C compiler with autotools, use a wrapper
  script calling the compiler with the `BOOTSTRAP_CFLAGS` instead. In this way,
  it can be avoided that the autotools draw wrong conclusions from calling the
  compiler without the specified flags (as some tests do).
- `INCLUDE_LINTER`:
  Add linter to toolchain if supported. (default: `false`)  
  Currently this option is only supported by `clang` toolchains, adding
  `clang-tidy`. Additionally, Clang versions `18` and `19` will also include
  the *external project*
  [Include What You Use](https://github.com/include-what-you-use/include-what-you-use).

Fields for using the toolchains
(within [Justbuild](https://github.com/just-buildsystem/justbuild) projects):

- `STATIC_RUNLIBS`:
  Statically link runtime libraries, e.g., `libgcc_s`, `libstdc++` (default:
  `false`)
- `USE_LIBCXX`:
  Use LLVM's `libc++` instead of GNU's `libstdc++` (only for `clang` toolchains,
  default: `false`)

### Building on Hosts with Custom System Paths

Some systems (e.g., NixOS) use custom paths for Coreutils, the C library, and
the dynamic linker that the autotools cannot determine. On such systems, `PATH`
is used to locate Coreutils and `TOOLCHAIN_CONFIG` may set additional system
paths.

Example configuration for bootstrapping on NixOS (hashes may vary):

~~~ json
{ "ENV": {"PATH": "/root/.nix-profile/bin"}
, "TOOLCHAIN_CONFIG":
  { "HOST_SYSTEM_HDR_DIR": "/nix/store/y8wfrgk7br5rfz4221lfb9v8w3n0cnyd-glibc-2.37-8-dev/include"
  , "HOST_SYSTEM_LIB_DIR": "/nix/store/ld03l52xq2ssn4x0g5asypsxqls40497-glibc-2.37-8/lib"
  , "HOST_DYNAMIC_LINKER": "/nix/store/ld03l52xq2ssn4x0g5asypsxqls40497-glibc-2.37-8/lib/ld-linux-x86-64.so.2"
  }
}
~~~

## Musl Performance Issues

Musl has huge allocator contention issues with multithreading. For that reason,
all our `musl` compilers are shipped with the alternative allocator
[mimalloc](https://github.com/microsoft/mimalloc) that solves these issues. If
you notice any performance slowdowns with your Musl-linked binaries, consider
using the alternative allocator by appending `-l:mimalloc.o` to your `LDFLAGS`.

## License

All files are copyright Huawei Cloud Computing Technology Co., Ltd., license
Apache-2.0, except for the patches in `etc/patches`, which are license GPL-2.0
(the same license as the respective upstream project).
