#!/bin/sh
python ssbcompress.py "$1"
powerpc-750-linux-gnu-gcc -g -static -o ssbcompress_ppc out.c
echo '#!/bin/sh' > ssbcompress
echo 'exec qemu-ppc ssbcompress_ppc "$@"' >> ssbcompress
chmod 755 ssbcompress

