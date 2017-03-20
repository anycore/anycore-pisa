GLOBAL_SCRIPT_DIR_SWITCH_ACTIVITY	=	"${CURDIR}/../../../scripts"
LOCAL_SCRIPT_DIR_SWITCH_ACTIVITY	=	"${CURDIR}/../../scripts"
#
#
#
## MAKE CHANGES HERE #
##
## setup name of the clock in your design.
#CLKNAME = clk
#
## set variable "modname" to the name of topmost module in design
#MODNAME = Decode
##
## # set variable "RTL_DIR" to the HDL directory w.r.t synthesis directory
#RTL_DIR =  "../../src/"
##
## # set variable "GLOBAL_SCRIPT_DIR" that has the main synthesis scripts
##
## # set variable "type" to a name that distinguishes this synthesis run
##
#CLK_PER = 4
#CLK_SKEW = 0.04
##
RUN_ID = 1

# MAKE CHANGES HERE #

run:
	mkdir -p reports netlist work; make clean
	tcsh -c 'add synopsys_new && dc_shell -64bit -f $(LOCAL_SCRIPT_DIR)/synthesis.tcl | tee synth.log'

pwr:
	mkdir -p reports work; 
	tcsh -c 'add synopsys_new && dc_shell -64bit -f $(LOCAL_SCRIPT_DIR)/power.tcl | tee pwr.log'

clean:
	rm -f *.syn; rm -f *.svf; rm -f *.pvl; rm -f *.mr; rm -f *.log; rm -f encounter.*; rm -rf alib-52; rm -f work/*;rm -f synthesis_new.tcl ptpx.tcl pt.tcl primetime_px.fsdb

purge:
	rm -rf netlist reports work

run_new:
	mkdir -p reports netlist work
	make clean
	echo "set LOCAL_SCRIPT_DIR $(LOCAL_SCRIPT_DIR)"					> synthesis_new.tcl
	echo "source $(LOCAL_SCRIPT_DIR)/setup_local.tcl"				>>  	synthesis_new.tcl
	echo "source \$${GLOBAL_SCRIPT_DIR}/setup.tcl"					>>	synthesis_new.tcl
	echo "source $(LOCAL_SCRIPT_DIR)/read_local.tcl"				>>	synthesis_new.tcl
	echo "source \$${GLOBAL_SCRIPT_DIR}/Constraints.tcl"		>>	synthesis_new.tcl
	echo "source \$${GLOBAL_SCRIPT_DIR}/CompileAnalyze.tcl"	>>	synthesis_new.tcl
	tcsh -c 'add synopsys2013 && dc_shell -64bit -f synthesis_new.tcl	|	tee synth.log'
	#tcsh -c 'add synopsys_new && dc_shell -f synthesis_new.tcl	|	tee synth.log'

pt:
	echo "set LOCAL_SCRIPT_DIR $(LOCAL_SCRIPT_DIR)"					> pt.tcl
	echo "source $(LOCAL_SCRIPT_DIR)/setup_local.tcl"										>>  	pt.tcl
	echo "source \$${GLOBAL_SCRIPT_DIR}/setup.tcl"						>>	pt.tcl
	echo "source \$${GLOBAL_SCRIPT_DIR}/run_pt.tcl"	>>	pt.tcl
	tcsh -c 'add synopsys2013 && pt_shell -f pt.tcl  | tee pt.log'

ptpx:
	mkdir -p reports
	echo "set LOCAL_SCRIPT_DIR $(LOCAL_SCRIPT_DIR_SWITCH_ACTIVITY)"					> ptpx.tcl
	echo "set USE_ACTIVITY_FILE 1"					>> ptpx.tcl
	echo "source $(LOCAL_SCRIPT_DIR_SWITCH_ACTIVITY)/setup_local.tcl"				>>  	ptpx.tcl
	echo "set GLOBAL_SCRIPT_DIR $(GLOBAL_SCRIPT_DIR_SWITCH_ACTIVITY)"				>>  	ptpx.tcl
	echo "source $(GLOBAL_SCRIPT_DIR_SWITCH_ACTIVITY)/setup.tcl"					>>	ptpx.tcl
	echo "source $(GLOBAL_SCRIPT_DIR_SWITCH_ACTIVITY)/run_ptpx.tcl"	>>	ptpx.tcl
	tcsh -c 'add synopsys2013 && pt_shell -64bit -f ptpx.tcl  | tee ptpx.log'
	tcsh -c '../../scripts/stat_pow_rep reports/power_ptpx_FABSCALAR_$(RUN_ID).rpt >! reports/power_$(RUN_ID).csv'

