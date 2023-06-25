#ifndef _STDARG_H
#  define _STDARG_H 1
#  if (defined(__WATCOMC__) && defined(_M_I386)) || (defined(__TINYC__) && defined(__i386__))
    typedef char *__gnuc_va_list;
#    define va_start(ap, last) ((ap) = (char*)&(last) + ((sizeof(last)+3)&~3), (void)0)  /* i386 only. */
#    define va_arg(ap, type) ((ap) += (sizeof(type)+3)&~3, *(type*)((ap) - ((sizeof(type)+3)&~3)))  /* i386 only. */
#    define va_end(ap) /*((ap) = 0, (void)0)*/  /* i386 only. Adding the `= 0' back doesn't make a difference. */
#  else
    typedef __builtin_va_list __gnuc_va_list;
#    define va_start(v,l) __builtin_va_start(v,l)
#    define va_end(v) __builtin_va_end(v)
#    define va_arg(v,l) __builtin_va_arg(v,l)
#  endif
  typedef __gnuc_va_list va_list;
  #ifdef __TINYC__  /* uClibc <sys/types.h> bug. */
    __extension__ typedef long long int64_t;
  #endif
#endif
