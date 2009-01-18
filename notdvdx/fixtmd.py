import os, hashlib, struct
fn = 'notdvdx.tmd'
assert os.path.getsize(fn) == 0x1e4 + 36*2

g = open(fn, 'r+b')

f = open('zero.app', 'rb')
z = f.read()
stuff = hashlib.sha1(z).digest()
print repr(stuff)
f.close()

g.seek(0x1e4 + 0xc)
g.write(struct.pack('>I', len(z)))
g.write(stuff)

f = open('main.dol', 'rb')
z = f.read()
stuff = hashlib.sha1(z).digest()
print repr(stuff)
f.close()

g.seek(0x1e4 + 36 + 0xc)
g.write(struct.pack('>I', len(z)))
g.write(stuff)
g.close()
