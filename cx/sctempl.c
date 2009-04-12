//NTSC: 80204fc8
#include <stdio.h>
#include <stdlib.h>
#include <malloc.h>
int main(int argc, char **argv) {
    if(argc != 2) {
        printf("Must have one argument\n");
        return 1;
    }
    int outsize = atoi(argv[1]);
    char *x = "<>";
    char *input, *output, *weird;
    int len = 1024;
    input = (char *) malloc(len);
    char *ptr = input;
    int c;
    while((c = getchar()) != EOF) {
        //printf("read\n");
        *ptr++ = (char) c;
        if((ptr - input) >= len) {
            len *= 2;
            input = realloc(input, len);
        }
    }
    output = calloc(1048576, 1);
    weird = calloc(1048576, 1);
    //printf("ok\n");
    printf("calling: %x %d %x %x 1\n", input, ptr - input, output, weird);
    int ret = ((int(*)(char*, int, char*, char*, int)) x)(input, ptr - input, output, weird, 1);
    printf("compressed size: %d\n", ret);
    fwrite(output, 1, outsize, stdout);
}
