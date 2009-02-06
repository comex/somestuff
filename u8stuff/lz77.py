#!/usr/bin/env python
import sys, struct, re
#import psyco
#psyco.full()
# by marcan. 
class WiiLZ77:
		TYPE_LZ77 = 1
		def __init__(self, file, offset):
				self.file = file
				self.offset = offset

				self.file.seek(self.offset)

				hdr = struct.unpack("<I",self.file.read(4))[0]
				self.uncompressed_length = hdr>>8
				self.compression_type = hdr>>4 & 0xF

				if self.compression_type != self.TYPE_LZ77:
						raise ValueError("Unsupported compression method %d"%self.compression_type)

		def uncompress(self):
				dout = ""

				self.file.seek(self.offset + 0x4)

				while len(dout) < self.uncompressed_length:
						flags = struct.unpack("<B",self.file.read(1))[0]

						for i in range(8):
								if flags & 0x80:
										info = struct.unpack(">H",self.file.read(2))[0]
										num = 3 + ((info>>12)&0xF)
										disp = info & 0xFFF
										ptr = len(dout) - (info & 0xFFF) - 1
										for i in range(num):
												dout += dout[ptr]
												ptr+=1
												if len(dout) >= self.uncompressed_length:
														break
								else:
										dout += self.file.read(1)
								flags <<= 1
								if len(dout) >= self.uncompressed_length:
										break

				self.data = dout
				return self.data

f = open(sys.argv[1])

hdr = f.read(4)
if hdr != "LZ77":
	f.seek(0x20)
	assert f.read(4) == 'LZ77'

unc = WiiLZ77(f, f.tell())

du = unc.uncompress()
try:
	f2 = open(sys.argv[2],"w")
	f2.write(du)
	f2.close()
except IndexError:
	dx = re.sub('\.lz7$', '', sys.argv[1])
	if dx != sys.argv[1]:
		f2 = open(dx, 'w')
		f2.write(du)
		f2.close()
	else:
		raise
