import sys, os, struct, dol
from UserString import MutableString
f = open(sys.argv[1], 'rb')
d = dol.DOL(f.read())
f.close()
addy = 0x80204fc8

BLR = '4e800020'.decode('hex')
funcs = {}
output = ''
def makebl(a):
    assert a < 0x1fffffff and a > -0x20000000
    a %= 0x3fffffff
    return struct.pack('>I', a | 0x48000001)
def doFunc(addr):
    global funcs, goffset, output
    print 'func: %08x' % addr
    # Assumptions: No branches to outside of function etc
    func = d.getString(addr, 10000)
    blr = func.find(BLR)
    assert blr != -1
    func = func[:blr+4]
    #print hex(len(func))
    #print func.encode('hex')
    assert len(func) % 4 == 0
    offs = len(output)
    funcs[addr] = offs
    output += 'R' * len(func)
    for a in xrange(0, len(func), 4):
        code, = struct.unpack('>I', func[a:a+4])
        if code == code | 0x48000001: # BLR
            target = (code & ~0x48000001) + a + addr
            print '%08x --> %08x' % (code, target)
            if funcs.get(target) is None:
                doFunc(target)
            func = func[:a] + makebl(funcs[target] - (offs+a)) + func[a+4:]
    output = output[:offs] + func + output[offs+len(func):]



doFunc(addy)

st = output   




st2 = ''
for i in st:
    st2 += '\\x' + i.encode('hex')
g = open('out.c', 'wb')
g.write(open('sctempl.c').read().replace('<>', st2))
g.close()
