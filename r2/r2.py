import sys, struct, re, psyco
from dol import DOL
from writeelf import ElfSection, writeElf
from cstruct import *
psyco.full()
class REL(cstruct):
    libID = u32(0)
    unk1 =  u32(4)
    unk2 = u32(8)
    numSegments = u32(0xc)
    segTableOffset = u32(0x10)
    unk5 = u32(0x14)
    unk6 = u32(0x18)
    unk7 = u32(0x1c)
    unk8 = u32(0x20)
    relTableOffset = u32(0x24)
    importTableOffset = u32(0x28)
    importTableSize = u32(0x2c)
    def __init__(self, fn, base):
        self.fn = fn
        self.base = base
        self.loaded = False
    def load(self):
        if self.loaded: return self
        self.loaded = True
        buf = self.buf
        print >> sys.stderr, 'Loading %s' % self.fn
        self.segments = Segment.unpackMany(buf[self.segTableOffset:], self.numSegments)
        self.imports = Import.unpackMany(buf[self.importTableOffset:], self.importTableSize/Import.size, buf)
    def relocate(self):
        print >> sys.stderr, 'Relocating %s' % self.fn
        buf = MutableString(self.buf)
        [j.relocate(buf, self) for i in self.imports for j in i.relocs]
        self.buf = str(buf)
        return self
    def toSections(self):
        return [ElfSection(seg.type, self.base + seg.offset, self.buf[seg.offset:seg.offset+seg.length]) for seg in self.segments if seg.length > 0]
class Segment(cstruct):
    offset = u32(0)
    length = u32(4)
    def unpack(self, buf):
        cstruct.unpack(self, buf)
        if self.offset & 1:
            self.offset -= 1
            self.type = 'text'
        else:
            self.type = 'data'
        return self

class Import(cstruct):
    libID = u32(0)
    relocationTableOffset = u32(4)
    def unpack(self, buf, gbuf):
        cstruct.unpack(self, buf)
        self.relocs = Relocation.unpackUntilDone(gbuf[self.relocationTableOffset:], self.libID)
        return self

class Relocation(cstruct):
    offsetDelta = u16(0)
    relType = u8(2)
    segment = u8(3)
    rel = u32(4)
    
    def __init__(self, libID):
        self.libID = libID
    
    def unpack(self, buf, oldOffset):
        cstruct.unpack(self, buf)
        self.offset = oldOffset + self.offsetDelta
        return self
    
    def __repr__(self):
        return '<relocation(%x): %x <-- %x@%x>' % (self.relType, self.offset, self.libID, self.rel)
    @classmethod
    def unpackUntilDone(cls, buf, *args):
        global rels
        ret = []
        offset = 0
        offs = 0
        while True:
            v = cls(*args).unpack(buf[offs:offs+cls.size], offset)
            ret.append(v)
            if v.relType == 0xcb: # terminator
                break
            elif v.relType == 0xca: # change segment
                offset = 0
            else:
                offset = v.offset
            offs += cls.size
        return ret
    
    def relocate(self, buf, rel):
        global rels
        if self.libID == 0:
            source = 0 # rel is absolute
        else:
            rels[self.libID].load()
            source = rels[self.libID].base + rels[self.libID].segments[self.segment].offset
        source += self.rel
        assert source == source % 0xffffffff
        offset = self.offset
        typ = self.relType
        if typ == 1: # 32 bits
            buf[offset:offset + 4] = struct.pack('>I', source)
        elif typ == 4:
            buf[offset:offset + 2] = struct.pack('>H', source & 0xffff)
        elif typ == 6:
            buf[offset:offset + 2] = struct.pack('>H', (source >> 16) & 0xffff)
        elif typ == 0xa:
            # Oh, this sucks
            ptr = rel.base + offset
            orig = str(buf[offset:offset+4])
            if len(orig) != 4:
                print 'WTF ZOMG'
                print len(buf)
                print offset
                print len(buf[offset:offset+4])
                die
            #print self.libID, hex(self.rel), hex(source), hex(ptr)
            a = struct.pack('>I', (((source - ptr) % 0xffffffff) & 0x3fffffc ) | (struct.unpack('>I', orig)[0] & 0xfc000003))
            buf[offset:offset + 4] = a
        elif typ == 0xca or typ == 0xcb or typ == 0xc9:
            pass
        else:
            print >> sys.stderr, '(Unsupported type %d)' % typ
        sys.stderr.write('.')
        
        
dol = DOL(open(sys.argv[1], 'rb').read())

rels = {}
def go(ar):
    global rels
    rel_start = 0x80800000
    for fn in ar:
        f = open(fn, 'rb')
        rel = f.read()
        f.close()
        
        size = len(rel) + 0x10000
        size -= size % 0x10000

        rel = REL(fn, rel_start).unpack(rel)
        rels[rel.libID] = rel
        
        rel_start += size

    rv = rels.values()
    
    #rv = [rv[0]]
    for rel in rv:
        rel.load()
    for rel in rv:
        rel.relocate()
        #print rel
    sections = []
    for addr, data, _ in dol.text:
        sections.append(ElfSection('text', addr, data))
    for addr, data, _ in dol.data:
        sections.append(ElfSection('data', addr, data))
    for rel in rv:
        sections += rel.toSections()
    writeElf(sections, sys.argv[-1])
    print len(rels)
cProfile.run('go(set(sys.argv[2:-1]))')

#go(set(sys.argv[2:]))