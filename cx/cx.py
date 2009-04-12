import sys, os
f = open(sys.argv[1], 'rb')
z = f.read()
f.close()
tofind = '80e300003903000488030000'.decode('hex')
y = z.find(tofind)
assert z.find(tofind, y+1) == -1
y2 = z.find('4e800020'.decode('hex'), y)
st = z[y:y2+4]
assert len(st) % 4 == 0
st2 = ''
for i in st:
    st2 += '\\x' + i.encode('hex')
g = open('out.c', 'wb')
g.write('''
#include <stdio.h>
#include <stdlib.h>
#include <malloc.h>
int main() {
    char *x = "%s";
    char *input, *output;
    int len = 1024;
    input = (char *) malloc(len);
    char *ptr = input;
    int c;
    while((c = getchar()) != EOF) {
        printf("read\\n");
        *ptr++ = (char) c;
        if((ptr - input) >= len) {
            len *= 2;
            input = realloc(input, len);
        }
    }
    output = malloc(1048576);
    printf("ok\\n");
    ((void(*)(char*, char*)) x)(input, output);
    printf("%%s\\n", output);
}
''' % st2)

