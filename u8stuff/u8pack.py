#!/usr/bin/env python
# Not perfectly compatible but Good Enough
import os, sys, struct
chunks = []
last_node = 0
def pack(fn, is_root=False):
    global last_node
    #print fn
    id = last_node + 1
    last_node = id
    
    recursion = len(fn) - len(fn.replace('/', '')) - base - 1
    if recursion < 0: recursion = 0
    #print fn, recursion, base
    if os.path.isdir(fn):
        chunks.append(None)
        ld = sorted(os.listdir(fn))
        if sorted(ld) == ['banner.bin', 'icon.bin', 'sound.bin']:
            # Sorting for binary compatibility
            ld = ['icon.bin', 'banner.bin', 'sound.bin']
        for i in ld:
            pack(os.path.join(fn, i))
        chunks[id-1] = (0x100, None if is_root else os.path.basename(fn), recursion, None, last_node)
    else:
        f = open(fn, 'rb')
        d = f.read()
        f.close()
        size = len(d)
        while len(d) % 32 != 0:
            d += '\x00'
        chunks.append((0, os.path.basename(fn), recursion, d, size))
base = len(sys.argv[1]) - len(sys.argv[1].replace('/', ''))
pack(sys.argv[1], True)
for n, (type, name, recursion, data, size) in enumerate(chunks):
    print 'ID: %x name: %s rec: %d datalen: %s size: %d' % (n, name, recursion, '-' if data is None else str(len(data)), size)
name_shit = '\x00'
data_shit = ''
chunks2 = []

for (type, name, recursion, data, size) in chunks:
    if name is None:
        name_offs = 0
    else:
        name_offs = len(name_shit)
        name_shit += name + chr(0)
    if data is None:
        data_offs = -recursion - 1
    else:  
        data_offs = len(data_shit)
        data_shit += data
    chunks2.append((type, name_offs, data_offs, size))
def align(x, boundary):
    if x % boundary == 0:
        return x
    else:
        return x + boundary - (x % boundary)
header1_size = 12*len(chunks2)
header2_size = len(name_shit)
header_size = header1_size + header2_size
print '%x = %x + %x' % (header_size, header1_size, header2_size)
rootnode_offset = 0x20
data_offset = align(rootnode_offset + header_size, 0x40)
f = open(sys.argv[2], 'wb')
f.write('\x55\xAA\x38\x2D')
f.write(struct.pack('>I', rootnode_offset))
f.write(struct.pack('>I', header_size))
f.write(struct.pack('>I', data_offset))
f.write('\x00' * 16)
for (type, name_offs, data_offs, size) in chunks2:
    if data_offs < 0:
        data_offs = -(data_offs + 1)
    else:
        data_offs += data_offset
    f.write(struct.pack('>HHII', type, name_offs, data_offs, size))
f.write(name_shit)
f.write('\x00' * (data_offset - rootnode_offset - header_size))
f.write(data_shit)
f.close()
