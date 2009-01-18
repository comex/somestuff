#include <string.h>
void *memset(void *s, int c, size_t n) {
    char *p = s;
    while(n-- > 0) {
        *(p++) = (char) c;
    }
    return s;
}
size_t strlen(const char *s) {
    size_t len = 0;
    while(*(s++) != 0) len++;
    return len;
}