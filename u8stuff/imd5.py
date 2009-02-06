#!/usr/bin/env python
import sys, hashlib, struct
nopadding = False
if '-n' in sys.argv:
	sys.argv.remove('-n')
	nopadding = True
f = open(sys.argv[1], 'rb')
z = f.read()
f.close()
if not nopadding:
	while len(z) % 32 != 0:
		z += '\x00'

md = hashlib.md5(z).digest()
f = open(sys.argv[2], 'wb')
f.write('IMD5')
f.write(struct.pack('>I', len(z)))
f.write('\x00' * 8)
f.write(md)
f.write(z)
f.close()
