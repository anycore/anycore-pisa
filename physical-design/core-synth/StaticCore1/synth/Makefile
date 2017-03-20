ANYCORE_BASE_DIR		=	$(realpath $(CURDIR)/../../../..)
RTL_DIR   	=	$(realpath ${ANYCORE_BASE_DIR}/src)
SCRIPT_DIR	=	$(realpath ${ANYCORE_BASE_DIR}/physical-design/core-synth/scripts)
HOOKS_DIR		=	$(realpath ${CURDIR}/../hooks)
RUN_ID			= 1
CONFIG_FILE = StaticCore1.v
CLK_PERIOD  = 4.0
WRITE_SDF   = 1

$(info ANYCORE_BASE_DIR="${ANYCORE_BASE_DIR}")

RAMGEN_DIR 	= 	$(realpath $(ANYCORE_BASE_DIR)/physical-design/ramgen/FabMem)
RAM_NAMES		= 	PRF_RAM_RPORT6_WPORT3_DEPTH160_INDEX8_WIDTH64	\
								BTB_RAM_RPORT1_WPORT1_DEPTH1024_INDEX1_WIDTH2

RAM_CELLS		=	 	$(patsubst %,$(RAMGEN_DIR)/libs/ram/%.v,$(RAM_NAMES))
ram_db 			= 	$(patsubst %,$(RAMGEN_DIR)/libs/ram/%_typ.db,$(RAM_NAMES))
#ram_db 			= 	$(patsubst %,$(RAMGEN_DIR)/libs/ram/%_typ.db,$(RAM_NAMES))


$(ram_db): $(RAMGEN_DIR)/libs/ram/%_typ.db: 
	$(eval RPORT:= $(shell perl -e 'my $$name=$*; $$name =~ m/.*RPORT(\d+)_.*/; print $$1'))
	$(eval WPORT:= $(shell perl -e 'my $$name=$*; $$name =~ m/.*WPORT(\d+)_.*/; print $$1'))
	$(eval DEPTH:= $(shell perl -e 'my $$name=$*; $$name =~ m/.*DEPTH(\d+)_.*/; print $$1'))
	$(eval INDEX:= $(shell perl -e 'my $$name=$*; $$name =~ m/.*INDEX(\d+)_.*/; print $$1'))
	$(eval WIDTH:= $(shell perl -e 'my $$name=$*; $$name =~ m/.*WIDTH(\d+)/; print $$1'))
	make -C $(RAMGEN_DIR) CELL_NAME=$* RPORT=$(RPORT) WPORT=$(WPORT) DEPTH=$(DEPTH) INDEX=$(INDEX) WIDTH=$(WIDTH) libgen_ram

.PHONY: ramlib
ramlib: $(ram_db)

clean:
	rm -f *.syn; rm -f *.svf; rm -f *.pvl; rm -f *.mr; rm -f *.log; rm -f encounter.*; rm -rf alib-52; rm -f work/*;rm -f synth.tcl

purge:
	rm -rf netlist reports work

synth: $(ram_db)
	mkdir -p reports netlist work
	make clean
	echo "set ADDITIONAL_LIBRARIES \"$(ram_db)\""		>  	$(HOOKS_DIR)/Pre_Setup_Hook.tcl
	echo "set CLK_PER $(CLK_PERIOD)"                >>	$(HOOKS_DIR)/Pre_Setup_Hook.tcl
	echo "set WRITE_SDF $(WRITE_SDF)"               >>	$(HOOKS_DIR)/Pre_Setup_Hook.tcl
	echo "set HOOKS_DIR $(HOOKS_DIR)"								> 	synth.tcl
	echo "set RTL_DIR   $(RTL_DIR)"									>>	synth.tcl
	echo "set CONFIG_FILE $(CONFIG_FILE)"						>>	synth.tcl
	echo "source ${SCRIPT_DIR}/Setup.tcl"						>>	synth.tcl
	echo "set RUN_ID $(RUN_ID)"											>>  synth.tcl
	echo "source $(SCRIPT_DIR)/Read_Design.tcl"			>>	synth.tcl
	echo "source ${SCRIPT_DIR}/Constraints.tcl"			>>	synth.tcl
	echo "source ${SCRIPT_DIR}/CompileAnalyze.tcl"	>>	synth.tcl
	tcsh -c 'add synopsys2015 && dc_shell -64bit -f synth.tcl	|	tee synth.log'

pt:
	echo "set HOOKS_DIR $(HOOKS_DIR)"								> 	pt.tcl
	echo "set RTL_DIR  $(RTL_DIR)"									>>	pt.tcl
	echo "set CONFIG_FILE $(CONFIG_FILE)"						>>	pt.tcl
	echo "source ${SCRIPT_DIR}/Setup.tcl"						>>	pt.tcl
	echo "source ${SCRIPT_DIR}/run_pt.tcl"   				>>	pt.tcl
	tcsh -c 'add synopsys2015 && pt_shell -64bit -f pt.tcl  | tee pt.log'

ptpx:
	mkdir -p reports
	echo "set HOOKS_DIR $(HOOKS_DIR)"								> 	ptpx.tcl
	echo "set RTL_DIR  $(RTL_DIR)"									>>	ptpx.tcl
	echo "set CONFIG_FILE $(CONFIG_FILE)"						>>	ptpx.tcl
	echo "set USE_ACTIVITY_FILE 1"									>> 	ptpx.tcl
	echo "source $(SCRIPT_DIR)/Setup.tcl"						>>	ptpx.tcl
	echo "set RUN_ID $(RUN_ID)"											>>  ptpx.tcl
	echo "source $(SCRIPT_DIR)/run_ptpx.tcl"				>>	ptpx.tcl
	tcsh -c 'add synopsys2015 && pt_shell -f ptpx.tcl  | tee ptpx.log'

