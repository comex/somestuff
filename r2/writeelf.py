import sys, struct, re
from UserString import MutableString

strings = '\0.strtab\0'
str_offset = 9
elfn = {'text': 0, 'data': 0}


class ElfSection:
    def __init__(self, type, addr, data):
        global strings, str_offset, elf_offset, elfn
        if type == 'bss':
            x = '.bss\0'
        else:
            x = '.%s.%02x\0' % (type, elfn[type])
            elfn[type] += 1
        self.x = x
        self.str_offset = str_offset
        strings += x
        str_offset += len(x)
        
        self.addr = addr
        #while len(data) % 4 != 0: data += '\0' # % 256
        self.size = len(data)
        self.data = data
        self.type = type
# .bss

#elfsections.append(ElfSection('bss', 0x80494880, chr(0) * 0x001108D4, elf_offset))


def writeElf(elfsections, outfile):
    global strings, str_offset

    while len(strings) < 0x400: strings += '\0'

    print [i.x for i in elfsections]

    elfheader = MutableString(chr(0) * 0x400)
    elfheader[0] = chr(0x7f)
    elfheader[1] = chr(0x45)
    elfheader[2] = chr(0x4c)
    elfheader[3] = chr(0x46)
    elfheader[4] = chr(0x01)
    elfheader[5] = chr(0x02)
    elfheader[6] = chr(0x01)
    
    def write16(stx, place, number):
        stx[place:place+2] = struct.pack('>H', number)
    def write32(stx, place, number):
        stx[place:place+4] = struct.pack('>I', number)
    write16(elfheader, 0x10, 2)
    write16(elfheader, 0x12, 0x14)
    write32(elfheader, 0x14, 1)
    write32(elfheader, 0x18, 0x80000000) # entrypoint TODO
    write32(elfheader, 0x1c, 0x400)
    write32(elfheader, 0x20, 0x800)
    write32(elfheader, 0x24, 0)
    write16(elfheader, 0x28, 0x400) # 0x34
    write16(elfheader, 0x2a, 0x400) # 0x20
    write16(elfheader, 0x2c, len(elfsections)+2)
    write16(elfheader, 0x2e, 0x400) # 0x28
    write16(elfheader, 0x30, len(elfsections)+3) # +2
    write16(elfheader, 0x32, 1)
    
    segheader = ''
    elf_offset = 0x1000
    for es in elfsections:
        es.elf_offset = elf_offset
        elf_offset += es.size
        segheader += struct.pack('>IIIIIIII',
            1,
            es.elf_offset,
            es.addr,
            es.addr,
            0 if es.type == 'bss' else es.size,
            es.size,
            5 if es.type == 'text' else 6,
            0x20
        )
    while len(segheader) < 0x400: segheader += chr(0)
    secheader = MutableString(chr(0) * 0x400)
    write32(secheader, 0x28 + 0x00, 1)
    write32(secheader, 0x28 + 0x04, 3)
    write32(secheader, 0x28 + 0x08, 0)
    write32(secheader, 0x28 + 0x0c, 0)
    write32(secheader, 0x28 + 0x10, 0xc00)
    write32(secheader, 0x28 + 0x14, 0x400)
    write32(secheader, 0x28 + 0x18, 0)
    write32(secheader, 0x28 + 0x1c, 0)
    write32(secheader, 0x28 + 0x20, 1)
    write32(secheader, 0x28 + 0x24, 0)
    p = 0x50
    for es in elfsections:
        write32(secheader, p + 0x00, es.str_offset)
        write32(secheader, p + 0x04, 8 if es.type == 'bss' else 1)
        write32(secheader, p + 0x08, 6 if es.type == 'text' else 3)
        write32(secheader, p + 0x0c, es.addr)
        write32(secheader, p + 0x10, es.elf_offset)
        write32(secheader, p + 0x14, es.size)
        write32(secheader, p + 0x18, 0)
        write32(secheader, p + 0x1c, 0)
        write32(secheader, p + 0x20, 0x20)
        write32(secheader, p + 0x24, 0)
        p += 0x28
    
    print 'elfheader: 0x%x\nsegheader: 0x%x\nsecheader: 0x%x\n' % (len(elfheader), len(segheader), len(secheader))
    f = open(outfile, 'wb')
    f.write(str(elfheader)) # 0x400
    f.write(segheader)      # 0x800
    f.write(str(secheader)) # 0xc00
    f.write(strings)        # 0x1000
    for es in elfsections:
        f.write(es.data)
    f.close()
