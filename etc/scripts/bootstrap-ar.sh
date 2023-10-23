#!/bin/sh

set -eu

SRCDIR=$1

( cd ${SRCDIR}

  export CC=${CC:-cc}
  export LD=${LD:-${CC}}
  export AR=true
  export RANLIB=true
  export MAKE=${MAKE:-make}
  export CFLAGS="${CFLAGS:-} -I."

  AR_SRCS="
    binutils/ar.c
    binutils/arparse.c
    binutils/arlex.c
    binutils/arsup.c
    binutils/not-ranlib.c
    binutils/rename.c
    binutils/binemul.c
    binutils/emul_vanilla.c
    binutils/bucomm.c
    binutils/version.c
    binutils/filemode.c
  "

  # fake dlfcn.h in order to disable dynamic loads during configure
  echo '#error fail here' > dlfcn.h

  # configure and build object files for bfd, libiberty, zlib, and libsframe
  ./configure --prefix=/ --disable-nls --enable-gprofng=no --disable-werror --enable-deterministic-archives --without-zstd
  ${MAKE} MAKEINFO=true all-binutils || true

  export CFLAGS="${CFLAGS} -DDEFAULT_AR_DETERMINISTIC=1 -Dbin_dummy_emulation="bin_vanilla_emulation" -Iinclude -Ibfd "

  # build archiver object files
  NUM=0
  for SRC in ${AR_SRCS}; do
    # use short object file name to keep final command line short
    ${CC} ${CFLAGS} -c ${SRC} -o ${NUM}.o
    NUM=$((${NUM}+1))
  done

  ${CC} ${CFLAGS} -o ar $(ls *.o bfd/*.o libiberty/*.o zlib/*.o libsframe/*.o | LC_ALL=C sort) -ldl
)

mv ${SRCDIR}/ar .
