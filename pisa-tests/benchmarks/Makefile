default: all

bmarkdir = .

instname = pisa-bmarks
instbasedir = $(PISA_INSTALL)/install

#--------------------------------------------------------------------
# Sources
#--------------------------------------------------------------------

bmarks = \
	add_int \
	add_fp \
	hello_world \
	reduce_array \

bmarks_host = \
	add_int \
	add_fp \
	hello_world \
	reduce_array \

#--------------------------------------------------------------------
# Build rules
#--------------------------------------------------------------------

HOST_OPTS = -std=gnu99 -DPREALLOCATE=0 -DHOST_DEBUG=1
HOST_COMP = gcc $(HOST_OPTS)

PISA_GCC = /afs/bp.ncsu.edu/dist/simplescalar/tools/bin/sslittle-na-sstrix-gcc
PISA_GCC_OPTS = -static -std=gnu99 -O2 
PISA_LINK = $(PISA_GCC) $(incs)
#PISA_LINK_OPTS = -nostdlib -nostartfiles -ffast-math -lc
PISA_LINK_OPTS = -lc 
PISA_OBJDUMP = /afs/bp.ncsu.edu/dist/simplescalar/tools/bin/sslittle-na-sstrix-objdump -d

VPATH += $(addprefix $(bmarkdir)/, $(bmarks))

incs  += $(addprefix -I$(bmarkdir)/, $(bmarks))
objs  :=

include $(patsubst %, $(bmarkdir)/%/bmark.mk, $(bmarks))

#------------------------------------------------------------
# Build and run benchmarks on pisa simulator

bmarks_pisa_install  = $(foreach bmk,$(bmarks),$(bmk)_pisa)
bmarks_pisa_bin  = $(addsuffix .pisa,  $(foreach bmk,$(bmarks),$(bmk)/$(bmk)))
bmarks_pisa_dump = $(addsuffix .pisa.dump, $(foreach bmk,$(bmarks),$(bmk)/$(bmk)))
bmarks_pisa_hex  = $(addsuffix .pisa.hex, $(foreach bmk,$(bmarks),$(bmk)/$(bmk)))
bmarks_pisa_out  = $(addsuffix .pisa.out,  $(foreach bmk,$(bmarks),$(bmk)/$(bmk)))

.PHONY: $(bmarks_pisa_install)
$(bmarks_pisa_install): %: %_install;

$(bmarks_pisa_dump): %.pisa.dump: %.pisa
	$(PISA_OBJDUMP) $< > $@

%.o: %.c
	$(PISA_GCC) $(PISA_GCC_OPTS) $(bmarks_defs) \
	             -c $(incs) $< -o $@

%.o: %.S
	$(PISA_GCC) $(PISA_GCC_OPTS) $(bmarks_defs) -D__ASSEMBLY__=1 \
	             -c $(incs) $< -o $@

pisa: $(bmarks_pisa_dump) $(bmarks_pisa_install) 
run-pisa: $(bmarks_pisa_out)
	echo; perl -ne 'print "  [$$1] $$ARGV \t$$2\n" if /\*{3}(.{8})\*{3}(.*)/' \
	       $(bmarks_pisa_out); echo;

junk += $(bmarks_pisa_bin) $(bmarks_pisa_dump) $(bmarks_pisa_hex) $(bmarks_pisa_out)

#------------------------------------------------------------
# Build and run benchmarks on host machine

bmarks_host_bin = $(addsuffix .host, $(foreach bmk,$(bmarks_HOST),$(bmk)/$(bmk)))
bmarks_host_out = $(addsuffix .host.out, $(foreach bmk,$(bmarks_HOST),$(bmk)/$(bmk)))

$(bmarks_host_out): %.host.out: %.host
	./$< > $@

host: $(bmarks_host_bin)
run-host: $(bmarks_host_out)
	echo; perl -ne 'print "  [$$1] $$ARGV \t$$2\n" if /\*{3}(.{8})\*{3}(.*)/' \
	       $(bmarks_host_out); echo;

junk += $(bmarks_host_bin) $(bmarks_host_out)

#------------------------------------------------------------
# Default

all: pisa

install: install-bin

#------------------------------------------------------------
# Install

date_suffix = $(shell date +%Y-%m-%d_%H-%M)
install_dir = $(instbasedir)/$(instname)-$(date_suffix)
latest_install = $(shell ls -1 -d $(instbasedir)/$(instname)* | tail -n 1)

install-bin:
	mkdir $(install_dir)
	cp -r $(bmarks_pisa_bin) $(bmarks_pisa_dump) $(install_dir)

install-link: install-bin
	rm -rf $(instbasedir)/$(instname)
	ln -s $(latest_install) $(instbasedir)/$(instname)

#------------------------------------------------------------
# Clean up

clean:
	rm -rf $(objs) $(junk)
