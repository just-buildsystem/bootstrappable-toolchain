/*
 * Minimalistic implementation of appletlib.c that does not require any header
 * generation.
 */
#define stringify_impl(x)   #x
#define stringify(x)        stringify_impl(x)
#define concat(x,y)         x##y
#define applet_main(name)   concat(name, _main)

/* Define this accessor before we #define "errno" our way */
#include <errno.h>
static inline int *get_perrno(void) { return &errno; }

#include stringify(APPLET_GROUP/APPLET_NAME.c)

int main(int argc, char **argv) {
#ifdef bb_cached_errno_ptr
	ASSIGN_CONST_PTR(&bb_errno, get_perrno());
#endif
  return applet_main(APPLET_NAME)(argc, argv);
}

/* missing definitions from appletlib.c */
const char *applet_name = stringify(APPLET_NAME);
void bb_show_usage() { xfunc_die(); }
unsigned string_array_len(char **argv) {
  char **start = argv;
  while (*argv)
    argv++;
  return argv - start;
}

/* missing definitions for tar.c (despite 'to_command' being disabled) */
#include "bb_archive.h"
void FAST_FUNC data_extract_to_command(archive_handle_t *archive_handle) {
  /* unused */
}
