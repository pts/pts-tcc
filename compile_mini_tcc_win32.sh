#! /bin/sh --
# by pts@fazekas.hu at Wed May 15 02:20:34 CEST 2024
set -ex
test "${0%/*}" = "$0" || cd "${0%/*}"

# Run this first: ./pts-tcc-0.9.26-compile.sh

#rm -f ./*.o tcc-0.9.26/*.o  # Would also remove good_strtold.o.
# If we omit --gcc=4.8, we lose 80-bit `long double' support. OpenWatcom only has 64-bit `double'.
# -march=i386 is needed by DOSBox, because it silently fails for cmovne in -march=i686.
# -fno-common is needed by wlink, otherwise it generates buggy code.
../pathbin/minicc --gcc=4.8 -march=i386 -c -nostdlib -DCONFIG_NO_RP3 -DHAVE_SMART_PRINTF -Dgood_strtold=strtold \
    -DCONFIG_TCCDIR='"/dev/null"' -DTCC_VERSION='"0.9.26-2"' -DTCC_VERSION10000=926 -DTCC_TARGET_I386 -DCONFIG_TCC_STATIC -DCONFIG_TCC_STATIC_LINK_ONLY -DCONFIG_NO_RUN -DCONFIG_NO_EXEC -fno-common -fno-strict-aliasing \
    -Wno-unused-parameter -Wno-sign-compare -Wno-missing-field-initializers -Wno-pointer-sign -Wno-unused-result -Wno-shift-negative-value \
    tcc-0.9.26/tcc.c tcc-0.9.26/libtcc.c tcc-0.9.26/tccelf.c tcc-0.9.26/tccgen.c tcc-0.9.26/tccpp.c tcc-0.9.26/i386-gen.c tcc-0.9.26/tccasm.c tcc-0.9.26/i386-asm.c
../pathbin/minicc -march=i386 -c -momf -o win32_adapter.o win32_adapter.c
../pathbin/minicc -march=i386 -c -momf -DLINUX -o linux_adapter.o win32_adapter.c
# !! Try tools/wlink.
# Use `d d' for DWARF debug info.
wlink sys linux op map=tl.map op q op noext l clib3r n pts-tccpl.unc f linux_adapter.o f tcc.o f libtcc.o f tccelf.o f tccgen.o f tccpp.o f i386-gen.o f tccasm.o f i386-asm.o f libc_i64/i64_divdi3.o f libc_i64/i64_udivdi3.o f libc_i64/i64_moddi3.o f libc_i64/i64_umoddi3.o f libc_i64/i64_i8d.o f libc_i64/i64_u8d.o f ../build_tmp/memcmp.o f ../build_tmp/memcpy.o f ../build_tmp/memmove.o f ../build_tmp/memset.o f ../build_tmp/strchr.o f ../build_tmp/strcmp.o f ../build_tmp/strcpy.o f ../build_tmp/strlen.o f ../build_tmp/strncmp.o f ../build_tmp/strrchr.i386.o f ../build_tmp/strcat.o f ../build_tmp/strtod.i386.o f ../build_tmp/strtof.i386.o f ../build_tmp/strtol.o f ../build_tmp/strtold.o f ../build_tmp/strtoll.o f ../build_tmp/strtoul.o f ../build_tmp/strtoull.o f ../build_tmp/atoi.o f ../build_tmp/setjmp.o f ../build_tmp/longjmp.o
wlink sys win32 op map=t.map op q runtime console=3.10 op noext l clib3r n pts-tccp.unc.exe f win32_adapter.o f tcc.o f libtcc.o f tccelf.o f tccgen.o f tccpp.o f i386-gen.o f tccasm.o f i386-asm.o f libc_i64/i64_divdi3.o f libc_i64/i64_udivdi3.o f libc_i64/i64_moddi3.o f libc_i64/i64_umoddi3.o f libc_i64/i64_i8d.o f libc_i64/i64_u8d.o f ../build_tmp/memcmp.o f ../build_tmp/memcpy.o f ../build_tmp/memmove.o f ../build_tmp/memset.o f ../build_tmp/strchr.o f ../build_tmp/strcmp.o f ../build_tmp/strcpy.o f ../build_tmp/strlen.o f ../build_tmp/strncmp.o f ../build_tmp/strrchr.i386.o f ../build_tmp/strcat.o f ../build_tmp/strtod.i386.o f ../build_tmp/strtof.i386.o f ../build_tmp/strtol.o f ../build_tmp/strtold.o f ../build_tmp/strtoll.o f ../build_tmp/strtoul.o f ../build_tmp/strtoull.o f ../build_tmp/atoi.o f ../build_tmp/setjmp.o f ../build_tmp/longjmp.o
#wlink sys win32 op map=t.map op stack=0x300000 op q runtime console=3.10 op noext l clib3r n pts-tccp.unc.exe f win32_adapter.o f tcc.o f libtcc.o f tccelf.o f tccgen.o f tccpp.o f i386-gen.o f tccasm.o f i386-asm.o f libc_i64/i64_divdi3.o f libc_i64/i64_udivdi3.o f libc_i64/i64_moddi3.o f libc_i64/i64_umoddi3.o f libc_i64/i64_i8d.o f libc_i64/i64_u8d.o f ../build_tmp/memcmp.o f ../build_tmp/memcpy.o f ../build_tmp/memmove.o f ../build_tmp/memset.o f ../build_tmp/strchr.o f ../build_tmp/strcmp.o f ../build_tmp/strcpy.o f ../build_tmp/strlen.o f ../build_tmp/strncmp.o f ../build_tmp/strrchr.i386.o f ../build_tmp/strcat.o f ../build_tmp/strtod.i386.o f ../build_tmp/strtof.i386.o f ../build_tmp/strtol.o f ../build_tmp/strtold.i386.o f ../build_tmp/strtoll.o f ../build_tmp/strtoul.o f ../build_tmp/strtoull.o f ../build_tmp/atoi.o f ../build_tmp/setjmp.o f ../build_tmp/longjmp.o
#wlink sys win32 op q runtime console=3.10 op noext l clib3r n pts-tccp.unc.exe f win32_adapter.o f tcc.o f libtcc.o f tccelf.o f tccgen.o f tccpp.o f i386-gen.o f tccasm.o f i386-asm.o f libc_i64/i64_divdi3.o f libc_i64/i64_udivdi3.o f libc_i64/i64_moddi3.o f libc_i64/i64_umoddi3.o f libc_i64/i64_i8d.o f libc_i64/i64_u8d.o f ../build_tmp/memcmp.o f ../build_tmp/memcpy.o f ../build_tmp/memmove.o f ../build_tmp/memset.o f ../build_tmp/strchr.o f ../build_tmp/strcmp.o f ../build_tmp/strcpy.o f ../build_tmp/strlen.o f ../build_tmp/strncmp.o f ../build_tmp/strrchr.i386.o f ../build_tmp/strcat.o f ../build_tmp/strtod.i386.o f ../build_tmp/strtof.i386.o f ../build_tmp/strtol.o f ../build_tmp/strtold.i386.o f ../build_tmp/strtoll.o f ../build_tmp/strtoul.o f ../build_tmp/strtoull.o f ../build_tmp/atoi.o f ../build_tmp/setjmp.o f ../build_tmp/longjmp.o
#wlink sys win32 op q runtime console=3.10 op noext l clib3r n pts-tccp.unc.exe f win32_adapter.o f hello.o f libc_i64/i64_divdi3.o f libc_i64/i64_udivdi3.o f libc_i64/i64_moddi3.o f libc_i64/i64_umoddi3.o f libc_i64/i64_i8d.o f libc_i64/i64_u8d.o f ../build_tmp/memcmp.o f ../build_tmp/memcpy.o f ../build_tmp/memmove.o f ../build_tmp/memset.o f ../build_tmp/strchr.o f ../build_tmp/strcmp.o f ../build_tmp/strcpy.o f ../build_tmp/strlen.o f ../build_tmp/strncmp.o f ../build_tmp/strrchr.i386.o f ../build_tmp/strcat.o f ../build_tmp/strtod.i386.o f ../build_tmp/strtof.i386.o f ../build_tmp/strtol.o f ../build_tmp/strtold.i386.o f ../build_tmp/strtoll.o f ../build_tmp/strtoul.o f ../build_tmp/strtoull.o f ../build_tmp/atoi.o f ../build_tmp/setjmp.o f ../build_tmp/longjmp.o
cp pts-tccp.unc.exe t.exe
dl/upx --ultra-brute --no-lzma -q -q -f -o pts-tccp.ubr.exe pts-tccp.unc.exe

: "$0" OK.