import sys, struct, os, select, time
class DoneError(Exception): pass
# It's possible to do this on OSX but requires some fancy invocations.
# I have no idea about Windows.
f = open('/dev/ttyUSB0', 'r+b')
def get_title_path(hi, lo):
    return 'title/%08x/%08x' % (hi, lo)
tmd_cache = {}
fds = {}
fdn = 0x11000
def sumsum(lblob):
    return sum([ord(i) for i in lblob])
def xwrite(blob):
    global f
    t1 = time.time()
    assert f.read(1) == '\x1d'    
    f.write(struct.pack('>I', len(blob)))
    pos = 0
    while True:
        if pos >= len(blob):
            print ' done.'
            break
        lblob = blob[pos:pos+1024]
        lbpos = 0
        try:
            while True:
                l_input, l_output, _ = select.select([f], [f], [f])
                if l_output: # f in l_output
                    f.write(lblob[lbpos])
                    lbpos += 1
                    if lbpos >= len(lblob): raise DoneError
                elif l_input: # f in l_input
                    raise DoneError
        except DoneError:
            pass
        cr = f.read(1)
        if cr != '\x1c':
            print '!: ' + hex(ord(cr))
            continue
        f.write(struct.pack('>I', sumsum(lblob)))
        ctrl = ord(f.read(1))
        if ctrl == 0x1e:
            sys.stdout.write(',')
            sys.stdout.flush()
            continue
        elif ctrl == 0x1f:
            sys.stdout.write('.')
            sys.stdout.flush()
            pos += 1024
        else:
            print 'wtf: %x' % ctrl
    t2 = time.time()
    print 'write took %f seconds' % (t2-t1)
def parse_tmd(hi, lo):   
    global tmd_cache
    h = (hi, lo)
    if tmd_cache.has_key(h):
        return tmd_cache[h]
    path = get_title_path(hi, lo) + '/content/title.tmd'
    if not os.path.exists(path):
        raise ValueError('title.tmd does not exist')
    f = open(path, 'rb')
    tmd = f.read()
    f.close()
    nbr_cont, = struct.unpack('>H', tmd[0x1de:0x1e0])
    tmd_parsed = {}
    for i in xrange(nbr_cont):
        offset = 0x1e4 + 36*i
        cid, index, ctype = struct.unpack('>IHH', tmd[offset:offset+8])
        tmd_parsed[index] = cid
    tmd_cache[h] = tmd_parsed
    return tmd_parsed
#print parse_tmd(1, 2) # sysmenu lol
while True:
    i = f.read(1)
    if i == '':
        continue
    #print hex(ord(i))
    if i == chr(0x13):
        # read three useless bytes without which it didn't work
        f.read(3)
        args = struct.unpack('>IIII', f.read(16))
        title_hi, title_lo, something, index = args
        print 'ES_OpenTitleContentFile(0x%x, 0x%x, 0x%x, 0x%x)' % args
        path = get_title_path(title_hi, title_lo)
        if os.path.exists(path):
            try:
                tmd = parse_tmd(title_hi, title_lo)
            except ValueError:
                print '! ...no %s/content/title.tmd! aborting!' % path
                ret = 0
            else:
                print tmd
                print index
                cid = tmd[index]
                cpath = '%s/content/%08x.app' % (path, cid)
                print '> access %s' % cpath
                try:
                    g = open(cpath, 'rb')
                except IOError:
                    print ' (file not found)'
                    ret = 0
                else:
                    print '(%x)' % fdn
                    fds[fdn] = g
                    ret = fdn
                    fdn += 1
        else:
            print '(%s doesn\'t exist)' % path
            ret = 0
        f.write(struct.pack('>I', ret))
    elif i == chr(0x14):
        args = struct.unpack('>III', f.read(12))
        cfd, ignore, size = args
        print 'ES_ReadContentFile(0x%x, 0x%x, 0x%x)' % args
        if cfd > 0x10000:
            print f.read(1)
            try:
                g = fds[cfd]
            except KeyError:
                print '! Invalid FD'
                f.write('\x00' * (size + 4))
            else:
                print 'reading it myself:'
                blob = g.read(size)
                sys.stdout.write('I have a %d-char blob.  writing' % len(blob))
                sys.stdout.flush()
                xwrite(blob)
                f.write(struct.pack('>I', len(blob)))
    elif i == chr(0x15):
        args = struct.unpack('>III', f.read(12))
        cfd, where, whence = args
        print 'ES_SeekContentFile(0x%x, 0x%x, 0x%x)' % args
        if cfd > 0x10000:
            print f.read(1)
            try:
                g = fds[cfd]
            except KeyError:
                print '! Invalid FD'
                f.write('\x00' * 4)
            else:
                print 'f.seek(%d, %d)' % (where, whence)
                g.seek(where, whence)
                ret = 0
                f.write(struct.pack('>I', ret))
    elif i == chr(0x16):
        cfd, = struct.unpack('>I', f.read(4))
        print 'ES_CloseContentFile(0x%x)' % cfd
        if cfd > 0x10000:
            print f.read(1)
            print hex(struct.unpack('>I', f.read(4))[0])
            try:
                g = fds[cfd]
            except KeyError:
                print '! Invalid FD'
            else:
                g.close()

            ret = 1
            f.write(struct.pack('>I', ret))            
    elif i == chr(0x17):
        sz, = struct.unpack('>I', f.read(4))
        #print '%% %s' % f.read(sz),
        q = 0
        msg = ''
        while q < sz:
            c = f.read(1)
            if c == chr(0xff): break
            msg += c
            q += 1
            
        sys.stdout.write(msg)
    elif i == chr(0xff):
        #print 'SPAM'
        pass
    else:
        print hex(ord(i)), ' ',

