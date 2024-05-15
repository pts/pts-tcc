#! /bin/sh --
set -ex
test "${0%/*}" = "$0" || cd "${0%/*}"

# Run this first: ./pts-tcc-0.9.26-compile.sh

SYSROOT="$PWD"/dl/pts-xstatic/xstaticempty
UCLIBC_LIBDIR="${SYSROOT%/xstaticempty}/xstaticusr/lib"
UCLIBC_CLDDIR="${SYSROOT%/xstaticempty}/xstaticcld"

rm -rf tcc-0.9.26/libcdata/utcclibc
mkdir tcc-0.9.26/libcdata/utcclibc

#for F in libc.a libm.a libcrypt.a libutil.a; do
#  (cd tcc-0.9.26/libcdata/utcclibc && ../../../dl/ar x "$UCLIBC_LIBDIR/$F") || die "ar x failed"
#done
(cd tcc-0.9.26/libcdata/utcclibc && ../../../dl/ar x ../../../uclibc-0.9.30.1.a) || die "ar x failed"

cp -a libc_start/start.o tcc-0.9.26/libcdata/
cp -a libc_float_i686/*.o tcc-0.9.26/libcdata/utcclibc/
cp -a libc_i64/*.o tcc-0.9.26/libcdata/utcclibc/
cp -a libc_tcc/*.o tcc-0.9.26/libcdata/utcclibc/
cp -a libc_othercc/*.o tcc-0.9.26/libcdata/utcclibc/

for F in __fpending.o gets.o mktemp.o siggetmask.o tmpnam.o utimes.o; do  # Remove the sections causing the linker warnings.
  strip -S -x -R '.gnu.warning.*' -R .note.GNU-stack -R .comment -R .eh_frame "tcc-0.9.26/libcdata/utcclibc/$F"
done

(cd tcc-0.9.26/libcdata/utcclibc && ../../../dl/ar crs ../utcclibc.a *.o) || die "ar crs failed"

( echo ".globl data_tcclibc"; echo ".section .data"; echo "data_tcclibc:"; echo ".incbin \"tcc-0.9.26/libcdata/utcclibc.a\""; echo ".string \"\\001\""
  echo ".globl data_crt1"; echo ".section .data"; echo "data_crt1:"; echo ".incbin \"tcc-0.9.26/libcdata/start.o\""; echo ".string \"\\001\""
) >tcc-0.9.26/libcdata_utcc.s
../pathbin/minicc as --32 -o tcc-0.9.26/libcdata_utcc.o tcc-0.9.26/libcdata_utcc.s  # Use GNU as(1), with `.incbin' support.

# --gcc=4.8 generates the smallest code when compressed.
# Compiles cleanly with: --gcc -gcc=clang --gcc=4.8 --gcc=4.4 --tcc --pcc.
../pathbin/minicc --gcc=4.8 -nostdinc -nostdlib -I"$UCLIBC_LIBDIR"/../include -Icc_include \
    -DCONFIG_TCCDIR='"/dev/null"' -DTCC_VERSION='"0.9.26-2"' -DTCC_VERSION10000=926 -DTCC_TARGET_I386 -DCONFIG_TCC_STATIC -DCONFIG_TCC_DATA -DCONFIG_NO_RUN -DCONFIG_NO_EXEC -fno-strict-aliasing \
    -Wno-unused-parameter -Wno-sign-compare -Wno-missing-field-initializers -Wno-pointer-sign -Wno-unused-result -Wno-shift-negative-value \
    -o pts-tcc-miniutcc.unc \
    tcc-0.9.26/tcc.c tcc-0.9.26/libtcc.c tcc-0.9.26/tccelf.c tcc-0.9.26/tccgen.c tcc-0.9.26/tccpp.c tcc-0.9.26/i386-gen.c tcc-0.9.26/tccasm.c tcc-0.9.26/i386-asm.c tcc-0.9.26/libcdata_utcc.o \
    tcc-0.9.26/libcdata/start.o tcc-0.9.26/libcdata/utcclibc.a
dl/upx --ultra-brute --no-lzma -q -q -f -o pts-tcc-miniutcc.ubr pts-tcc-miniutcc.unc
ls -ld pts-tcc-miniutcc.unc pts-tcc-miniutcc.ubr

: "$0" OK.
