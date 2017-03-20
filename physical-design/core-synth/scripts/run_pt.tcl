###################################################
#
# run_pt.tcl
#
# 4/11/2011 W. Rhett Davis (rhett_davis@ncsu.edu)
# updated 3/27/2012
#
#####################################################

set begintime [clock seconds]

# set variable "{RUN_ID}" to either routed or trialrouted
set type synthesized

# set variable "corner" to one of the following:
#   typical     (typical transistors, 1.1  V,  25 degC)
#   worst_low   (   slow transistors, 0.95 V, -40 degC)
#   low_temp    (   fast transistors, 1.25 V, -40 degC)
#   fast        (   fast transistors, 1.25 V,   0 degC)
#   slow        (   slow transistors, 0.95 V, 125 degC)
#set corner typical
set corner fast

# Define a helpful function for printing out time strings
proc timef {sec} {
  set hrs [expr $sec/3600]
  set sec [expr $sec-($hrs*3600)]
  set min [expr $sec/60]
  set sec [expr $sec-($min*60)]
  return "${hrs}h ${min}m ${sec}s"
}


if {$corner == "slow"} {
    set link_library   [concat "*" $techlib_slow $ADDITIONAL_LIBRARIES]
}
if {$corner == "typical"} {
    set link_library   [concat "*" $techlib_typical $ADDITIONAL_LIBRARIES]
}
if {$corner == "fast"} {
    set link_library   [concat "*" $techlib_fast $ADDITIONAL_LIBRARIES generated_rams.db]
}


read_verilog "${NETLIST_DIR}/verilog_final_${MODNAME}_${RUN_ID}.v"

current_design ${MODNAME}

set_wire_load_model -name "MEDIUM"
set_wire_load_mode enclosed

#link_design

create_clock -name $clkname -period $CLK_PER $clkname
if { $type == "synthesized" } {
  set_clock_uncertainty $CLK_SKEW $clkname
}  

set_input_delay $IP_DELAY -clock $clkname [remove_from_collection [all_inputs] $clkname]
set_driving_cell -lib_cell "$DR_CELL_NAME" -pin "$DR_CELL_PIN" [remove_from_collection [all_inputs] $clkname]


#set_propagated_clock [get_clocks $clkname]

set_false_path -from [find port reset]
set_false_path -from [find port debug*]
#set_false_path -to [find port debug*]
#set_false_path -through [find pin -hierarchy "*calu/*"]
#set_false_path -from [find port "execLaneActive[5]"]
#set_false_path -through [find pin -hierarchy exePipe5*]
##Takes care of paths within the instance
#Change instance to the required instance
#current_instance exePipe5
#Invalidate all paths to registers within the instance
#set_false_path -to [all_registers]
#Return to top-level
#current_instance


current_instance
group_path -name "fetch1" -through fs1
group_path -name "fetch2" -through fs2
group_path -name "decode" -through decode
current_instance instBuf/instBuffer
group_path -name "ibuffWr" -to [all_registers]
current_instance ..
group_path -name "ibuffRd" -through instBuffer
current_instance
group_path -name "rename" -through rename
group_path -name "dispatch" -through dispatch
current_instance issueq
group_path -name "issueq" -from [all_registers] 
current_instance
current_instance iq_regread
group_path -name "issueqRd" -to [all_registers] 
current_instance

# RBRC 
#------------------------------------------------------
# Include the the design specific contraints from the
# design directory. This may override the generic
# contraints provided in the global constraint file.
#------------------------------------------------------ 
set FILE_EXISTS [file exists ${LOCAL_SCRIPT_DIR}/pt_local.tcl]
if { $FILE_EXISTS == 1} {
 source ${LOCAL_SCRIPT_DIR}/pt_local.tcl
}



#report_timing -delay_type min_max -max_paths ${PATHS_TO_REPORT} -slack_lesser_than ${CLK_PER} > ${REPORT_DIR}/timing_pt_${corner}_${RUN_ID}.rpt
report_timing -slack_lesser_than ${CLK_PER} -group [get_path_groups] > ${REPORT_DIR}/timing_pt_${corner}_${RUN_ID}.rpt

write_sdf -version 3.0 -context Verilog -include [list SETUPHOLD RECREM] netlist/FABSCALAR_typ_pt_${RUN_ID}.sdf

set FILE_EXISTS [file exists ${NETLIST_DIR}/${MODNAME}_${RUN_ID}.spef]
if { $FILE_EXISTS == 1 } {
  read_parasitics -format spef "${NETLIST_DIR}/${MODNAME}_${RUN_ID}.spef"
}

if { $type == "routed" } {
  report_timing -nosplit -input_pins -transition_time -delay_type min_max -path_type full_clock_expanded -max_paths ${PATHS_TO_REPORT} >> ${REPORT_DIR}/timing_pt_${corner}_${RUN_ID}.rpt
  report_clock_timing -type summary > ${REPORT_DIR}/timing_pt_${corner}_clock.rpt
}

#write_sdf -context verilog ${REPORT_DIR}/${MODNAME}_typ_${RUN_ID}.sdf

set endtime [clock seconds]
set timestr [timef [expr $endtime-$begintime]]
puts "run_pt.tcl completed successfully (elapsed time: $timestr actual)"
exit
