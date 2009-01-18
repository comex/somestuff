import sys, struct
f = open('../maintemp.bin', 'rb')
blob =f.read()
f.close()
print len(blob)

f = open(sys.argv[1], 'r+b')
z = f.read()

f.seek(4) # file offset for text1
f.write(struct.pack('>I', len(z)))

f.seek(0x4c) # loading address
f.write('\x80\x00\x34\x00')

f.seek(0x94) # size
f.write(struct.pack('>I', len(blob)))

f.seek(0xe0)
f.write('\x80\x00\x34\x00')

f.seek(len(z))
f.write(blob)

f.close()