The gbalzss.c modifikation compiles easy under most un*xes
and under win32

I included a win32 binary and you can just compile it under linux with
gcc -o gbalzss gbalzss.c


Compress your data using this program

./gbalzss e data.raw compressed-data.raw

If you need to decompress a compressed file on console
sometimes you can use:

./gbalzss d compressed-data.raw data.raw

IMPORTANT:
Be SURE to align the compressed data to a 4 byte boundary
Or the BIOS function will probably not work on it
Heres an example how to align your data using gcc compiler,
if you include it as C const array:

const u8 compressed[4808]__attribute__ ((aligned (4))) = {

Include or link it to your program then feed it to BIOS function 11h


credits: as you can see this is based upon Haruhiko Okumura's
original lzss code so thanks :)

Also tribute to gbadev.org & cowbite & no$gba's gbatek without those I couldnt
do much on gba :p

If you have questions, drop me a mail
Andre Perrot <ovaron@gmx.net>
