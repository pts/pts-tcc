#! /bin/sh --
# by pts@fazekas.hu at Wed May 15 02:20:17 CEST 2024
set -ex
test "${0%/*}" = "$0" || cd "${0%/*}"

# Run this first: ./pts-tcc-0.9.26-compile.sh

#dl/upx --ultra-brute --no-lzma -q -q -f -o pts-tcc.ow.ubr pts-tcc.ow.unc
# If we omit --gcc=4.8, we lose 80-bit `long double' support. OpenWatcom only has 64-bit `double'.
../pathbin/minicc --gcc=4.8 \
    -DCONFIG_TCCDIR='"/dev/null"' -DTCC_VERSION='"0.9.26-2"' -DTCC_VERSION10000=926 -DTCC_TARGET_I386 -DCONFIG_TCC_STATIC -DCONFIG_TCC_STATIC_LINK_ONLY -DCONFIG_NO_RUN -DCONFIG_NO_EXEC -Dgood_strtold=strtold -fno-strict-aliasing \
    -Wno-unused-parameter -Wno-sign-compare -Wno-missing-field-initializers -Wno-pointer-sign -Wno-unused-result -Wno-shift-negative-value \
    -o pts-tccp.unc \
    tcc-0.9.26/tcc.c tcc-0.9.26/libtcc.c tcc-0.9.26/tccelf.c tcc-0.9.26/tccgen.c tcc-0.9.26/tccpp.c tcc-0.9.26/i386-gen.c tcc-0.9.26/tccasm.c tcc-0.9.26/i386-asm.c
dl/upx --ultra-brute --no-lzma -q -q -f -o pts-tccp.ubr pts-tccp.unc

: "$0" OK.
