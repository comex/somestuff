#!/bin/sh
python cx.py "$1"
powerpc-750-linux-gnu-gcc -static -o decompress_ppc out.c
echo '#!/bin/sh' > decompress
echo 'exec qemu-ppc decompress_ppc' >> decompress
chmod 755 decompress

