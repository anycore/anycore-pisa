## Default values - Can be overridded by Pre_Setup_Hool.tcl
# setup name of the clock in your design.
set clkname clk

# set variable "modname" to the name of topmost module in design
set MODNAME FABSCALAR

set PARAM_FILE "configs/${CONFIG_FILE}"

# set variable "RTL_DIR" to the HDL directory w.r.t synthesis directory
#set RTL_DIR  "${BASE_DIR}/anycore-riscv-src"

# set variable "type" to a name that distinguishes this synthesis run
set RUN_ID 1

set CLK_PER 0.50

set CLK_SKEW 0.04

set CLK_GATE 0

set MULTI_CORNER 0

set WRITE_SDF 0

set WRITE_VERILOG_NETLIST 1

set USE_SAIF 0

set SAIF_DIR    ../SIMULATION

set SAIF_FILE ../SIMULATION/${MODNAME}.saif

set ADDITIONAL_LIBRARIES ""

set WRITE_SDC 0

set USE_VCD 0

set VCD_DIR     ../SIMULATION

set VCD_INST simulate/fabScalar

set VCD_FILE waves.vcd

set PR_DIR     ../PR/output/

# directory for generated reports 
set REPORT_DIR    "reports"

# directory for generated netlists
set NETLIST_DIR   "netlist"

#set the number of digits to be used for delay results
set report_default_significant_digits 4

set PATHS_TO_REPORT 50

# set the number of cores to use
set_host_options -max_cores 4

# Signed to unsigned conversion warning for loop indices
suppress_message VER-318

suppress_message UID-401

suppress_message UPF-281

# %s conflicts with %s in the target library
suppress_message OPT-106
suppress_message OPT-170

#suppress_message OPT-319

# '*' inherited license information from design 'DW_cmp'
suppress_message DDB-74

set FILE_EXISTS [file exists ${HOOKS_DIR}/Pre_Setup_Hook.tcl]
#if { $FILE_EXISTS == 1 } {
if { [file exists ${HOOKS_DIR}/Pre_Setup_Hook.tcl] } {
 source ${HOOKS_DIR}/Pre_Setup_Hook.tcl
}

# Set the search path for DC to find the verilog sources
set verilog_search_path "$RTL_DIR/"
set search_path         [concat  $verilog_search_path $search_path]

#---------------------------------------------------------
# Input and Output Delay values for timing checks
#---------------------------------------------------------
# ASSUME being driven by a slowest D-flip-flop         
# ASSUME driving a slowest D-flip-flop         
# NOTE: THESE ARE INITIAL ASSUMPTIONS ONLY             

# EX: 50um M3 has R of 178.57 Ohms and C of 12.5585fF. 0.69RC = 1.55ps, and wire load
# of 50um M3 is 13fF. Therefore, roughly 20ps wire delay is assumed.                
set WIRE_DELAY 0.02
set MAX_INS_DELAY 1.0

# From .lib file
# For FreePDK 45nm
# Maximum cell delay
set DFF_CKQ 0.258596

# Half of Maximum setup time
set DFF_SETUP 0.070000

set IP_DELAY [expr $WIRE_DELAY + $DFF_CKQ]
set OP_DELAY [expr $WIRE_DELAY + $DFF_SETUP]

#---------------------------------------------------------	
# ASSUME being driven by a D-flip-flop                 
#---------------------------------------------------------
# For FreePDK 45 nm libraries
set DR_CELL_NAME DFFR_X1
set DR_CELL_PIN  Q

 set DR_CELL_PIN  Q

#---------------------------------------------------------
# Output load on ports is assumed to be FO4 D-flip-flop
#---------------------------------------------------------
 
# For FreePDK 45 nm libraries
set PORT_LOAD_CELL DFFR_X1/D

#---------------------------------------------------------
# Set simpler names for the different libraries
#---------------------------------------------------------
# If using FreePDK45 libraries
#set lib_path "/afs/eos.ncsu.edu/lockers/research/ece/wdavis/tech/nangate/NangateOpenCellLibrary_PDKv1_3_v2010_12/Front_End/Liberty/CCS"
#set power_lib_path "/afs/eos.ncsu.edu/lockers/research/ece/wdavis/tech/nangate/NangateOpenCellLibrary_PDKv1_3_v2010_12/Low_Power/Front_End/Liberty/CCS" 
set lib_path "/home/rbasuro/NangateOpenCellLibrary_PDKv1_3_v2010_12/Front_End/Liberty/CCS"
set power_lib_path "/home/rbasuro/NangateOpenCellLibrary_PDKv1_3_v2010_12/Low_Power/Front_End/Liberty/CCS" 
  
set techlib_slow    "NangateOpenCellLibrary_slow_ccs.db LowPowerOpenCellLibrary_slow_ccs.db"
set techlib_typical "NangateOpenCellLibrary_typical_ccs.db LowPowerOpenCellLibrary_typical_ccs.db"
set techlib_fast    "NangateOpenCellLibrary_fast_ccs.db LowPowerOpenCellLibrary_fast_ccs.db"


#---------------------------------------------------------
# Search Path variables  
#---------------------------------------------------------

set current_dir_path "./"
set search_path "$current_dir_path $lib_path $power_lib_path $search_path";

set search_path [concat  $search_path [list [format "%s%s"  $synopsys_root "/libraries/syn"]]]
set search_path [concat  $search_path [list "." [format "%s%s"  $synopsys_root "/dw/sim_ver"]]]

#---------------------------------------------------------
# Set the synthetic library variable to enable use of 
# desigware blocks
#---------------------------------------------------------
 set synthetic_library [list dw_foundation.sldb]
 
#---------------------------------------------------------
# Specify the worst case (slowest) libraries and       
# slowest temperature/Vcc conditions                   
# This would involve setting up the slow library as the 
# target and setting the link library to the conctenation
# of the target and the synthetic library
#---------------------------------------------------------
if {$MULTI_CORNER == 1} {
 set target_library $techlib_slow
} else {
 set target_library $techlib_typical
}

# ADDITIONAL_LIBRARIES is design specific and set in the design specific setup file
set link_library   [concat "*" $target_library $synthetic_library $ADDITIONAL_LIBRARIES]

# Don't use always on cells
set_dont_use LowPowerOpenCellLibrary/AON* 
set_dont_touch LowPowerOpenCellLibrary/AON* 

set verilogout_no_tri "true"
