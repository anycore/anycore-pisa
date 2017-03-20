# uncomment to keep hierarchy
#set_ungroup [get_references RAM_PARTITIONED] true
set_ungroup [all_designs] false
set_structure true

## Specific to FreePDK45 nm
remove_attribute LowPowerOpenCellLibrary/ISO* dont_touch
remove_attribute LowPowerOpenCellLibrary/ISO* dont_use 


#---------------------------------------------------------
# Include the design specific compile options file.
# -This will provide the compile options
# -This can also override anything that has been defined before
#    for eg. set_ungroup etc
#---------------------------------------------------------
set FILE_EXISTS [file exists ${HOOKS_DIR}/Pre_Compile_Hook.tcl]
if { $FILE_EXISTS == 1 } {
 source ${HOOKS_DIR}/Pre_Compile_Hook.tcl
}

#compile -map_effort medium -boundary_optimization -auto_ungroup area 
echo "Before compile ultra command"
if {$CLK_GATE == "1"} {
  compile_ultra -retime -gate_clock
} else {
  compile_ultra -retime -no_autoungroup
}

#---------------------------------------------------------
# Now trace the critical (slowest) loops -sort_by slack -max_paths and see if     
# the timing works.                                    
# If the slack is NOT met, you HAVE A PROBLEM and      
# need to redesign or try some other minimization      
# tricks that Synopsys can do                          
#---------------------------------------------------------

if {$MULTI_CORNER == 1} {
  report_timing -sort_by slack -max_paths ${PATHS_TO_REPORT} > ${REPORT_DIR}/timing_max_slow_${MODNAME}_${RUN_ID}.rpt
} else {
  report_timing -sort_by slack -max_paths ${PATHS_TO_REPORT} > ${REPORT_DIR}/timing_max_typical_${MODNAME}_${RUN_ID}.rpt
}

#---------------------------------------------------------
# If multi corner synthesis is used then verify sanity 
# of the design at the different corners and perform 
# additional timing and design rule check
#---------------------------------------------------------

if {$MULTI_CORNER == 1} {
  #---------------------------------------------------------
  # Now resynthesize the design for the fastest corner   
  # making sure that hold time conditions are met        
  #---------------------------------------------------------
  
  #---------------------------------------------------------
  # Specify the fastest process corner and lowest temp   
  # and highest (fastest) Vcc                            
  #---------------------------------------------------------

  set target_library $techlib_fast
  set link_library   [concat "*" $target_library $synthetic_library $ADDITIONAL_LIBRARIES]
  translate

  #---------------------------------------------------------
  # Set the design rule to 'fix hold time violations'    
  # Then compile the design again, telling Synopsys to   
  # only change the design if there are hold time        
  # violations.                                          
  #---------------------------------------------------------

  set_fix_hold $clkname
  #compile_ultra -only_design_rule -incremental
  compile_ultra -incremental
  #compile -prioritize_min_loops -sort_by slack -max_paths -only_hold_time
  report_timing -sort_by slack -max_paths ${PATHS_TO_REPORT}  -delay min -nworst 30 > timing_min_fast_holdfixed_${MODNAME}_${RUN_ID}.rpt 

  #---------------------------------------------------------
  # Report the fastest loops -sort_by slack -max_paths.  Make sure the hold         
  # is actually met.                                     
  #---------------------------------------------------------
  report_timing -sort_by slack -max_paths ${PATHS_TO_REPORT}  -delay min  > ${REPORT_DIR}/timing_min_fast_holdfixed_${RUN_ID}.rpt

  #---------------------------------------------------------
  # Write out the 'fastest' (minimum) timing file        
  # in Standard Delay Format.  We might use this in	    
  # later verification.                                  
  #---------------------------------------------------------

  if {$WRITE_SDF == 1} {
    write_sdf -context verilog ${NETLIST_DIR}/${MODNAME}_min_${RUN_ID}.sdf
  }

  #---------------------------------------------------------
  # Since Synopsys has to insert logic to meet hold      
  # violations, we might find that we have setup         
  # violations now.  So lets recheck with the slowest    
  # corner, etc.                                         
  #  YOU have problems if the slack is NOT MET           
  # 'translate' means 'translate to new library'         
  #---------------------------------------------------------

  set target_library $techlib_slow
  set link_library   [concat "*" $target_library $synthetic_library $ADDITIONAL_LIBRARIES]
  translate
  report_timing -sort_by slack -max_paths ${PATHS_TO_REPORT}   > ${REPORT_DIR}/timing_max_slow_holdfixed_${MODNAME}_${RUN_ID}.rpt

  #---------------------------------------------------------
  # Report timings with the typical library
  #---------------------------------------------------------
  set target_library $techlib_typical
  set link_library   [concat "*" $target_library $synthetic_library $ADDITIONAL_LIBRARIES]
  translate
  report_timing -sort_by slack -max_paths ${PATHS_TO_REPORT}  -delay min -nworst 30 > ${REPORT_DIR}/timing_min_typical_holdfixed_${MODNAME}_${RUN_ID}.rpt 
  report_timing -sort_by slack -max_paths ${PATHS_TO_REPORT} > ${REPORT_DIR}/timing_max_typical_holdfixed_${MODNAME}_${RUN_ID}.rpt
} else {
# Single corner mode

  set compile_delete_unloaded_sequential_cells true
  write -hierarchy -format ddc -output ${NETLIST_DIR}/${MODNAME}_prehold_${RUN_ID}.ddc
  set_fix_hold $clkname
  compile_ultra -only_design_rule -incremental
  report_timing -sort_by slack -max_paths ${PATHS_TO_REPORT}  -delay min -nworst 30 > ${REPORT_DIR}/timing_min_typical_holdfixed_${MODNAME}_${RUN_ID}.rpt 
  report_timing -sort_by slack -max_paths ${PATHS_TO_REPORT} > ${REPORT_DIR}/timing_max_typical_holdfixed_${MODNAME}_${RUN_ID}.rpt

}


#---------------------------------------------------------
# Write out area distribution for the final design    
#---------------------------------------------------------
report_cell > ${REPORT_DIR}/cell_report_final.rpt
report_area -hierarchy  > ${REPORT_DIR}/area_final_${MODNAME}_${RUN_ID}.rpt

set_switching_activity -period $CLK_PER -toggle_rate 0.20 -static_probability 0.5 [remove_from_collection [get_nets -hier *] [get_nets -hier *clk*]]
report_power -hier -verbose -nosplit -analysis_effort medium > ${REPORT_DIR}/power_final_${MODNAME}_${RUN_ID}.rpt

#---------------------------------------------------------
# Include the design specific powere options file.
#---------------------------------------------------------

set FILE_EXISTS [file exists ${HOOKS_DIR}/Post_Synth_Pre_Write_Hook.tcl]
if { $FILE_EXISTS == 1 } {
  source ${HOOKS_DIR}/Post_Synth_Pre_Write_Hook.tcl
}

#---------------------------------------------------------
# Write out the resulting netlist in Verliog format    
#---------------------------------------------------------
if {$WRITE_VERILOG_NETLIST} {
  change_names -rules verilog -hierarchy > ${NETLIST_DIR}/fixed_names_init
  write_file -hierarchy -f verilog -o ${NETLIST_DIR}/verilog_final_${MODNAME}_${RUN_ID}.v
}

#---------------------------------------------------------
# Write out the 'slowest' (maximum) timing file        
# in Standard Delay Format.  We might use this in      
# later verification.                                  
#---------------------------------------------------------

if {$WRITE_SDF == 1} {
  if {$MULTI_CORNER == 1} {
    set target_library $techlib_typical
    set link_library   [concat "*" $target_library $synthetic_library $ADDITIONAL_LIBRARIES]
    translate
    write_sdf -context verilog ${NETLIST_DIR}/${MODNAME}_typ_${RUN_ID}.sdf
  } else {
    write_sdf -context verilog ${NETLIST_DIR}/${MODNAME}_typ_${RUN_ID}.sdf
  }
}

if {$WRITE_SDC == 1} {
  write_sdc ${NETLIST_DIR}/${MODNAME}_final.sdc
}

check_design > ${REPORT_DIR}/check_design_final_${MODNAME}_${RUN_ID}.rpt
report_qor > ${REPORT_DIR}/qor_${MODNAME}_${RUN_ID}.rpt
report_constraint -all_violators > ${REPORT_DIR}/constraint_${MODNAME}_${RUN_ID}.rpt

set FILE_EXISTS [file exists ${HOOKS_DIR}/Post_Write_Hook.tcl]
if { $FILE_EXISTS == 1 } {
  source ${HOOKS_DIR}/Post_Write_Hook.tcl
}


cputime -v -all

exit
