import sys, struct, re
from muting import MutableString
import cProfile

# Current organization:
# An instance of a cstype is a field.  An instance of a cstruct is an actual value.
# To support arrays properly, I'll need a proxy class for buf

# Dumb pretty printer
used_objects = None
def my_repr(b, start=''):
    special = lambda x: type(x) not in (int, str, unicode)
    if type(b) == dict:
        if len(filter(special, b.values())) == 0:
            rep = '{ '
            f = False
            for a in sorted(b.keys()):
                if f:
                    rep += ', '
                else:
                    f = True
                rep += '%s: %s' % (str(a), my_repr(b[a]))
            rep += ' }'
        else:
            rep = '{\n'
            for a in sorted(b.keys()):
                c = b[a]
                if type(c) in (dict, list):
                    rep += '%s:\n%s\n' % (str(a), my_repr(c, '  '))
                else:
                    rep += '%s: %s\n' % ( str(a), my_repr(c))
            rep += '}'
    elif type(b) in (int, long):
        rep = hex(b)
    elif type(b) in (list, tuple):
        if len(filter(special, b)) == 0:
             rep = '[' + ', '.join(map(my_repr, b)) + ']'
        else:
            rep = '[\n'
            rep += ',\n'.join(my_repr(a, '  ') for a in b)
            rep += '\n]'
    else:
        rep = repr(b)
    return re.sub(re.compile('^', re.M), start, rep)

class cstype(object):
    def default(self):
        return None


# This should be better than the benzin approach

class cstval(cstype):
    def __init__(self, offs):
        self.offs = offs
        self.size = struct.calcsize('>'+self.typ)
    def unpack(self, buf):
        return struct.unpack('>'+self.typ, buf[self.offs:self.offs+self.size])[0]
    def pack(self, buf, val):
        buf[self.offs:self.offs+self.size] = struct.pack('>'+self.typ, val)
    def getmax(self):
        return self.offs + self.size

class u32(cstval):
    typ = 'I'
class u16(cstval):
    typ = 'H'
class u8(cstval):
    typ = 'B'

class cststruct(cstype):
    def __init__(self, cls, offs):
        self.cls = cls
        self.offs = offs
        self.size = cls.size
    def unpack(self, buf):
        return self.cls().unpack(buf)
    def pack(self, buf, val):
        buf[self.offs:self.offs+self.size] = val.pack()
    
    def getmax(self):
        return self.offs + self.size



class cstruct(object):
    class metacls(type):
        def __new__(mcs, name, bases, dict):
            cls = type.__new__(mcs, name, bases, dict)
            cls.csvals = {}
            rm = 0
            for k in dir(cls):
                v = getattr(cls, k)
                if isinstance(v, cstype):
                    m = v.getmax()
                    if m > rm: rm = m
                    cls.csvals[k] = v
                    setattr(cls, k, v.default())
            cls.size = rm
            return cls

    __metaclass__ = metacls

    def unpack(self, buf):
        self.buf = buf
        for k, v in self.csvals.items():
            setattr(self, k, v.unpack(buf))
        return self
    def pack(self):
        buf = MutableString('\0' * self.size)
        for k, v in self.csvals.items():
            v.pack(buf, getattr(self, k))
        return str(buf)

    
    def __repr__(self):
        print type(self), hash(self)
        inf = '%s:\n' % re.sub('^.*\.', '', str(self.__class__)).strip("'>")
        dc = {}
        for k in dir(self):
            v =  getattr(self, k)
            if k[0] != '_' and not callable(v) and k not in ('buf', 'csvals', 'size'):
                dc[k] = v
        inf += my_repr(dc)
        return inf
        
    @classmethod
    def unpackMany(cls, buf, num, *args):
        return [cls().unpack(buf[i*cls.size:(i+1)*cls.size], *args) for i in xrange(num)]
    
    @classmethod
    def unpackUntilDone(self, buf, num):
        ret = []
        i = 0
        try:
            while True:
                ret.append(cls().unpack(buf[i*cls.size:(i+1)*cls.size]))
                i += 1
        except DoneException:
            pass
    
    @classmethod
    def type(cls, offs):
        return cststruct(cls, offs)
