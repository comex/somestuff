from muting import MutableString
st = 'test test'
a = MutableString(st)
def maybe(x):
    try:
        return x()
    except Exception, e:
        return str(e)
for i in xrange(-30, 30):
    for j in xrange(-30, 30):
        if a[i:j] != st[i:j]:
            print i, j, repr(a[i:j]), repr(st[i:j])
for i in xrange(-30, 30):
    if maybe(lambda: a[i]) != maybe(lambda: st[i]):
        print i, maybe(lambda: a[i]), maybe(lambda: st[i])
a[2:5] = 'foo'
a[1] = 'q'
print a
q = {a: 1, 'tqfootest': 2}
print q
print a.__cmp__(MutableString('tqfootest')) # Python limitations say I can't have it == 'tqfootest'