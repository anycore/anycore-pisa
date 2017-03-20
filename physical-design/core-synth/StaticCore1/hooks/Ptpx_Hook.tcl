echo "Executing pt_local.tcl"

#set_false_path -from [list [find port *PartitionActive*] [find port *LaneActive*] [find port reconfigureCore]]


#set_false_path -through [find pin -hierarchy "*calu/*"]

#set_false_path -through [find pin -hierarchy "exePipe5/*"]
###Takes care of paths within the instance
##Change instance to the required instance
#current_instance exePipe5
##Invalidate all paths to registers within the instance
#set_false_path -to [all_registers]
##Return to top-level
#current_instance

#set_false_path -through [find pin -hierarchy "exePipe4/*"]
###Takes care of paths within the instance
##Change instance to the required instance
#current_instance exePipe4
##Invalidate all paths to registers within the instance
#set_false_path -to [all_registers]
##Return to top-level
#current_instance
#
#set_false_path -through [find pin -hierarchy "exePipe3/*"]
###Takes care of paths within the instance
##Change instance to the required instance
#current_instance exePipe3
##Invalidate all paths to registers within the instance
#set_false_path -to [all_registers]
##Return to top-level
#current_instance

update_power
echo "==Begin Cumulative Data==" > ${REPORT_DIR}/power_ptpx_${MODNAME}_${RUN_ID}.rpt
report_power -hierarchy -verbose -nosplit -sort_by name >> ${REPORT_DIR}/power_ptpx_${MODNAME}_${RUN_ID}.rpt
echo "==End Cumulative Data==" >> ${REPORT_DIR}/power_ptpx_${MODNAME}_${RUN_ID}.rpt
report_power -groups isolation >> ${REPORT_DIR}/power_ptpx_${MODNAME}_${RUN_ID}.rpt
echo "==Begin Register Data==" >> ${REPORT_DIR}/power_ptpx_${MODNAME}_${RUN_ID}.rpt
report_power -hierarchy -verbose -nosplit -sort_by name -groups register >> ${REPORT_DIR}/power_ptpx_${MODNAME}_${RUN_ID}.rpt
echo "==End Register Data==" >> ${REPORT_DIR}/power_ptpx_${MODNAME}_${RUN_ID}.rpt
echo "==Begin Combo Data==" >> ${REPORT_DIR}/power_ptpx_${MODNAME}_${RUN_ID}.rpt
report_power -hierarchy -verbose -nosplit -sort_by name -groups combinational >> ${REPORT_DIR}/power_ptpx_${MODNAME}_${RUN_ID}.rpt
echo "==End Combo Data==" >> ${REPORT_DIR}/power_ptpx_${MODNAME}_${RUN_ID}.rpt
