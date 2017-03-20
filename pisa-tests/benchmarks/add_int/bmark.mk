add_int_c_src = \
	add_int.c \

add_int_pisa_src = \

add_int_run_files = \

add_int_c_objs     = $(patsubst %.c, add_int/%.o, $(add_int_c_src))
add_int_pisa_objs = $(patsubst %.S, add_int/%.o, $(add_int_pisa_src))

add_int_pisa_bin = add_int/add_int.pisa
$(add_int_pisa_bin) : $(add_int_c_objs) $(add_int_pisa_objs)
	$(PISA_LINK) $(add_int_c_objs) $(add_int_pisa_objs) -o $(add_int_pisa_bin) $(PISA_LINK_OPTS)

.PHONY: add_int_pisa_install
add_int_pisa_install: $(add_int_pisa_bin)
	mkdir -p add_int/install
	cp -f $(add_int_pisa_bin) $(add_int_run_files) add_int/install

junk += $(add_int_c_objs) $(add_int_pisa_objs) \
        $(add_int_pisa_bin) add_int/install
