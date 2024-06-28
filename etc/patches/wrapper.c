#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

int main(int argc, char** argv) {
#include "toolname.h"
#include "link_args.h"
  char *s, *path, *newpath, *prgdir, *cwd, **newargv, *tool, *tmp;
  size_t size, s_s, s_cwd, s_prgdir, s_path, s_toolname, s_tmp;
  int i;

  for (link_args_c =0; link_args[link_args_c] != NULL; link_args_c++) {}

  if ((tmp=strdup(argv[0])) == NULL) {
    return 66;
  }
  s = strrchr(tmp, '/');
  if (s == NULL) {
    s = getenv("CC_DIR");
    if (s == NULL) {
      s = getenv("CC");
    }
    if (s == NULL) {
      s = getenv("CXX");
    }
    if (s != NULL) {
      if ((tmp=strdup(s)) == NULL) {
        return 66;
      }
      s = strrchr(tmp, '/');
    }
  }
  if (s != NULL) {
    *s = '\0';
    s_tmp = strlen(tmp);
    if ((prgdir=(char*)malloc(s_tmp + 1 + strlen(dir_offset) + 1)) == NULL) {
      return 66;
    }
    strcpy(prgdir, tmp);
    strcpy(&prgdir[s_tmp], "/");
    strcpy(&prgdir[s_tmp+1], dir_offset);
  } else {
    prgdir = dir_offset; /* last resort */
  }

  cwd = ".";
  if (*prgdir != '/') {
    /* called by non-absolute path, need to prefix with cwd */
    for (size = 1024;; size *= 2) {
      if ((cwd=(char*)malloc(size)) == NULL) {
        return 66;
      }
      if (getcwd(cwd, size) != NULL) {
        break;
      }
      if (errno != ERANGE) {
        return 66;
      }
    }
    s = prgdir;
    s_s = strlen(s);
    s_cwd = strlen(cwd);

    if ((prgdir=(char*)malloc(s_cwd + 1 + s_s + 1))==NULL) {
      return 66;
    }
    strcpy(prgdir, cwd);
    strcpy(&prgdir[s_cwd], "/");
    strcpy(&prgdir[s_cwd+1], s);
  }

  /* prgdir is now our best guess for the directory the real program is located in */
  path = getenv("PATH");
  if (path == NULL) {
    path = prgdir;
  } else {
    s_path = strlen(path);
    s_prgdir = strlen(prgdir);
    if ((newpath=(char*)malloc(s_prgdir + 1 + s_path + 1)) == NULL) {
      return 66;
    }
    strcpy(newpath, prgdir);
    strcpy(&newpath[s_prgdir], ":");
    strcpy(&newpath[s_prgdir+1], path);
    path = newpath;
  }
  setenv("PATH", path, 1);

  if ((newargv=(char**)malloc((argc + link_args_c + 1)*sizeof(char*)))==NULL) {
    return 66;
  }
  s_prgdir = strlen(prgdir);
  s_toolname = strlen(toolname);
  if ((tool=(char*)malloc(s_prgdir+1+s_toolname+1))==NULL) {
    return 66;
  }
  strcpy(tool, prgdir);
  strcpy(&tool[s_prgdir], "/");
  strcpy(&tool[s_prgdir+1], toolname);

  newargv[0] = tool;
  for (i=1; i<argc; i++) {
    newargv[i] = argv[i];
  }
  for (i=0; i < link_args_c; i++) {
    newargv[argc+i] = link_args[i];
  }
  newargv[argc+link_args_c] = NULL;

  execv(tool, newargv);

  return 65; /* exec failed */
}
