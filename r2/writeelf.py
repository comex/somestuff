import sys, struct, re
from UserString import MutableString

strings = '\0.strtab\0'
str_offset = 9
elfn = {'text': 0, 'data': 0}


class ElfSection:
    def __init__(self, type, addr, data, note=None):
        global strings, str_offset, elf_offset, elfn
        if type == 'bss':
            x = '.bss'
        else:
            x = '.%s.%02x' % (type, elfn[type])
            elfn[type] += 1
        if note is not None: x += '.' + note
        x += '\0'
        self.x = x
        self.note = note
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

def pad(st):
    while len(st) % 0x400 != 0: st += '\0'
    return st

def writeElf(elfsections, outfile):
    global strings, str_offset

    strings = pad(strings)

    for i in elfsections:
        print i.x, i.note

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

    
    segheader = ''
    
    for es in elfsections:
        segheader += struct.pack('>IIIIIIII',
            1,
            0xeeeeeeee,
            es.addr,
            es.addr,
            0 if es.type == 'bss' else es.size,
            es.size,
            5 if es.type == 'text' else 6,
            0x20
        )
    
    secheader = '\x00' * 40
    secheader += struct.pack('>IIIIIIIIII',
        1,
        3,
        0,
        0,
        0x99999999,
        len(strings),
        0,
        0,
        1,
        0
    )
 
    for es in elfsections:
        secheader += struct.pack('>IIIIIIIIII',
            es.str_offset,
            8 if es.type == 'bss' else 1,
            6 if es.type == 'text' else 3,
            es.addr,
            0xdddddddd,
            es.size,
            0,
            0,
            0x20,
            0
        )

    segheader = pad(segheader)
    secheader = pad(secheader)
    

    secheader = secheader[:0x38] + struct.pack('>I', 0x400 + len(secheader) + len(segheader)) + secheader[0x3c:]
    elf_offset = 0x400 + len(secheader) + len(segheader) + len(strings)
    for i, es in enumerate(elfsections):
        offs = 0x4 + 32*i
        segheader = segheader[:offs] + struct.pack('>I', elf_offset) + segheader[offs+4:]
        offs2 = 0x60 + 40*i
        secheader = secheader[:offs2] + struct.pack('>I', elf_offset) + secheader[offs2+4:]
        es.elf_offset = elf_offset
        elf_offset += -(-es.size & -0x400)
    
    
    
    write16(elfheader, 0x10, 2)
    write16(elfheader, 0x12, 0x14)
    write32(elfheader, 0x14, 1)
    write32(elfheader, 0x18, 0x80000000) # entrypoint TODO
    write32(elfheader, 0x1c, 0x400) # Start of segheader
    write32(elfheader, 0x20, 0x400 + len(segheader))
    write32(elfheader, 0x24, 0)
    write16(elfheader, 0x28, 0x400) # 0x34
    write16(elfheader, 0x2a, 32) # 0x20
    write16(elfheader, 0x2c, len(elfsections))
    write16(elfheader, 0x2e, 40) # 0x28
    write16(elfheader, 0x30, len(elfsections)+2) # +2
    write16(elfheader, 0x32, 1)
    
    print 'elfheader: 0x%x\nsegheader: 0x%x\nsecheader: 0x%x\n' % (len(elfheader), len(segheader), len(secheader))
    f = open(outfile, 'wb')
    f.write(str(elfheader)) # 0x400
    f.write(segheader)      # 0x800
    f.write(str(secheader)) # 0xc00
    f.write(strings)        # 0x1000
    for es in elfsections:
        f.write(pad(es.data))
    f.close()
