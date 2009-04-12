#!/bin/sh
python cxuncompress.py "$1"
powerpc-750-linux-gnu-gcc -g -static -o decompress_ppc out.c
echo '#!/bin/sh' > decompress
echo 'exec qemu-ppc decompress_ppc "$@"' >> decompress
chmod 755 decompress

