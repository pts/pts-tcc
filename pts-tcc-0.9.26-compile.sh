#! /bin/bash --
#
# Build pts-tcc using xstatic (using uClibc 0.9.30.1).
# by pts@fazekas.hu at Mon Apr  8 15:45:02 CEST 2013
#
# Requirements to compile:
#
# * Linux.
# * i386 or amd64 (x86_g4) architecture.
# * gcc installed. Works with gcc-4.8 ... gcc-7.3. Recommended: gcc-4.8.
# * wget installed.
#
# To create the patch, run any of:
#   for F in tcc-0.9.26/{*.c,*.h,configure}; do test "$F" = tcc-0.9.26/config.h && continue; diff -u -U10 orig/"$F" "$F"; done >pts-tcc-0.9.26.patch
#   for F in tcc-0.9.26/{tcc.c,tccelf.c,tccgen.c,tccpp.c,tcc.h,configure}; do diff -u -U10 orig/"$F" "$F"; done >pts-tcc-0.9.26.patch
#
# TODO: Don't use the `xstatic' binary, invoke `gcc', `gcc -E', `as' and `ld' manually from the xstatic dir.
# TODO: Use a smaller `ar' executable. (Where is it?)
# TODO: Use our assembler `as' executable. Does it work with gcc-7.3?
# TODO: Add uClibc #include files to the pts-tcc binary.
#

set -ex

function die() {
  set +ex
  echo "fatal: $@" >&2
  exit 1
}

type -p perl || die "perl: command not found"
type -p grep || die "grep: command not found"
type -p tar || die "tar: command not found"
type -p bzip2 || die "bzip2: command not found"
type -p strip || die "strip: command not found"

# --- Download dependencies.

mkdir -p dl

if ! test -f dl/tcc-0.9.26.tar.bz2; then
  # Original download URL: http://download.savannah.nongnu.org/releases/tinycc/tcc-0.9.26.tar.bz2
  wget -nv -O dl/tcc-0.9.26.tar.bz2.tmp https://github.com/pts/pts-tcc/releases/download/tcc/tcc-0.9.26.tar.bz2
  mv dl/tcc-0.9.26.tar.bz2.tmp dl/tcc-0.9.26.tar.bz2
fi

if ! test -f dl/pts-xstatic-latest.sfx.7z; then
  wget --no-check-certificate -nv -O dl/pts-xstatic-latest.sfx.7z.tmp http://pts.50.hu/files/pts-xstatic/pts-xstatic-latest.sfx.7z
  chmod 755 dl/pts-xstatic-latest.sfx.7z.tmp
  mv dl/pts-xstatic-latest.sfx.7z.tmp dl/pts-xstatic-latest.sfx.7z
fi

if ! test -f dl/pts-tcc-build-tools.sfx.7z; then
  wget -nv -O dl/pts-tcc-build-tools.sfx.7z.tmp https://github.com/pts/pts-tcc/releases/download/exec/pts-tcc-build-tools.sfx.7z
  chmod 755 dl/pts-tcc-build-tools.sfx.7z.tmp
  mv dl/pts-tcc-build-tools.sfx.7z.tmp dl/pts-tcc-build-tools.sfx.7z
fi

if ! test -f dl/pts-xstatic/xstaticcld/libgcc.a; then
  chmod 755 dl/pts-xstatic-latest.sfx.7z
  (cd dl && ./pts-xstatic-latest.sfx.7z -y) || die 'extracting pts-xstatic failed'
fi

if ! test -f dl/upx; then
  chmod 755 dl/pts-tcc-build-tools.sfx.7z
  (cd dl && ./pts-tcc-build-tools.sfx.7z -y) || die 'extracting pts-xstatic failed'
fi

# --- Find and detect gcc.

if type -p gcc-4.8 >/dev/null 2>&1; then
  # gcc-4.8 creates an uncompressed pts-tcc executable 3800 bytes smaller than gcc-7.3.
  GCC=gcc-4.8
elif type -p gcc >/dev/null 2>&1; then
  GCC=gcc
else
  die 'gcc: command not found'
fi

GCCOK=
# Using -march=i386 creates saves 4K of the compressed pts-tcc executable. 
for GCCFLAGS in '-m32 -march=i386' '-march=i386' ''; do
  rm -f gcctest.s
  # No need to add -m32, xstatic does it by default.
  $GCC $GCCFLAGS -S gcctest.c
  if grep 'addl.*$42, %eax$' <gcctest.s >/dev/null; then
    GCCOK=1
    break
  fi
done
test "$GCCOK" || die "unexpected assembly output in test compilation"
GCC="$GCC $GCCFLAGS"

#SYSROOT="$($XSTATIC $GCC -print-sysroot)"
SYSROOT="$PWD"/dl/pts-xstatic/xstaticempty
test "${SYSROOT%/xstaticempty}" = "$SYSROOT" && die "unexpected sysroot"
UCLIBC_LIBDIR="${SYSROOT%/xstaticempty}/xstaticusr/lib"
UCLIBC_CLDDIR="${SYSROOT%/xstaticempty}/xstaticcld"

# --- Check that we have all dependencies prepared.

test -f dl/upx
test -f dl/ar
test -f dl/ld
test -f dl/perl
test -f dl/pts-xstatic/xstaticcld/libgcc.a
test -f dl/tcc-0.9.26.tar.bz2
test -f dl/tcc-0.9.26.tar.bz2
test -f "$UCLIBC_CLDDIR/libgcc.a"
test -f "$UCLIBC_LIBDIR/crt1.o"
test -f "$UCLIBC_LIBDIR/crti.o"
test -f "$UCLIBC_LIBDIR/crtn.o"
test -f "$UCLIBC_LIBDIR/libc.a"
test -f "$UCLIBC_LIBDIR/libm.a"
test -f "$UCLIBC_LIBDIR/libcrypt.a"
test -f "$UCLIBC_LIBDIR/libutil.a"

# --- Compile.

if ! test -f tcc-0.9.26/config.h; then
  rm -rf  tcc-0.9.26
  tar xjf dl/tcc-0.9.26.tar.bz2
  (cd tcc-0.9.26 && patch -p1 <../pts-tcc-0.9.26.patch) || die "patch failed"
  # This would create: tcc-0.9.26/config.h tcc-0.9.26/config.mak tcc-0.9.26/config.texi
  # (cd tcc-0.9.26 && noldl=yes ./configure --cc=false --extra-cflags='-DCONFIG_TCC_STATIC') || die "configure failed"
  : >tcc-0.9.26/config.h  # config.mak and config.texi can be left empty.
fi

# No need to specify -fno-use-linker-plugin here, gcc-7.3 needs it only for linking (thus not with gcc -c).
CFLAGS='-DCONFIG_TCCDIR="/dev/null" -DTCC_VERSION="0.9.26-1" -DTCC_VERSION10000=926 -DTCC_TARGET_I386 -DCONFIG_TCC_STATIC -DCONFIG_TCC_DATA -DCONFIG_TCC_CRTIN -DCONFIG_NO_EXEC -fno-pic -fno-strict-aliasing -W -Wall -Wunused-result -Wno-pointer-sign -Wno-sign-compare -Wno-unused-parameter -Wno-missing-field-initializers -Wno-shift-negative-value -Wno-frame-address -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=0'

#-rw-r--r-- 1 pts eng 1233128 Nov 27  2010 libc.a
#-rw-r--r-- 1 pts eng  214376 Nov 27  2010 libm.a
#-rw-r--r-- 1 pts eng   16386 Nov 27  2010 libcrypt.a
#-rw-r--r-- 1 pts eng    7668 Nov 27  2010 libutil.a
# c,m: 329484 compressed
# c,m,crypt,util: 336732 compressed
if ! test -f tcclibc/o_done; then
  rm -rf tcclibc
  mkdir  tcclibc
  # These files .o would be added to libtcc1.a. We add the precompiled libc_tcc/*.o files instead.
  # for F in libtcc1.c alloca86.S alloca86-bt.S bcheck.c; do
  #   (cd tcc-0.9.26 && $GCC -static -B"$UCLIBC_CLDDIR" --sysroot="$SYSROOT" -fno-stack-protector -isystem "$UCLIBC_LIBDIR"/../include $CFLAGS -c lib/"$F" -o ../tcclibc/"${F%.*}.o" -Wno-cpp) || die 'gcc failed'
  # done

  for F in "$UCLIBC_LIBDIR"/lib{c,m,crypt,util}.a; do
    ls -l "$F"
    (cd tcclibc && ../dl/ar x "$F") || die "ar x failed"
  done
  cp -a libc_float_i686/*.o tcclibc/  # Overwrite code precompiled for -match=pentium3 (uClibc __CONFIG_PENTIUMIII__) with code precompied for earlier -march=i686.
  cp -a libc_i64/*.o tcclibc/  # Parts of libtcc1.c.
  cp -a libc_tcc/*.o tcclibc/  # libtcc1.c (parts), alloca86.S, alloca86-bt.S, bcheck.c.
  rm -f tcclibc/libtcc1.o tcclibc/start.o
  #
  #strip -S -x -R .note.GNU-stack -R .comment tcclibc/*.o
  for F in tcclibc/*.o; do
    ALL_SECTIONS="$(objdump -hw "$F" | awk '$3~/^[0-9a-fA-F]+$/{print$2}')"
    if test -z "$ALL_SECTIONS"; then
      if test "$(objdump -t "$F" | grep '[*]COM[*]')"; then  # Found a common symbol.
        strip -S -x "$F" ||:  # harmless: strip: error: the input file 'h_errno.o' has no sections
      else
        rm -f "$F"
      fi
      continue
    fi
    HAS_GLOBALBEG="$(objdump -t "$F" | grep '^00000000  *g  *[.]text[     ]' ||:)"
    test "$HAS_GLOBALBEG" && HAS_GLOBALBEG=.text
    EMPTY_SECTIONS="$(objdump -hw "$F" | busybox awk '$3~/^0+$/&&$2!='"\"$HAS_GLOBALBEG\""'{print"-R "$2}')"
    strip -S -x -R .note.GNU-stack -R .comment -R .eh_frame $EMPTY_SECTIONS "$F"
    ALL_SECTIONS="$(objdump -hw "$F" | awk '$3~/^[0-9a-fA-F]+$/{print$2}')"
    if test -z "$ALL_SECTIONS" && test -z "$(objdump -t "$F" | grep '[*]COM[*]')" && test -z "$HAS_GLOBALBEG"; then
      rm -f "$F"
    fi
  done
  : >>tcclibc/o_done
fi
rm -rf tcc-0.9.26/libcdata
mkdir  tcc-0.9.26/libcdata
(cd tcclibc && ../dl/ar crs ../tcc-0.9.26/libcdata/tcclibc.a *.o) || die "ar crs failed"
ls -l tcc-0.9.26/libcdata/tcclibc.a
for F in "$UCLIBC_LIBDIR"/{crt1.o,crti.o,crtn.o}; do
  cp -a "$F" tcc-0.9.26/libcdata/
done
for F in tcclibc.a crt1.o crti.o crtn.o; do
  G="${F##*/}"
  NAME="data_${G%.*}"
  echo ".globl $NAME"; echo ".section .data"; echo "$NAME:"; echo ".incbin \"libcdata/$F\""; echo ".string \"\\001\""
done >tcc-0.9.26/libcdata.s

(cd tcc-0.9.26 && $GCC -static -B"$UCLIBC_CLDDIR" --sysroot="$SYSROOT" -fno-stack-protector -isystem "$UCLIBC_LIBDIR"/../include $CFLAGS -c tcc.c libtcc.c tccelf.c tccgen.c tccpp.c i386-gen.c tccrun.c tccasm.c i386-asm.c libcdata.s -O2 -mpreferred-stack-boundary=2 -falign-functions=0) || die "gcc failed"
#(cd tcc-0.9.26 && $GCC -o ../pts-tcc.uncompressed  tcc.o libtcc.o tccelf.o tccgen.o tccpp.o i386-gen.o tccrun.o tccasm.o i386-asm.o libcdata.o -s -lm -v) || die "gcc linking failed"
(cd tcc-0.9.26 && ../dl/ld -nostdlib -m elf_i386 -static -o ../pts-tcc.uncompressed -s "$UCLIBC_CLDDIR"/crt1.o "$UCLIBC_CLDDIR"/crti.o "$UCLIBC_CLDDIR"/crtbeginT.o -L"$UCLIBC_CLDDIR" -L"$UCLIBC_LIBDIR" tcc.o libtcc.o tccelf.o tccgen.o tccpp.o i386-gen.o tccrun.o tccasm.o i386-asm.o libcdata.o -lm --start-group -lgcc -lc --end-group "$UCLIBC_CLDDIR"/crtend.o "$UCLIBC_CLDDIR"/crtn.o) || die "ld failed"

ls -l pts-tcc.uncompressed
# upx --lzma: 312548 bytes
# upx --ultra-brute --lzma: 313420 bytes
# upx --ultra-brute --no-lzma: 350180 bytes
# LZMA decompression is slower, but it saves many bytes, so we use it.
dl/upx --lzma -q -q -f -o pts-tcc pts-tcc.uncompressed
dl/upx --ultra-brute --no-lzma -q -q -f -o pts-tcc.ubr pts-tcc.uncompressed
# elfosfix.pl, needed only for pts-tcc.uncompressed.
# Change ELF executable system type from SYSV to GNU/Linux.
dl/perl -0777 -pi -e 'die if !s@\A(\177ELF...)[\0\3]@$1\003@s' pts-tcc pts-tcc.uncompressed

: pts-tcc compile OK.
