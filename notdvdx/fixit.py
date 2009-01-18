import struct
f = open('main.dol', 'r+b')
sz = len(f.read()) - 0x100
f.seek(0x90)
f.write(struct.pack('>I', sz))
f.close()
