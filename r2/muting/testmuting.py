from muting import MutableString
st = 'test test'
a = MutableString(st)
for i in xrange(-30, 30):
    for j in xrange(-30, 30):
        if a[i:j] != st[i:j]:
            print i, j, repr(a[i:j]), repr(st[i:j])
a[2:5] = 'foo'
print str(a)