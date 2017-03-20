echo "Executing Power_local.tcl"

#---------------------------------------------------------
# Write out the resulting netlist in Verliog format    
#---------------------------------------------------------
if {$WRITE_VERILOG_NETLIST} {
 change_names -rules verilog -hierarchy > ${NETLIST_DIR}/fixed_names_init
 write_file -hierarchy -f verilog -o ${NETLIST_DIR}/verilog_final_pre_iso_${MODNAME}_${RUN_ID}.v
}

## set UPF (Power Spec) search path. "RTL_DIR" is set in the "setup.tcl".
#set upf_search_path "$RTL_DIR/power_spec"
#set search_path         [concat  $upf_search_path $search_path]
#
## Check that the names are simple
#set mv_input_enforce_simple_names true
## Set this so that DC writes out a non hierarchical UPF
set upf_create_implicit_supply_sets false

#set_operating_conditions ss_nominal_max_0p90v_m40c
set_operating_conditions ff_nominal_min_0p99v_m40c
load_upf ${LOCAL_SCRIPT_DIR}/FABSCALAR_golden_gate_level.upf 

## CREATE NET VOLTAGES 
set_voltage 0.99  -object_list [get_supply_nets -hierarchical VDD*]
set_voltage 0     -object_list [get_supply_nets -hierarchical VSS]

compile_ultra -incremental 
set_fix_hold $clkname
compile_ultra -only_design_rule -incremental

report_timing -sort_by slack -max_paths ${PATHS_TO_REPORT}  -delay min -nworst 30 > ${REPORT_DIR}/timing_min_typical_holdfixed_${MODNAME}_${RUN_ID}.rpt 
report_timing -sort_by slack -max_paths ${PATHS_TO_REPORT} > ${REPORT_DIR}/timing_max_typical_holdfixed_${MODNAME}_${RUN_ID}.rpt

## CREATE PORT STATES 
#foreach_in_collection p1 [get_supply_ports -hierarchical *VDD] {
#  echo "Adding Port state on [get_object_name $p1]"
#  add_port_state [get_object_name $p1] -state {ACTIVE 0.99} -state {OFF off}
#}
#foreach_in_collection p1 [get_supply_ports -hierarchical *SWITCHED_VDD] {
#  echo "Adding Port state on [get_object_name $p1]"
#  add_port_state [get_object_name $p1] -state {ACTIVE 0.99} -state {OFF off}
#}
#foreach_in_collection p1 [get_supply_ports -hierarchical *VSS] {
#  echo "Adding Port state on [get_object_name $p1]"
#  add_port_state [get_object_name $p1] -state {ACTIVE 0}
#}

