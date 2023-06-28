#! /bin/sh --
set -ex

# Run this first: ./pts-tcc-0.9.26-compile.sh

# --gcc=4.4 doesn't have -Wno-unused-result
# --gcc=4.8 doesn't need -Wno-shift-negative-value (GCC 7.5.0)
# --gcc (GCC 7.5.0) generates the smallest code.
# Compiles with: --gcc -gcc=clang --gcc=4.4 --tcc --pcc --wcc.
../pathbin/minicc --gcc --diet -DCONFIG_TCCDIR='"/dev/null"' -DTCC_VERSION='"0.9.26-1"' -DTCC_VERSION10000=926 -DTCC_TARGET_I386 -DCONFIG_TCC_STATIC -DCONFIG_NO_RUN -DCONFIG_NO_EXEC -DCONFIG_LIBC_NO_MALLOC -fno-strict-aliasing \
    -Wno-unused-parameter -Wno-sign-compare -Wno-missing-field-initializers -Wno-pointer-sign -Wno-unused-result -Wno-shift-negative-value \
    -o pts-tcc-minid.unc \
    tcc-0.9.26/tcc.c tcc-0.9.26/libtcc.c tcc-0.9.26/tccelf.c tcc-0.9.26/tccgen.c tcc-0.9.26/tccpp.c tcc-0.9.26/i386-gen.c tcc-0.9.26/tccasm.c tcc-0.9.26/i386-asm.c
dl/upx --ultra-brute --no-lzma -q -q -f -o pts-tcc-minid.ubr pts-tcc-minid.unc
ls -ld pts-tcc-minid.unc pts-tcc-minid.ubr


: "$0" OK.
