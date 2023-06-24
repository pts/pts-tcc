#! /bin/sh --
set -ex

../pathbin/minicc --gcc -DCONFIG_TCCDIR='"/dev/null"' -DTCC_VERSION='"0.9.26-1"' -DTCC_VERSION10000=92600 -DTCC_TARGET_I386 -DCONFIG_TCC_STATIC -DCONFIG_NO_RUN -DCONFIG_NO_EXEC -fno-strict-aliasing \
    -Wno-unused-parameter -Wno-sign-compare -Wno-missing-field-initializers -Wno-pointer-sign -Wno-unused-result -Wno-shift-negative-value \
    -o pts-tcc-minil.unc \
    tcc-0.9.26/tcc.c tcc-0.9.26/libtcc.c tcc-0.9.26/tccelf.c tcc-0.9.26/tccgen.c tcc-0.9.26/tccpp.c tcc-0.9.26/i386-gen.c tcc-0.9.26/tccasm.c tcc-0.9.26/i386-asm.c
# TODO(pts): Currently it doesn't link, there are undefined symbols.
# TODO(pts): Can we replace strtof with strtod?
# TODO(pts): Undefined symbols: malloc+realloc+free strtof strtold strtoll strtoul strtoull
ls -ld pts-tcc-minil.unc
dl/upx --ultra-brute --no-lzma -q -q -f -o pts-tcc-minil.ubr pts-tcc-minil.unc
ls -ld pts-tcc-minil.unc pts-tcc-minil.ubr

: "$0" OK.
