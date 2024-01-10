#!/bin/sh

set -eu

SRCDIR=$1
APPLET_GROUP=$2
APPLET_NAME=$3

export CC=${CC:-cc}
export CFLAGS="${CFLAGS:-} -D_GNU_SOURCE -Iinclude -I${SRCDIR} -I${SRCDIR}/include"

DEP_SRCS="
  libbb/bb_pwd.c
  libbb/bb_strtonum.c
  libbb/concat_path_file.c
  libbb/concat_subpath_file.c
  libbb/common_bufsiz.c
  libbb/compare_string_array.c
  libbb/copyfd.c
  libbb/crc32.c
  libbb/default_error_retval.c
  libbb/endofname.c
  libbb/fclose_nonstdin.c
  libbb/fflush_stdout_and_exit.c
  libbb/full_write.c
  libbb/get_last_path_component.c
  libbb/get_line_from_file.c
  libbb/getopt32.c
  libbb/isqrt.c
  libbb/last_char_is.c
  libbb/llist.c
  libbb/makedev.c
  libbb/make_directory.c
  libbb/messages.c
  libbb/mode_string.c
  libbb/perror_msg.c
  libbb/process_escape_sequence.c
  libbb/procps.c
  libbb/ptr_to_globals.c
  libbb/read.c
  libbb/read_printf.c
  libbb/recursive_action.c
  libbb/safe_poll.c
  libbb/safe_strncpy.c
  libbb/safe_write.c
  libbb/signals.c
  libbb/skip_whitespace.c
  libbb/time.c
  libbb/verror_msg.c
  libbb/wfopen.c
  libbb/wfopen_input.c
  libbb/xatonum.c
  libbb/xfunc_die.c
  libbb/xfuncs.c
  libbb/xfuncs_printf.c
  libbb/xgetcwd.c
  libbb/xreadlink.c
  libbb/xrealloc_vector.c
  libbb/xregcomp.c
  archival/bbunzip.c
  archival/chksum_and_xwrite_tar_header.c
  archival/libarchive/data_align.c
  archival/libarchive/data_extract_all.c
  archival/libarchive/data_extract_to_stdout.c
  archival/libarchive/data_skip.c
  archival/libarchive/filter_accept_all.c
  archival/libarchive/filter_accept_reject_list.c
  archival/libarchive/find_list_entry.c
  archival/libarchive/get_header_tar.c
  archival/libarchive/header_list.c
  archival/libarchive/header_skip.c
  archival/libarchive/header_verbose_list.c
  archival/libarchive/init_handle.c
  archival/libarchive/open_transformer.c
  archival/libarchive/seek_by_jump.c
  archival/libarchive/seek_by_read.c
  archival/libarchive/unsafe_prefix.c
  archival/libarchive/unsafe_symlink_target.c
"

if [ ! -f dep.objs ]; then
  NUM=0
  for SRC in ${DEP_SRCS}; do
    # use short object file name to keep final command line short
    ${CC} ${CFLAGS} -c ${SRCDIR}/${SRC} -o ${NUM}.o
    NUM=$((${NUM}+1))
  done
  ls *.o | LC_ALL=C sort > dep.objs
fi

${CC} ${CFLAGS} -DAPPLET_GROUP=${APPLET_GROUP} -DAPPLET_NAME=${APPLET_NAME} \
  -o ${APPLET_NAME} appletlib.c $(cat dep.objs)
