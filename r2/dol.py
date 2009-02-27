import struct, sys
class DOL(object):
    text = data = None
    ep = 0x80004000
    bss_addr = 0x80001f00
    bss_size = 0x10
    def __init__(self, dol=None):
        self.text = []
        self.data = []
        if dol is not None:
            a = 0
            offss = []
            addrs = []
            sizes = []

            for ar in (offss, addrs, sizes):
                for i in xrange(18):
                    ar.append(struct.unpack('>I', dol[a:a+4])[0])
                    a += 4

            self.bss_addr, self.bss_size, self.ep = struct.unpack('>III', dol[0xd8:0xe4])

            ware = {}
            for num, offs in enumerate(offss):
                if offs != 0:
                    ware[num] = dol[offs:offs+sizes[num]]

            for i in xrange(7):
                if offss[i] != 0:
                    self.text.append([addrs[i], ware[i], offss[i]])
            for i in xrange(7, 18):
                if offss[i] != 0:
                    self.data.append([addrs[i], ware[i], offss[i]])
    def info(self):
        for num, (addr, ware, _) in enumerate(self.text):
            print 'Text[%d] --> %08x / size: %x' % (num, addr, len(ware))
        for num, (addr, ware, _) in enumerate(self.data):
            print 'Data[%d] --> %08x / size: %x' % (num, addr, len(ware))

        print 'BSS: %08x / size: %x' % (self.bss_addr, self.bss_size)
        print 'Entry point: %08x' % self.ep

    def dump(self, wrapafter=False): # note: wrapafter doesn't actually DO anything
        sections = []
        dol = ''
        dolbody = ''
        dolbodyn = 0
        for i in xrange(7):
            sections.append(self.text[i] if len(self.text) > i else None)
        for i in xrange(11):
            sections.append(self.data[i] if len(self.data) > i else None)
        
        for num, a in enumerate(sections):
            if a is None:
                dol += '\x00\x00\x00\x00'
            else:
                if len(a[1]) > 0:
                    while len(dolbody) % (64 if wrapafter else 32) != 0:
                        dolbody += '\x00'
                dol += struct.pack('>I', len(dolbody) + 0x100)
                dolbody += a[1]

        for num, a in enumerate(sections):
            if a is None:
                dol += '\x00\x00\x00\x00'
            else:
                dol += struct.pack('>I', a[0])
        for num, a in enumerate(sections):
            if a is None:
                dol += '\x00\x00\x00\x00'
            else:
                dol += struct.pack('>I', len(a[1]))
        dol += struct.pack('>III', self.bss_addr, self.bss_size, self.ep)
        dol += '\x00' * 0x1c
        dol += dolbody
        while len(dol) % (64 if wrapafter else 32) != 0: dol += '\x00'
        return dol
if __name__ == '__main__':
    orig = open(sys.argv[1], 'rb').read()
    x = DOL(orig)
    x.info()
    assert x.dump() == orig
    #new = x.dump()
    #f = open('out.dol', 'wb')
    #f.write(new)
    #f.close()
