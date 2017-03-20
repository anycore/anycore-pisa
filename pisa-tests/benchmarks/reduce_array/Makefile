PISA_GCC = /afs/bp.ncsu.edu/dist/simplescalar/tools/bin/sslittle-na-sstrix-gcc
PISA_OBJDUMP = /afs/bp.ncsu.edu/dist/simplescalar/tools/bin/sslittle-na-sstrix-objdump
compile = reduce_array

all: ${compile}

reduce_array: reduce_array.c
	$(PISA_COMPILER) -O1 -g -o reduce_array reduce_array.c

assembly: ${compile} 
	$(PISA_OBJDUMP) -dS reduce_array > assembly

clean:
	rm -f assembly reduce_array
