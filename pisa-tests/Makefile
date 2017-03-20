## Important paths
#This is where all tests are run
SCRATCH_SPACE 		= /home/rbasuro/anycore_pisa_scratch
#Path to the SPEC directory
SPEC_CHKPT_DIR 		= /afs/eos.ncsu.edu/lockers/research/ece/ericro/common/benchmarks/pisa/spec2k/checkpoint

## Various paths used in testcases
ANYCORE_TEST_DIR 	= $(PWD)
ANYCORE_BASE_DIR 	= $(realpath $(ANYCORE_TEST_DIR)/..)
VERILOG_SRC_DIR	 	= $(ANYCORE_BASE_DIR)/src
SYNTH_BASE_DIR 	 	= $(ANYCORE_BASE_DIR)/physical-design
FUNCSIM_DIR       = $(ANYCORE_BASE_DIR)/functional-sim

## Following are the run directories for the various testcases
BMARK_SRC_DIR 		= $(ANYCORE_TEST_DIR)/benchmarks
BMARK_BUILD_DIR 	= $(SCRATCH_SPACE)/anycore_bmark_build
RTL_TEST_DIR 			= $(SCRATCH_SPACE)/anycore_rtl_test
GATE_TEST_DIR 		= $(SCRATCH_SPACE)/anycore_gate_test

# Set to POWER=1 for Prime Time power analysis of gate sims
POWER = 0

## Testcases are a combination of benchmark name and configuration 
## to be used for the run. Any combination can be specified in the
## following way: BENCHMARK_NAME+CONFIGURATION

## Testcases for RTL simulations
all_rtl_tests =	\
				hello_world+StaticCore1	\
				reduce_array+StaticCore1	\
				hello_world+StaticCore2	\
				reduce_array+StaticCore2	\

all_rtl_spec_tests =	\
				bzip+StaticCore1+3089	\
				bzip+StaticCore2+3089	\
				#gap+StaticCore1 \
				gzip+StaticCore1 \
				mcf+StaticCore1 \
				parser+StaticCore1 \
				vortex+StaticCore1 \

## Testcases for gate-level simulations
all_gate_tests =	\
				hello_world+StaticCore1	\
				#reduce_array+StaticCore1	\

all_gate_spec_tests =	\
				#bzip+StaticCore1+4060	\
				#gap+StaticCore1 \
				gzip+StaticCore1 \
				mcf+StaticCore1 \
				parser+StaticCore1 \
				vortex+StaticCore1 \

rtl_tests 	= $(addprefix rtl+,$(patsubst \,,$(all_rtl_tests)))
rtl_spec_tests 	= $(addprefix rtl+,$(patsubst \,,$(all_rtl_spec_tests)))
gate_tests 	= $(addprefix gate+,$(patsubst \,,$(all_gate_tests)))
gate_spec_tests 	= $(addprefix gate+,$(patsubst \,,$(all_gate_spec_tests)))

.PHONY: all rtl spec $(rtl_tests) $(micro_tests) $(spec_tests)
all:	rtl
rtl_spec:	$(rtl_spec_tests) 
rtl:	$(rtl_spec_tests) $(rtl_tests) 
gate_spec:	$(gate_spec_tests) 
gate: $(gate_spec_tests) $(gate_tests)

.ONESHELL:


define rtl_test_rule
$(1):
	mkdir -p $(BMARK_BUILD_DIR)
	ln -sf $(BMARK_SRC_DIR)/Makefile $(BMARK_BUILD_DIR)/
	cd $(BMARK_BUILD_DIR);	$(ANYCORE_TEST_DIR)/scripts/lndir $(BMARK_SRC_DIR)/$(2);	cd $(ANYCORE_TEST_DIR)
	echo "BMARK_SRC_DIR = $(BMARK_SRC_DIR)/$(2)"
	echo "BMARK_BUILD_DIR = $(BMARK_BUILD_DIR)/$(2)"
	make -C $(BMARK_BUILD_DIR) bmarks=$(2)
	mkdir -p $(RTL_TEST_DIR)/$(subst +,/,$(1))
	cd $(RTL_TEST_DIR)/$(subst +,/,$(1));	\
	echo "RTL_TEST_DIR = $(shell pwd)";	\
	cp -f $(BMARK_SRC_DIR)/$(2)/job .;	\
	cp -f $(BMARK_SRC_DIR)/$(2)/config .;	\
	ln -sf $(BMARK_BUILD_DIR)/$(2)/install/* .;	\
	cp -f $(ANYCORE_TEST_DIR)/rtl.mk makefile;	\
	sed -i 's/CONFIG_PLACE_HOLDER/$(3)/g' makefile;	\
	sed -i 's:VERILOG_SRC_DIR_PLACE_HOLDER:$(VERILOG_SRC_DIR):g' makefile;	\
	sed -i 's:FUNCSIM_DIR_PLACE_HOLDER:$(FUNCSIM_DIR):g' makefile;	\
	csh -c 'add cadence2013; make -f makefile run_nc';	\
	cd $(ANYCORE_TEST_DIR)
endef

# Call the macro rtl_test_rule(testcase,benchmark,configuration,test_directory)  - No spaces between arguments
$(foreach testcase,$(rtl_tests),$(eval $(call rtl_test_rule,$(testcase),$(word 2,$(subst	+, ,$(testcase))),$(word 3,$(subst +, ,$(testcase))))))

define gate_test_rule
$(1):
	mkdir -p $(BMARK_BUILD_DIR)
	ln -sf $(BMARK_SRC_DIR)/Makefile $(BMARK_BUILD_DIR)/
	cd $(BMARK_BUILD_DIR);	$(ANYCORE_TEST_DIR)/scripts/lndir $(BMARK_SRC_DIR)/$(2);	cd $(ANYCORE_TEST_DIR)
	echo "BMARK_SRC_DIR = $(BMARK_SRC_DIR)/$(2)"
	echo "BMARK_BUILD_DIR = $(BMARK_BUILD_DIR)/$(2)"
	make -C $(BMARK_BUILD_DIR) bmarks=$(2)
	mkdir -p $(GATE_TEST_DIR)/$(subst +,/,$(1))
	cd $(GATE_TEST_DIR)/$(subst +,/,$(1));	\
	echo "GATE_TEST_DIR = $(shell pwd)";	\
	cp -f $(BMARK_SRC_DIR)/$(2)/job .;	\
	cp -f $(BMARK_SRC_DIR)/$(2)/config .;	\
	ln -sf $(BMARK_BUILD_DIR)/$(2)/install/* .;	\
	cp -f $(ANYCORE_TEST_DIR)/gate.mk makefile;	\
	sed -i 's/CONFIG_PLACE_HOLDER/$(3)/g' makefile;	\
	sed -i 's:SYNTH_BASE_DIR_PLACE_HOLDER:$(SYNTH_BASE_DIR):g' makefile;	\
	sed -i 's:VERILOG_SRC_DIR_PLACE_HOLDER:$(VERILOG_SRC_DIR):g' makefile;	\
	sed -i 's:FUNCSIM_DIR_PLACE_HOLDER:$(FUNCSIM_DIR):g' makefile;	\
	csh -c 'add cadence2013; make -f makefile run_nc';	\
	cd $(ANYCORE_TEST_DIR)
	if [ "$(POWER)" = "1" ]; then
		cd $(GATE_TEST_DIR)/$(subst +,/,$(1));	\
		csh -c 'add synopsys2015; make -f makefile vcd && make -f makefile ptpx';	\
		cd $(ANYCORE_TEST_DIR)
	fi
endef

# Call the macro rtl_test_rule(testcase,benchmark,configuration,test_directory)  - No spaces between arguments
$(foreach testcase,$(gate_tests),$(eval $(call gate_test_rule,$(testcase),$(word 2,$(subst	+, ,$(testcase))),$(word 3,$(subst +, ,$(testcase))))))


define rtl_spec_test_rule
$(1):
	echo "BMARK_BIN_DIR = $(SPEC_CHKPT_DIR)/$(2)"
	mkdir -p $(RTL_TEST_DIR)/$(subst +,/,$(1))
	cd $(RTL_TEST_DIR)/$(subst +,/,$(1));	\
	echo "RTL_TEST_DIR = $(shell pwd)";	\
	ln -sf $(SPEC_CHKPT_DIR)/$(2)/* .;	\
	ln -sf $(SPEC_CHKPT_DIR)/$(2)/config.$(4) config; \
	cp -f $(ANYCORE_TEST_DIR)/rtl.mk makefile;	\
	sed -i 's/CONFIG_PLACE_HOLDER/$(3)/g' makefile;	\
	sed -i 's:VERILOG_SRC_DIR_PLACE_HOLDER:$(VERILOG_SRC_DIR):g' makefile;	\
	sed -i 's:FUNCSIM_DIR_PLACE_HOLDER:$(FUNCSIM_DIR):g' makefile;	\
	csh -c 'add cadence2013; make -f makefile run_nc';	\
	cd $(ANYCORE_TEST_DIR)
endef

# Call the macro spec_test_rule(testcase,benchmark,configuration,test_directory)  - No spaces between arguments
$(foreach testcase,$(rtl_spec_tests),$(eval $(call 	rtl_spec_test_rule,$(testcase),$(word 2,$(subst	+, ,$(testcase))),$(word 3,$(subst +, ,$(testcase))),$(word 4,$(subst +, ,$(testcase))))))


define gate_spec_test_rule
$(1):
	echo "BMARK_BIN_DIR = $(SPEC_CHKPT_DIR)/$(2)"
	mkdir -p $(GATE_TEST_DIR)/$(subst +,/,$(1))
	cd $(GATE_TEST_DIR)/$(subst +,/,$(1));	\
	echo "RTL_TEST_DIR = $(shell pwd)";	\
	ln -sf $(SPEC_CHKPT_DIR)/$(2)/* .;	\
	ln -sf $(SPEC_CHKPT_DIR)/$(2)/config.$(4) config; \
	cp -f $(ANYCORE_TEST_DIR)/rtl.mk makefile;	\
	sed -i 's/CONFIG_PLACE_HOLDER/$(3)/g' makefile;	\
	sed -i 's:SYNTH_BASE_DIR_PLACE_HOLDER:$(SYNTH_BASE_DIR):g' makefile;	\
	sed -i 's:VERILOG_SRC_DIR_PLACE_HOLDER:$(VERILOG_SRC_DIR):g' makefile;	\
	sed -i 's:FUNCSIM_DIR_PLACE_HOLDER:$(FUNCSIM_DIR):g' makefile;	\
	csh -c 'add cadence2013; make -f makefile run_nc';	\
	cd $(ANYCORE_TEST_DIR)
	if [ "$(POWER)" = "1" ]; then
		cd $(GATE_TEST_DIR)/$(subst +,/,$(1));	\
		csh -c 'add synopsys2015; make -f makefile vcd && make -f makefile ptpx';	\
		cd $(ANYCORE_TEST_DIR)
	fi
endef

# Call the macro gate_spec_test_rule(testcase,benchmark,configuration,test_directory)  - No spaces between arguments
$(foreach testcase,$(gate_spec_tests),$(eval $(call 	gate_spec_test_rule,$(testcase),$(word 2,$(subst	+, ,$(testcase))),$(word 3,$(subst +, ,$(testcase))),$(word 4,$(subst +, ,$(testcase))))))

