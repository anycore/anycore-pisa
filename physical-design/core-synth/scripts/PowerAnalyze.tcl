#---------------------------------------------------------
# Now resynthesize the design to meet constraints,     
# and try to best achieve the goal, and using the      
# CMOSX parts.  In large designs, compile can take     
# a lllooonnnnggg time!                                
#
# -map_effort specifies how much optimization effort   
# there is, i.e. low, medium, or high.                 
#		Use high to squeeze out those last picoseconds. 
# -verify_effort specifies how much effort to spend    
# making sure that the input and output designs        
# are equivalent logically                             
#---------------------------------------------------------
##################################################
# Revision History: 01/18/2011, by Zhuo Yan
##################################################


#---------------------------------------------------------
# Include the design specific compile options file.
# -This will provide the compile options
# -This can also override anything that has been defined before
#    for eg. set_ungroup etc
#---------------------------------------------------------
# source scripts/Compile_local.tcl

 read_verilog -netlist ${NETLIST_DIR}/verilog_final_${MODNAME}_${RUN_ID}.v

 current_design $MODNAME
 set_wire_load_model -name "MEDIUM"
 set_wire_load_mode enclosed

#---------------------------------------------------------
# Write out area distribution for the final design    
#---------------------------------------------------------
if {$USE_SAIF == 1} {
 read_saif -input ${SAIF_FILE} -instance_name "simulate/dut"

} else {
 set_switching_activity -period $CLK_PER -toggle_rate 0.10 -static_probability 0.5 [remove_from_collection [get_nets -hier *] [get_nets -hier *clk*]]
 #report_power -hier -verbose -net -cell > ${REPORT_DIR}/power_final_${MODNAME}_${RUN_ID}.rpt
}
 report_power -hier -verbose -analysis_effor medium > ${REPORT_DIR}/power_final_${MODNAME}_${RUN_ID}.rpt

 cputime -v -all
