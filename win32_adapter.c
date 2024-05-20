/* pts@fazekas.hu at Wed May 15 02:20:34 CEST 2024 */
/* !! Segfaults at an unexpected location in mwperun.exe, and segfaults later with Wine. */

#ifndef __WATCOMC__
#  error This adapter needs the Watcom C compiler.
#endif

#ifndef __386__
#  error This adapter works only on i386 CPU.
#endif

#ifndef __MINILIBC686__
#  error This adapter works with minilibc686.
#endif

#pragma aux __watcall "*_"
#pragma aux __cdecl "*"

typedef int time_t;
typedef unsigned size_t;
typedef struct _FILE *FILE;

/* Overrides lib386/nt/clib3r.lib / mbcupper.o
 * Source: https://github.com/open-watcom/open-watcom-v2/blob/master/bld/clib/mbyte/c/mbcupper.c
 * Overridden implementation calls CharUpperA in USER32.DLL:
 * https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-charuppera
 *
 * This function is a transitive dependency of _cstart() with main() in
 * OpenWatcom. By overridding it, we remove the transitive dependency of all
 * .exe files compiled with `owcc -bwin32' on USER32.DLL.
 *
 * This is a simplified implementation, it keeps non-ASCII characters intact.
 */
unsigned int __watcall _mbctoupper(unsigned int c) {
  return (c - 'a' + 0U <= 'z' - 'a' + 0U)  ? c + 'A' - 'a' : c;
}

extern int __cdecl tcc_main(int argc, char **argv);
#pragma aux tcc_main "main"

extern FILE* __watcall __get_std_file(unsigned handle);

FILE *mini_stdin, *mini_stdout, *mini_stderr;
#pragma aux mini_stdin "mini_stdin"
#pragma aux mini_stdout "mini_stdout"
#pragma aux mini_stderr "mini_stderr"

int mini_errno;  /* Set and ingnored. */
#pragma aux mini_errno "mini_errno"

int __watcall main(int argc, char **argv) {
  mini_stdin = __get_std_file(0);
  mini_stdout = __get_std_file(1);
  mini_stderr = __get_std_file(2);
  return tcc_main(argc, argv);
}
#pragma aux main "main_"

char * __cdecl mini_getcwd(char *buf, size_t size) {  /* Fake. */
  (void)size;
  buf[0] = '.';
  buf[1] = '\0';
  return buf;
}

/* Watcom libc constants. */
#ifdef LINUX
#  define W_O_CREAT 000100
#  define W_O_TRUNC 001000
#  define W_O_BINARY 0
#else
#  define W_O_CREAT 0x0020
#  define W_O_TRUNC 0x0040
#  define W_O_BINARY 0x0200
#endif

/* Linux constants. */
#define O_CREAT 0100
#define O_TRUNC 01000

extern int __watcall open(const char *__path, int __oflag, ...);
int __cdecl mini_open(const char *path, int flags, unsigned mode) {
  int flags2 = (flags & 3) | W_O_BINARY;
  if (flags & O_CREAT) flags2 |= W_O_CREAT;
  if (flags & O_TRUNC) flags2 |= W_O_TRUNC;
  return open(path, flags2, mode);
}

struct timeb {
  time_t         time;      /* seconds since Jan 1, 1970 UTC */
  unsigned short millitm;   /* milliseconds */
  short          timezone;  /* difference in minutes from UTC */
  short          dstflag;   /* nonzero if daylight savings time */
};
struct timeval {
  long tv_sec;     /* seconds */
  long tv_usec;    /* microseconds */
};
extern int __watcall ftime(struct timeb *timeptr);
int __cdecl mini_gettimeofday(struct timeval *tv, struct timezone *tz) {
  struct timeb tb;
  (void)tz;  /* Simplified, we don't set it. */
  if (ftime(&tb) != 0) return -1;
  tv->tv_sec = tb.time;
  tv->tv_usec = tb.millitm * 1000;
  return 0;
}

/* Forwards __cdecl to __cdecl. __watcall with variable number of arguments is actually __cdecl. */
#define FWD(func) extern void __watcall func(void); __declspec(naked) void __cdecl mini_ ## func(void) { __asm { jmp func } }
FWD(printf)
FWD(fprintf)
FWD(snprintf)
FWD(sprintf)

/* Forwards __cdecl function call to __watcall implementation of up to 4 arguments. */
static __declspec(naked) void fwd4(void) { __asm {
		push ebx  /* Save. */
		mov eax, [esp+3*4]
		mov edx, [esp+4*4]
		mov ebx, [esp+5*4]
		mov ecx, [esp+6*4]
		call dword ptr [esp+1*4]
		pop ebx  /* Restore. */
		pop ecx  /* Pop the called function. It's OK to spoil ECX for the __cdecl calling convention. */
		ret
} }
#define FWD4(func) extern void __watcall func(void); __declspec(naked) void __cdecl mini_ ## func(void) { __asm { push offset func } __asm { jmp fwd4 } }
FWD4(abort)
FWD4(close)
FWD4(exit)
FWD4(fclose)
FWD4(fdopen)
FWD4(fopen)
FWD4(fputc)
FWD4(fputs)
FWD4(free)
FWD4(fwrite)
FWD4(getenv)
FWD4(localtime)  /* struct tm for localtime(3) matches. */
FWD4(lseek)
FWD4(malloc)
FWD4(read)
FWD4(realloc)
FWD4(time)
FWD4(unlink)
FWD4(vsnprintf)
FWD4(fflush);  /* !! Remove. */

