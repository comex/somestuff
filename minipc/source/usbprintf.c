#include "miniexi.h"
#include <stdarg.h>
#include <stdio.h>
#include <string.h>
#define _SHIFTL(v, s, w)        \
    ((u32) (((u32)(v) & ((0x01 << (w)) - 1)) << (s)))
#define _SHIFTR(v, s, w)        \
    ((u32)(((u32)(v) >> (s)) & ((0x01 << (w)) - 1)))


#define usbprintf_bufsize 16384

#ifdef DEBUG_MINIPC
void usbprintf(const char *format, ...) {
	va_list args;
	va_start(args, format);
	char stuff[usbprintf_bufsize];
	vsnprintf(stuff, usbprintf_bufsize, format, args);
	va_end(args);
	//usb_sendbuffer_safe(1, stuff, strlen(stuff));
	exisendbuffer(strlen(stuff), stuff);
}
#endif

void usbprint(const char *format, ...) {
    
	exisendbuffer(strlen(format), format);
}
