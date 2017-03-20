#---------------------------------------------------------
# Our first Optimization 'compile' is intended to      
# produce a design that will meet hold-time            
# under worst-case conditions:                         
# 		- slowest process corner                        
# 		- highest operating temperature and lowest Vcc  
# 		- expected worst case clock skew                
#---------------------------------------------------------
#---------------------------------------------------------
# Set the current design to the top level instance name 
# to make sure that you are working on the right design
# at the time of constraint setting and compilation
#---------------------------------------------------------

# Elaborating design and uniquifying instances
elaborate $MODNAME -library WORK
uniquify


current_design $MODNAME

## For FreePDK 45nm
set_wire_load_model -name "5K_hvratio_1_1"
set_wire_load_mode enclosed


#---------------------------------------------------------
# Now set up the 'CONSTRAINTS' on the design:          
# 1.  How much of the clock period is lost in the      
#     modules connected to it                          
# 2.  What type of cells are driving the inputs        
# 3.  What type of cells and how many (fanout) must it 
#     be able to drive                                 
#---------------------------------------------------------

# Clock should be created as the first step as all other
# use this as reference
#------------------------------------------------------
# Creating clocks as the last stage of setting up
# constraints after the different default constraints
# have been overridden by the design specific
# constraint file
#------------------------------------------------------
create_clock -name $clkname -period $CLK_PER -waveform "0 [expr $CLK_PER / 2]" $clkname
set_clock_uncertainty $CLK_SKEW $clkname


#---------------------------------------------------------
# Input Delay
#---------------------------------------------------------
set_input_delay $IP_DELAY -clock $clkname [remove_from_collection [all_inputs] $clkname]

#---------------------------------------------------------
# Output Delay 
#---------------------------------------------------------
set_output_delay $OP_DELAY -clock $clkname [all_outputs]

#---------------------------------------------------------	
# ASSUME being driven by a D-flip-flop                 
#---------------------------------------------------------
set_driving_cell -lib_cell "$DR_CELL_NAME" -pin "$DR_CELL_PIN" [remove_from_collection [all_inputs] $clkname]

#---------------------------------------------------------
# ASSUME the worst case output load is                 
# 4 D-flip-flop (D-inputs) and                         
# 0.013 units of wiring capacitance                     
#---------------------------------------------------------
if {$MULTI_CORNER == 1} {
  # For FreePDK 45nm
  # Splitting the library name to remove the "_typical_ccs.db" part and then joining the cell name
  set port_load_cell_pin  [ lindex [split $techlib_slow _] 0 ]/$PORT_LOAD_CELL

} else {
  # For FreePDK 45nm
  # Splitting the library name to remove the "_typical_ccs.db" part and then joining the cell name
  set port_load_cell_pin  [ lindex [split $techlib_typical _] 0 ]/$PORT_LOAD_CELL
}

#set PORT_LOAD_CELL  DFFR_X1/D
set wire_load_est   0.013
set fanout          4
set port_load [expr $wire_load_est + $fanout * [load_of $port_load_cell_pin]]
set_load $port_load [all_outputs]


# Timings for branch predictor
# Taken from Fabmem
# Words: 16384
# Width: 2

## Splitting the total memory access time in half
##set BP_ta  1.007
#set BP_ta  0.050
## Assume setup time as setup time for a 
#set BP_tas  0.050
## Assume setup times for writes as setup times for D-FF
## as it is a synchronous write
#set BP_tds 0.100
#set BP_tws 0.100
#
#set_max_delay [expr $CLK_PER/2-$BP_ta]  -from [find pin -hierarchy "*counterTable*/data0_*"]
#set_max_delay [expr $CLK_PER/2-$BP_tas] -to   [find pin -hierarchy "*counterTable*/addr0_*"]
#
#set_max_delay [expr $CLK_PER-$BP_tws]   -to   [find pin -hierarchy "*counterTable*/addr0wr*"]
#set_max_delay [expr $CLK_PER-$BP_tds]   -to   [find pin -hierarchy "*counterTable*/data0wr*"]
#set_max_delay [expr $CLK_PER-$BP_tws]   -to   [find pin -hierarchy "*counterTable*/we*"]
#
## Splitting the total memory access time in half
#set BTB_ta  0.050
## Assume setup time as setup time for a 
#set BTB_tas  0.020
## Assume setup times for writes as setup times for D-FF
## as it is a synchronous write
#set BTB_tds 0.100
#set BTB_tws 0.100
#
#set_max_delay [expr (7.5*$CLK_PER/10)-$BTB_ta]   -from [find pin -hierarchy "*btbTag*/data0_*"]
#set_max_delay [expr (2.5*$CLK_PER/10)-$BTB_tas]  -to   [find pin -hierarchy "*btbTag*/addr0_*"]
#
#set_max_delay [expr $CLK_PER-$BTB_tws]    -to   [find pin -hierarchy "*btbTag*/addr0wr*"]
#set_max_delay [expr $CLK_PER-$BTB_tds]    -to   [find pin -hierarchy "*btbTag*/data0wr*"]
#set_max_delay [expr $CLK_PER-$BTB_tws]    -to   [find pin -hierarchy "*btbTag*/we*"]

#set_dont_touch [find cell -hier "*counterTable*"]

#---------------------------------------------------------
# Now set the GOALS for the compile                    
# In most cases you want minimum area, so set the      
# goal for maximum area to be 0                        
#---------------------------------------------------------
# set_max_area 0
#---------------------------------------------------------
# This command prevents feedthroughs from input to output and avoids assign statements                 
#--------------------------------------------------------- 
set compile_delete_unloaded_sequential_cells true
set_compile_directives -delete_unloaded_gate true -constant_propagation true -local_optimization true -critical_path_resynthesis true
set compile_enable_constant_propagation_with_no_boundary_opt true
set_boundary_optimization true
set_leakage_optimization * true



set_false_path -from [find port debugPRFAddr*]
set_false_path -from [find port debugPRFWr*]
set_false_path -from [find port debugAMTAddr*]
set_false_path -from [find port dbAddr*]
set_false_path -from [find port dbData*]
set_false_path -from [find port dbWe*]

current_design Complex_ALU_DEPTH6
create_clock -name "calu_clk" -period 0.56 -waveform "0 [expr 0.56 / 2]" $clkname
set_clock_uncertainty $CLK_SKEW calu_clk
current_design FABSCALAR

## Group paths of different stages in different groups

current_instance
group_path -critical_range 0.3 -name "fetch1" -through fs1
group_path -critical_range 0.3 -name "fetch2" -through fs2
group_path -critical_range 0.3 -name "decode" -through decode
current_instance instBuf
group_path -critical_range 0.3 -name "ibuffWr" -to instBuffer
group_path -critical_range 0.3 -name "ibuffRd" -from instBuffer
current_instance
group_path -critical_range 0.3 -name "rename" -through rename
group_path -critical_range 0.3 -name "dispatch" -through dispatch
current_instance issueq
group_path -critical_range 0.3 -name "issueq" -from [all_registers] 
current_instance
current_instance iq_regread
group_path -critical_range 0.3 -name "issueqRd" -to [all_registers] 
current_instance

## Set up options for retiming by optimize_registers engine
set_optimize_registers false
set_optimize_registers true -designs [get_designs Complex_ALU*]

## Set up options for Adaptive Retiming by compile_ultra -retime engine
set_dont_retime ${MODNAME} true
set_dont_retime [get_designs Complex_ALU*] false

# RBRC 
#------------------------------------------------------
# Include the the design specific contraints from the
# design directory. This may override the generic
# contraints provided in the global constraint file.
#------------------------------------------------------ 
set FILE_EXISTS [file exists ${HOOKS_DIR}/Post_Constraints_Hook.tcl]
if { $FILE_EXISTS == 1 } {
 source ${HOOKS_DIR}/Post_Constraints_Hook.tcl
}

#---------------------------------------------------------
# check_design checks for consistency of design and issues
# warnings and errors. An error would imply the design is 
# not compilable. See > man check_design for more information.
#---------------------------------------------------------
check_design -summary
check_design > ${REPORT_DIR}/check_design_init_${MODNAME}_${RUN_ID}.rpt


#---------------------------------------------------------
# link performs check for presence of the design components 
# instantiated within the design. It makes sure that all the 
# components (either library unit or other designs within the
# heirarchy) are present in the search path and connects all 
# of the disparate components logically to the present design
#---------------------------------------------------------

link > ${REPORT_DIR}/link_design_${MODNAME}_${RUN_ID}.rpt 
list_instances > ${REPORT_DIR}/instances_${MODNAME}_${RUN_ID}.rpt 
