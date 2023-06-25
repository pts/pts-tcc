#ifndef _STDDEF_H
#  define _STDDEF_H
#  ifdef __SIZE_TYPE__  /* __GNUC__ */
    typedef __SIZE_TYPE__ size_t;
#  else
    typedef unsigned long size_t;  /* 64 bits for __GNUC__ __x86_64__. */
#  endif
  typedef long wchar_t;  /* Dummy. uClibc headers use it, but TCC sources don't need it. */
#  ifndef NULL
#    define NULL ((void*)0)
#  endif
#endif  /* _STDDEF_H */
