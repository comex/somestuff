import hashlib, sys, os, struct
from UserString import MutableString
if len(sys.argv) != 6:
	print 'Usage: python fix0.py 0.app.in 0.app.out icon.u8 banner.u8 sound.wav'
	sys.exit(1)
f = open(sys.argv[1], 'rb')
zs = f.read()
z = MutableString(zs)

sizes = [os.path.getsize(sys.argv[i]) for i in 3, 4, 5]
z[0x8c:0x98] = struct.pack('>III', *sizes)

f.close()
z[0x40:0x80] = chr(0) * 0x40
z[0x640 - 0x10:0x640] = chr(0) * 0x10
m = hashlib.md5(str(z)[0x40:0x640])
print m.hexdigest()
z[0x640 - 0x10:0x640] = m.digest()
f = open(sys.argv[2], 'wb')
f.write(str(z))
f.close()
