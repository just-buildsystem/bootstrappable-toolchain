# Bootstrap Process

The bootstrap process cannot rely on anything existing on the build systems,
except:

1. Coreutils
2. POSIX-compliant shell located at `/bin/sh`
3. C89 compiler (e.g., TinyCC, old GCC) with a working C library (*glibc* /
   *musl libc*)

Consequently, the process is designed to bootstrap a "minimal distribution" that
contains everything required for building modern toolchains. The process is
currently separated into two stages.

## Stage 0

### 1. Bootstrapped Busybox "essentials"

Bootstrapping a minimal set of tools that are needed for this stage includes:

- `sed`/`awk`/`diff` (for building `make`/`binutils`/`gcc-4.7.4`/`busybox`)
- `patch` (for patching `gcc-4.7.4`)
- `cmp`/`tar` (for running `gcc-4.7.4`'s install target)
- `find`/`bzip2` (for building full `busybox`)

All tools are bootstrapped by selectively compiling the required C files. Note
that Busybox' `ar` is not included, due to its missing indexing support.

### 2. Bootstrapped GNU Make

Bootstrapping the `make` build system requires the Busybox "essentials" from the
previous step. It is compiled via its bootstrap script `build.sh`. However, due
to missing `ar`, final linking is done via custom compile commands.

### 3. Bootstrapped Archiver (from Binutils)

Bootstrapping the archiver `ar`, requires the Busybox "essentials" and `make`
from the previous steps. This archiver has proper indexing support and is
compiled via its `Makefile`. However, due to missing `ar` from earlier stages,
final linking is done via custom compile commands.

### 4. Binutils

Building binutils requires the Busybox "essentials", `make`, and `ar` from the
previous steps. This *full collection* of binutils includes `ar`, `as`, `ld`,
`ranlib`, `strip`, and more.

### 5. GCC 4.7.4

Building GCC requires the Busybox "essentials", `make`, and binutils from the
previous steps. GCC version 4.7.4 is [the last GCC version that can be built
without a C++ compiler](https://lists.nongnu.org/archive/html/tinycc-devel/2017-05/msg00099.html).

Patches needed for building on modern systems:

- support [new type name `ucontext_t`](https://github.com/gcc-mirror/gcc/commit/883312dc79806f513275b72502231c751c14ff72)
- support [building with newer C standard](https://gcc.gnu.org/legacy-ml/gcc-patches/2015-08/msg00375.html)

Patches needed for building on systems with *musl libc*:
[back-ports from GCC 4.8.0, 6.1.0, 9.1.0, and 11.1.0](../etc/patches/gcc-4.7.4/musl-support).

To achieve reproducibility, we had to apply a few more custom patches that
ensure [build directory independence](../etc/patches/gcc-4.7.4/reproducibility).

Furthermore, to make this a *portable C/C++ toolchain* (which uses bundled
binutils), we needed to create a shell launcher (e.g., `gcc` launching
`gcc.real`) that sets `PATH` to bundled binutils, relative to its own location.

### 6. Busybox

Building Busybox requires the Busybox "essentials", `make`, and GCC 4.7.4 from
the previous steps. This *full collection* of Busybox is ensured to be built
with an efficient compiler and contains many useful tools for the next stages.

### 7. GNU Make

Building `make` requires `make`, GCC 4.7.4, and Busybox from the previous steps.
This version of `make` is ensured to be built with an efficient compiler for use
in the next stages.

## Stage 1

The result of the previous stage is a toolchain definition, containing Busybox,
`make`, and GCC 4.7.4 bundled with binutils. Unfortunately, GCC 4.7.4 is not
sufficient to build modern compilers, because most of them require full C++11
support. Therefore, we introduced a second bootstrapping stage.

### GCC 10.2.0

GCC 10.2.0 is the first GCC version that fully supports the C++11 standard. GCC
and binutils are built in separate actions, so we can make sure `ar` is
configured with `--enable-deterministic-archives`. Both actions build for the
host using the toolchain `stage-0/gcc`. To achieve reproducibility, we had to
apply a few patches to GCC that ensure build directory independence.
Furthermore, the use of `msgfmt` is disabled by setting `check_msgfmt=no`.
Otherwise, the build process might call `msgfmt` with the `LD_LIBRARY_PATH` set
to the current toolchain's lib dir, which might contain an insufficient
`libstdc++` version.

