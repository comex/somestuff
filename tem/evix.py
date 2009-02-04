import sys, re, struct, random, md5
from UserString import MutableString
blob = ''
func_locs = {}
for i in sys.stdin:
    i = i.rstrip()
    m = re.match('^([0-9a-zA-Z]+) <([a-zA-Z0-9_-]+)>:$', i)
    if m:
        func_locs[m.group(2)] = int(m.group(1), 16)
    if re.match('^8[a-zA-Z0-9]+:', i):
        #print i
        hx = re.split('(\s{2,}|\t)', i.strip())[2]
        #print hx
        for i in re.findall('[0-9a-zA-Z]{2}', hx):
            #print i
            blob += chr(int(i, 16))
def print_hf(x, print_it=True):
    global hf
    hf.write(x)
    if print_it:
        sys.stdout.write(x)
def get_jump(pos, mode=0): # pos from zero
    if mode == 0:
	   return '\x3c\x00\x80\x00\x60\x00' + struct.pack('>H', pos - 0x80000000) + '\x7c\x09\x03\xa6\x4e\x80\x04\x20'
        # lis / ori / mtctr / bctr
    elif mode == 1:
        return '\x7c\xe8\x02\xa6\x3c\x00\x80\x00\x60\x00' + struct.pack('>H', pos - 0x80000000) + '\x7c\x08\x03\xa6\x4e\x80\x00\x21'
    elif mode == 2:
        return '\xff' * 16
    else:
        raise '?'
def store_stuff(mem_loc, shit, print_it=True):
    if len(shit) % 4 != 0:
        raise 'haha not implemented'
    randi = 'bt_' + md5.md5(str(random.random())).hexdigest()[:10]
    print_hf('\tu32 %s[] = {\n' % randi, print_it)
    for i in xrange(0, len(shit), 4):
        num, = struct.unpack('>I', shit[i:i+4])
        print_hf('\t\t0x%08x%s\n' % (num, '' if i == len(shit) - 4 else ','), print_it)
    print_hf('\t};\n', print_it)
    print_hf('\tnstomem(0x%08x, %d, %s);\n' % (mem_loc, len(shit) / 4, randi), print_it)

def store_jump(mem_loc, name, mode=0):
    store_stuff(mem_loc, get_jump(func_locs[name], mode))

mx = 0x2ff0 - 0x1c00
print 'blob len is %d / %d' % (len(blob), mx)
if len(blob) >= max: sys.exit(1)
zf = open('blob.txt', 'wb')
zf.write(blob)
zf.close()
hf = open('/usr/src/b/tem/menu/source/patches.c', 'w')
print_hf('''
#include <gccore.h>
#include <stdarg.h>
#include <stdio.h>
static void nstomem(u32 addr, int len, u32 *ar) {
	u32 *ptr = (u32 *) addr;
	u32 x;
	int n; for(n = 0; n < len; n++) {
		x = ar[n];
		//printf("%08x: %08x --> %08x\\n", ptr, *ptr, x);
		*ptr = x;
		ptr++;
	}
	ICInvalidateRange((u32 *) addr, len * 4);
	DCFlushRange((u32 *) addr, len * 4);
    //sleep(1);
}\n''', False)
print_hf('void patches() {\n')
menus = {}
menus['3.3u'] = {
    'ES_OpenTitleContentFile': 0x81594974,
    'ES_ReadContentFile': 0x81594a0c,
    'ES_SeekContentFile': 0x81594aac,
    'ES_CloseContentFile': 0x81594b38,
}
menus['3.2e'] = {
    'ES_OpenTitleContentFile': 0x815941d8,
    'ES_ReadContentFile': 0x81594270,
    'ES_SeekContentFile': 0x81594310,
    'ES_CloseContentFile': 0x8159439c,
}
menus['3.4u'] = {
    'ES_OpenTitleContentFile': 0x8159e678,
    'ES_ReadContentFile': 0x8159e710,
    'ES_SeekContentFile': 0x8159e7b0,
    'ES_CloseContentFile': 0x8159e83c,
    '__FileWrite': 0x815df2a0
}
menu = menus[sys.argv[1]] #'3.2e']
store_jump(menu['ES_OpenTitleContentFile'], 'ES_OpenTitleContentFile_replacement', 1)
store_jump(menu['ES_ReadContentFile'], 'ES_ReadContentFile_replacement', 1)
store_jump(menu['ES_SeekContentFile'], 'ES_SeekContentFile_replacement', 1)
store_jump(menu['ES_CloseContentFile'], 'ES_CloseContentFile_replacement', 1)
#store_jump(menu['__FileWrite'], 'FileWrite_replacement', 1)
store_stuff(0x80001c00, blob, False)

print_hf('''
\t*((u32 *) 0x80002ff0) = 0;
\tDCFlushRange((void *) 0x80002ff0, 4);
}\n''')
