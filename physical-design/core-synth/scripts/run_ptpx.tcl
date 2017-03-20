###################################################
#
# run_ptpx.tcl
#
# 4/26/2011 W. Rhett Davis (rhett_davis@ncsu.edu)
# updated 4/5/2012
#
#####################################################
set begintime [clock seconds]

set start_cycle 0
set end_cycle 164

# set variable "type" to either routed or trialrouted
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

set VERILOG_NETLIST "${NETLIST_DIR}/verilog_final_${MODNAME}_${RUN_ID}.v"

set GATE_LEVEL_UPF ${NETLIST_DIR}/${MODNAME}_${RUN_ID}.upf

read_verilog $VERILOG_NETLIST

current_design ${MODNAME}

set_wire_load_model -name "MEDIUM"

set_wire_load_mode enclosed

#set FILE_EXISTS [file exists ${NETLIST_DIR}/${MODNAME}_${RUN_ID}.upf]
set FILE_EXISTS [file exists $GATE_LEVEL_UPF]
if { $FILE_EXISTS == 1 } {
  echo "Reading UPF ${NETLIST_DIR}/${MODNAME}_${RUN_ID}.upf"

  ## Check that the names are simple
  #set mv_input_enforce_simple_names true

  set upf_create_implicit_supply_sets false

  load_upf     $GATE_LEVEL_UPF 

}

#link_design

create_clock -name $clkname -period $CLK_PER $clkname
#if {$type == "routed"} {
#  set_propagated_clock [all_clocks]
#} else { 
#  remove_propagated_clock [all_clocks]
#  set_clock_transition 0.010 -rise [all_clocks]
#  set_clock_transition 0.010 -fall [all_clocks]
#  set_ideal_network -no_propagate [get_nets -segments $clkname]
#}
#set_input_delay $IP_DELAY -clock $clkname [remove_from_collection [all_inputs] $clkname]
#set_driving_cell -lib_cell "$DR_CELL_NAME" -pin "$DR_CELL_PIN" [remove_from_collection [all_inputs] $clkname]


set_app_var power_enable_analysis TRUE
if { $USE_ACTIVITY_FILE == 1 } {
  set_app_var power_analysis_mode time_based
  #set_power_analysis_options -waveform_format none -waveform_interval 10
  #set_app_var power_analysis_mode average
} else {
  set_app_var power_analysis_mode average
}
set_app_var power_x_transition_derate_factor 0

set_app_var power_default_toggle_rate 0.2
set_app_var power_default_static_probability 0.5
set_app_var power_default_toggle_rate_reference_clock fastest

set_app_var power_enable_multi_rail_analysis true


#read_parasitics -format spef "${PR_DIR}FABSCALAR_${type}.spef"

#check_timing
#update_timing
#report_timing

#####################################################################
#       read VCD file
#####################################################################
#echo "" > power/power_ptpx_${MODNAME}.rpt
#
#for { set i $start_cycle } { $i < $end_cycle } { incr i } {
#    set start_time [expr $i*$CLK_PER]
#    set end_time [expr ($i+1)*$CLK_PER]
#    read_vcd "${VCD_DIR}/${VCD_FILE}.vcd" -zero_delay -time "$start_time $end_time" -strip_path "${VCD_FILE}/${VCD_INST}"
#    echo "\n\n\n\n\ntime $i to [expr $i+1]" >> power/power_ptpx_${MODNAME}.rpt 
#    report_power -groups {register combinational sequential} -hierarchy  >> power/power_ptpx_${MODNAME}.rpt
#}

#####################################################################
#       read switching activity file
#####################################################################
if { $USE_ACTIVITY_FILE == 1 } {
  echo "Reading VCD ${VCD_DIR}/${VCD_FILE}"
  read_vcd "${VCD_DIR}/${VCD_FILE}" -strip_path "${VCD_INST}"
} else {


  set_switching_activity -toggle_rate 0.2 -static_probability 0.5 -base_clock $clkname -type inputs
  set_switching_activity -toggle_rate 0.2 -static_probability 0.5 [remove_from_collection [get_pins -hierarchical */Q] [get_pins PwrMan/*/Q]]
  set_switching_activity -toggle_rate 0.2 -static_probability 0.5 [remove_from_collection [get_pins -hierarchical */QN] [get_pins PwrMan/*/QN]]
  #infer_switching_activity -apply -output ${REPORT_DIR}/inferred_switching_activity_${MODNAME}_${RUN_ID}.rpt
  #set_switching_activity -period $CLK_PER -toggle_rate 0.20 -static_probability 0.5 [remove_from_collection [get_nets -hier *] [get_nets -hier *clk*]]
  set_switching_activity -period $CLK_PER -toggle_rate 0.20 -static_probability 0.5 [get_ports {inst_i instValid_i ldData_i ldDataValid_i}]
  #set_switching_activity -period $CLK_PER -toggle_rate 0.20 -static_probability 0.5 [report_switching_activity -list_not_annotated]
  
  set_case_analysis 0 resetFetch_i
  set_case_analysis 0 reset
}

create_power_group -name isolation [get_cells -hierarchical *ISO*]

set FILE_EXISTS [file exists ${LOCAL_SCRIPT_DIR}/pt_local.tcl]
if { $FILE_EXISTS == 1 } {
  source ${LOCAL_SCRIPT_DIR}/pt_local.tcl
}


report_switching_activity > ${REPORT_DIR}/switching_ptpx_${MODNAME}_${RUN_ID}.rpt


## Annotate power data for black boxes
#set_annotated_power -int 0.005 -leak 0.005 [get_cells *BTB*]
#set_annotated_power -internal_power 0.005 -leakage_power 0.005 [get_cells *BP*]


#####################################################################
#       check/update/report power
#####################################################################
#update_power
##check_power -verbose > ${REPORT_DIR}/power_ptpx_${MODNAME}_${RUN_ID}.rpt
##report_power -verbose > ${REPORT_DIR}/power_ptpx_${MODNAME}_${RUN_ID}.rpt
#report_power -hierarchy -verbose -nosplit -sort_by name > ${REPORT_DIR}/power_ptpx_${MODNAME}_${RUN_ID}.rpt
#echo "==End Data==" >> ${REPORT_DIR}/power_ptpx_${MODNAME}_${RUN_ID}.rpt
#report_power -groups isolation >> ${REPORT_DIR}/power_ptpx_${MODNAME}_${RUN_ID}.rpt
#report_power -hierarchy -verbose -nosplit -sort_by name -groups register >> ${REPORT_DIR}/power_ptpx_${MODNAME}_${RUN_ID}.rpt
#echo "==End Data==" >> ${REPORT_DIR}/power_ptpx_${MODNAME}_${RUN_ID}.rpt
#report_power -hierarchy -verbose -nosplit -sort_by name -groups combinational >> ${REPORT_DIR}/power_ptpx_${MODNAME}_${RUN_ID}.rpt
#echo "==End Data==" >> ${REPORT_DIR}/power_ptpx_${MODNAME}_${RUN_ID}.rpt
##report_power -hierarchy -verbose -nosplit -sort_by name -groups register > ${REPORT_DIR}/power_ptpx_${MODNAME}_${RUN_ID}_register.rpt
##report_power -hierarchy -verbose -nosplit -sort_by name -groups combinational > ${REPORT_DIR}/power_ptpx_${MODNAME}_${RUN_ID}_combinational.rpt
#
##report_power -leaf -hierarchy -verbose -sort_by name > ${REPORT_DIR}/power_ptpx_leaf_${MODNAME}_${RUN_ID}.rpt
#
##report_annotated_power -list_annotated

report_host_usage
#exit
