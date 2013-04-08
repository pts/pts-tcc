#! /bin/bash --
#
# Build pts-tcc using uClibc.
# by pts@fazekas.hu at Mon Apr  8 15:45:02 CEST 2013
#
# To create the patch:
# for F in tcc-0.9.26/{*.{c,h},configure}.orig; do diff -u -U10 "$F" "${F%.orig}"; done >pts-tcc-0.9.26.patch
# Using uClibc 0.9.30.1.
#

set -ex
UCLIBC_USR="${UCLIBC_USR:-/usr/i386-linux-uclibc/usr}"
test -f "$UCLIBC_USR/lib/crt1.o"
test -f "$UCLIBC_USR/lib/crti.o"
test -f "$UCLIBC_USR/lib/crtn.o"
test -f "$UCLIBC_USR/lib/libc.a"
test -f "$UCLIBC_USR/lib/libm.a"
test -f "$UCLIBC_USR/lib/libcrypt.a"
test -f "$UCLIBC_USR/lib/libutil.a"
type -p upx.pts || type -p upx
type -p gcc
type -p ld
type -p perl

test -f tcc-0.9.26.tar.bz2 || wget http://download.savannah.nongnu.org/releases/tinycc/tcc-0.9.26.tar.bz2
test -f tcc-0.9.26.tar.bz2
test -f pts-tcc-0.9.26.patch || wget http://pts-mini-gpl.googlecode.com/svn/trunk/pts-tcc/pts-tcc-0.9.26.patch
test pts-tcc-0.9.26.patch

bash ./i386-uclibc-gcc.c  # create i386-uclibc-gcc
CC="$PWD/i386-uclibc-gcc"
rm -rf tcc-0.9.26
tar xjf tcc-0.9.26.tar.bz2
(cd tcc-0.9.26 && patch -p1 <../pts-tcc-0.9.26.patch) || exit "$?"

(cd tcc-0.9.26 && ./configure --cc="$CC -static" --extra-cflags='-DCONFIG_TCC_STATIC') || exit "?"
echo "CONFIG_NOLDL=yes" >>tcc-0.9.26/config.mak
(cd tcc-0.9.26 && make libtcc1.a) || exit "$?"

rm -rf tcclibc
mkdir tcclibc
#-rw-r--r-- 1 pts eng 1233128 Nov 27  2010 libc.a
#-rw-r--r-- 1 pts eng  214376 Nov 27  2010 libm.a
#-rw-r--r-- 1 pts eng   16386 Nov 27  2010 libcrypt.a
#-rw-r--r-- 1 pts eng   12024 Nov 27  2010 librt.a
#-rw-r--r-- 1 pts eng    7668 Nov 27  2010 libutil.a
# c,m: 329484 compressed
# c,m,crypt,util: 336732 compressed
for F in "$UCLIBC_USR"/lib/lib{c,m,crypt,util}.a; do
  ls -l "$F"
  (cd tcclibc && ar x "$F") || exit "$?"
done
(cd tcclibc && ar x ../tcc-0.9.26/libtcc1.a) || exit "$?"
rm -f tcclibc.a  # ar cr doesn't remove the file.
(cd tcclibc && ar cr ../tcclibc.a *.o)
ls -l tcclibc.a
for F in tcclibc.a "$UCLIBC_USR"/lib/{crt1.o,crti.o,crtn.o}; do
  G="${F##*/}"
  export NAME="data_${G%.*}"
  perl -e '$_=join("",<STDIN>); my$L=length; s@([^-+/\w])@sprintf"\\%03o",ord$1@ge; print".globl $ENV{NAME}\n.section .data\n.align 4\n.size $ENV{NAME},$L\n$ENV{NAME}:\n.string \"$_\\001\"\n"' <"$F"
done >tcc-0.9.26/libcdata.s

(cd tcc-0.9.26 && $CC -static -o ../pts-tcc.uncompressed tcc.c libtcc.c tccelf.c tccgen.c tccpp.c i386-gen.c tccrun.c tccasm.c i386-asm.c libcdata.s -DTCC_TARGET_I386 -O2 -s -Wall -fno-strict-aliasing -mpreferred-stack-boundary=2 -march=i386 -falign-functions=0 -Wno-pointer-sign -Wno-sign-compare -lm -DCONFIG_TCC_STATIC -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=0) || exit "$?"
ls -l pts-tcc.uncompressed
cp -f pts-tcc.uncompressed pts-tcc
upx.pts --best pts-tcc || upx --best pts-tcc
./elfosfix.pl pts-tcc pts-tcc.uncompressed
