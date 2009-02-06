#!/usr/bin/env python
import sys, struct, os
g = open(sys.argv[1], 'rb')
g.seek(0, os.SEEK_END)
length = g.tell()
g.seek(0, os.SEEK_SET)
hdr4 = (length << 8) + 16
if hdr4 > 0x100000000:
    print 'File too big.'
    sys.exit(1)
f = open(sys.argv[2], 'wb')
f.write('LZ77')
f.write(struct.pack('<I', hdr4))

for i in xrange(length):
    f.write('\x00')
    f.write(g.read(8))