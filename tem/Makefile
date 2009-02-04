all: pick-one

patches33u:
	powerpc-gekko-objdump -d exicrap | python evix.py '3.3u'
patches32e:
	powerpc-gekko-objdump -d exicrap | python evix.py '3.2e'
patches34u:
	powerpc-gekko-objdump -d exicrap | python evix.py '3.4u'

exicrap:
	powerpc-gekko-gcc -c -I/opt/dkp/devkitPPC/lib/gcc/powerpc-gekko/4.2.3/include -o exicrap.o exicrap.S
	powerpc-gekko-ld --section-start .init=0x80001c00 -o exicrap exicrap.o

exidump:
	powerpc-gekko-gcc -c -I/opt/dkp/devkitPPC/lib/gcc/powerpc-gekko/4.2.3/include -o exicrap.o exicrap.S
	powerpc-gekko-objdump -d exicrap.o
