all: brute main.dol notdvdx.tmd notdvdx.tik
clean:
	rm -f main.dol main.o main brute notdvdx.tmd maintemp.bin notdvdx.tik 
main: main.S
	powerpc-gekko-cpp -D_LANGUAGE_ASSEMBLY -x assembler-with-cpp -I$(DEVKITPRO)/libogc/include main.S | powerpc-gekko-as -o main.o
	powerpc-gekko-ld -o main --section-start .text=0x80003400 main.o
brute: brute.c
	gcc -m32 -g -o brute -I$(DEVKITPRO)/libogc/include brute.c sha1.c
main.dol: main
	#elf2dol main maintemp.dol
	dd if=maintemp.dol of=main.dol bs=256 count=1
	powerpc-gekko-objcopy -O binary main maintemp.bin
	cat maintemp.bin >> main.dol
	python fixit.py
notdvdx.tmd: notdvdx_orig.tmd main.dol zero.app
	cp notdvdx_orig.tmd notdvdx.tmd
	python fixtmd.py
	./brute notdvdx.tmd 1
notdvdx.tik: notdvdx_orig.tik
	cp notdvdx_orig.tik notdvdx.tik
	./brute notdvdx.tik 0
install:
	mount-f
	wfcp main.dol ~/f/title/00010008/44564458/content/00000001.app
	wfcp zero.app ~/f/title/00010008/44564458/content/00000000.app
	wfcp notdvdx.tmd ~/f/title/00010008/44564458/content/title.tmd
	wfcp notdvdx.tik ~/f/ticket/00010008/44564458.tik
	umount-f
tarball:
	make clean
	bash -c 'cd installer; make clean'
	rm -f *~
	rm -f installer/*~
	rm -f installer/source/*~
	rm -f ../notdvdx.tar.bz2
	bash -c 'cd ..; tar cjvf notdvdx.tar.bz2 --exclude=.git notdvdx'
