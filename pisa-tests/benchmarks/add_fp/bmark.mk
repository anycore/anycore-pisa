add_fp_c_src = \
	add_fp.c \

add_fp_pisa_src = \

add_fp_run_files = \

add_fp_c_objs     = $(patsubst %.c, add_fp/%.o, $(add_fp_c_src))
add_fp_pisa_objs = $(patsubst %.S, add_fp/%.o, $(add_fp_pisa_src))

add_fp_pisa_bin = add_fp/add_fp.pisa
$(add_fp_pisa_bin) : $(add_fp_c_objs) $(add_fp_pisa_objs)
	$(PISA_LINK) $(add_fp_c_objs) $(add_fp_pisa_objs) -o $(add_fp_pisa_bin) $(PISA_LINK_OPTS)

.PHONY: add_fp_pisa_install
add_fp_pisa_install: $(add_fp_pisa_bin)
	mkdir -p add_fp/install
	cp -f $(add_fp_pisa_bin) $(add_fp_run_files) add_fp/install

junk += $(add_fp_c_objs) $(add_fp_pisa_objs) \
        $(add_fp_pisa_bin) add_fp/install
