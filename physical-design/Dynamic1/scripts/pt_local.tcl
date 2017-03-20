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

set_false_path -through [find pin -hierarchy "exePipe4/*"]
##Takes care of paths within the instance
#Change instance to the required instance
current_instance exePipe4
#Invalidate all paths to registers within the instance
set_false_path -to [all_registers]
#Return to top-level
current_instance

set_false_path -through [find pin -hierarchy "exePipe3/*"]
##Takes care of paths within the instance
#Change instance to the required instance
current_instance exePipe3
#Invalidate all paths to registers within the instance
set_false_path -to [all_registers]
#Return to top-level
current_instance

if { $USE_ACTIVITY_FILE } {
} else {
  ## Control signals
  set_case_analysis 0 PwrMan/squashPipe_o
  set_case_analysis 0 PwrMan/reconfigureFlag_o
  set_case_analysis 0 PwrMan/loadNewConfig_o
  set_case_analysis 0 PwrMan/drainPipeFlag_o
  set_case_analysis 0 PwrMan/beginConsolidation_o
  set_case_analysis 0 PwrMan/reconfigDone_o
  set_case_analysis 0 PwrMan/pipeDrained_o
  
  set_case_analysis 1 PwrMan/fetchLaneActive_o[0]
  set_case_analysis 0 PwrMan/fetchLaneActive_o[1]
  set_case_analysis 0 PwrMan/fetchLaneActive_o[2]
  set_case_analysis 0 PwrMan/fetchLaneActive_o[3]
  
  set_case_analysis 1 PwrMan/dispatchLaneActive_o[0]
  set_case_analysis 0 PwrMan/dispatchLaneActive_o[1]
  set_case_analysis 0 PwrMan/dispatchLaneActive_o[2]
  set_case_analysis 0 PwrMan/dispatchLaneActive_o[3]
  
  set_case_analysis 1 PwrMan/issueLaneActive_o[0]
  set_case_analysis 1 PwrMan/issueLaneActive_o[1]
  set_case_analysis 1 PwrMan/issueLaneActive_o[2]
  set_case_analysis 0 PwrMan/issueLaneActive_o[3]
  set_case_analysis 0 PwrMan/issueLaneActive_o[4]
  
  set_case_analysis 1 PwrMan/execLaneActive_o[0]
  set_case_analysis 1 PwrMan/execLaneActive_o[1]
  set_case_analysis 1 PwrMan/execLaneActive_o[2]
  set_case_analysis 0 PwrMan/execLaneActive_o[3]
  set_case_analysis 0 PwrMan/execLaneActive_o[4]
  
  set_case_analysis 0 PwrMan/saluLaneActive_o[0]
  set_case_analysis 0 PwrMan/saluLaneActive_o[1]
  set_case_analysis 1 PwrMan/saluLaneActive_o[2]
  set_case_analysis 0 PwrMan/saluLaneActive_o[3]
  set_case_analysis 0 PwrMan/saluLaneActive_o[4]
  
  set_case_analysis 0 PwrMan/caluLaneActive_o[0]
  set_case_analysis 0 PwrMan/caluLaneActive_o[1]
  set_case_analysis 1 PwrMan/caluLaneActive_o[2]
  set_case_analysis 0 PwrMan/caluLaneActive_o[3]
  set_case_analysis 0 PwrMan/caluLaneActive_o[4]
  
  set_case_analysis 1 PwrMan/commitLaneActive_o[0]
  set_case_analysis 1 PwrMan/commitLaneActive_o[1]
  set_case_analysis 0 PwrMan/commitLaneActive_o[2]
  set_case_analysis 0 PwrMan/commitLaneActive_o[3]
  
  set_case_analysis 1 PwrMan/rfPartitionActive_o[0]
  set_case_analysis 1 PwrMan/rfPartitionActive_o[1]
  set_case_analysis 1 PwrMan/rfPartitionActive_o[2]
  set_case_analysis 0 PwrMan/rfPartitionActive_o[3]
  
  set_case_analysis 1 PwrMan/alPartitionActive_o[0]
  set_case_analysis 1 PwrMan/alPartitionActive_o[1]
  set_case_analysis 1 PwrMan/alPartitionActive_o[2]
  set_case_analysis 0 PwrMan/alPartitionActive_o[3]
  
  set_case_analysis 1 PwrMan/lsqPartitionActive_o[0]
  set_case_analysis 1 PwrMan/lsqPartitionActive_o[1]
  
  set_case_analysis 1 PwrMan/iqPartitionActive_o[0]
  set_case_analysis 1 PwrMan/iqPartitionActive_o[1]
  set_case_analysis 0 PwrMan/iqPartitionActive_o[2]
  set_case_analysis 0 PwrMan/iqPartitionActive_o[3]
  
  
  ## Primary Inputs
  set_case_analysis 0 stallFetch_i
  set_case_analysis 0 reconfigureCore_i
  
  set_case_analysis 1 fetchLaneActive_i[0]
  set_case_analysis 0 fetchLaneActive_i[1]
  set_case_analysis 0 fetchLaneActive_i[2]
  set_case_analysis 0 fetchLaneActive_i[3]
  
  set_case_analysis 1 dispatchLaneActive_i[0]
  set_case_analysis 0 dispatchLaneActive_i[1]
  set_case_analysis 0 dispatchLaneActive_i[2]
  set_case_analysis 0 dispatchLaneActive_i[3]
  
  set_case_analysis 1 issueLaneActive_i[0]
  set_case_analysis 1 issueLaneActive_i[1]
  set_case_analysis 1 issueLaneActive_i[2]
  set_case_analysis 0 issueLaneActive_i[3]
  set_case_analysis 0 issueLaneActive_i[4]
  
  set_case_analysis 1 execLaneActive_i[0]
  set_case_analysis 1 execLaneActive_i[1]
  set_case_analysis 1 execLaneActive_i[2]
  set_case_analysis 0 execLaneActive_i[3]
  set_case_analysis 0 execLaneActive_i[4]
  
  set_case_analysis 0 saluLaneActive_i[0]
  set_case_analysis 0 saluLaneActive_i[1]
  set_case_analysis 1 saluLaneActive_i[2]
  set_case_analysis 0 saluLaneActive_i[3]
  set_case_analysis 0 saluLaneActive_i[4]
  
  set_case_analysis 0 caluLaneActive_i[0]
  set_case_analysis 0 caluLaneActive_i[1]
  set_case_analysis 1 caluLaneActive_i[2]
  set_case_analysis 0 caluLaneActive_i[3]
  set_case_analysis 0 caluLaneActive_i[4]
  
  set_case_analysis 1 commitLaneActive_i[0]
  set_case_analysis 1 commitLaneActive_i[1]
  set_case_analysis 0 commitLaneActive_i[2]
  set_case_analysis 0 commitLaneActive_i[3]
  
  set_case_analysis 1 rfPartitionActive_i[0]
  set_case_analysis 1 rfPartitionActive_i[1]
  set_case_analysis 1 rfPartitionActive_i[2]
  set_case_analysis 0 rfPartitionActive_i[3]
  
  set_case_analysis 1 alPartitionActive_i[0]
  set_case_analysis 1 alPartitionActive_i[1]
  set_case_analysis 1 alPartitionActive_i[2]
  set_case_analysis 0 alPartitionActive_i[3]
  
  set_case_analysis 1 lsqPartitionActive_i[0]
  set_case_analysis 1 lsqPartitionActive_i[1]
  
  set_case_analysis 1 iqPartitionActive_i[0]
  set_case_analysis 1 iqPartitionActive_i[1]
  set_case_analysis 0 iqPartitionActive_i[2]
  set_case_analysis 0 iqPartitionActive_i[3]
  
  #set_switching_activity -toggle_rate 0 -static_probability 0 [get_nets -hier fs1fs2/PIPEREG[1].fs1fs2Reg/*]
  #set_switching_activity -toggle_rate 0 -static_probability 0 [get_nets -hier fs2/preDecode_gen[1].preDecode/*]
  #set_switching_activity -toggle_rate 0 -static_probability 0 [get_nets -hier fs2dec/PIPEREG[1].fs2DecReg/*]
  #set_switching_activity -toggle_rate 0 -static_probability 0 [get_nets -hier decode/decode_PISA_gen[1].decode_PISA/*]
  #set_switching_activity -toggle_rate 0 -static_probability 0 [get_nets -hier issueq/ISSUE_LANE[3].lane_inst/*]
  #set_switching_activity -toggle_rate 0 -static_probability 0 [get_nets -hier instBufRen/PIPEREG[1].instBufRenReg/*]
  #set_switching_activity -toggle_rate 0 -static_probability 0 [get_nets -hier rename/RMT/LANEGEN[1].lane/*]
  #set_switching_activity -toggle_rate 0 -static_probability 0 [get_nets -hier renDis/PIPEREG[1].renDisReg/*]
  #set_switching_activity -toggle_rate 0 -static_probability 0 [get_nets -hier iq_regread/PIPEREG[3].iqRRReg/*]
  #set_switching_activity -toggle_rate 0 -static_probability 0 [get_nets -hier exePipe3/*]
  
  
  #set_switching_activity -toggle_rate 0 -static_probability 0 [get_pins activeList/*/*/*/INST_LOOP_2__ram_instance/*/Q]
  #set_switching_activity -toggle_rate 0 -static_probability 0 [get_pins activeList/*/*/*/INST_LOOP_3__ram_instance/*/Q]
  #
  #set_switching_activity -toggle_rate 0 -static_probability 0 [get_pins issueq/*/*/*/INST_LOOP_2__ram_instance/*/Q]
  #set_switching_activity -toggle_rate 0 -static_probability 0 [get_pins issueq/*/*/*/INST_LOOP_3__ram_instance/*/Q]
  #
  #set_switching_activity -toggle_rate 0 -static_probability 0 [get_pins issueq/*/*/*/INST_LOOP_2__cam_instance/*/Q]
  #set_switching_activity -toggle_rate 0 -static_probability 0 [get_pins issueq/*/*/*/INST_LOOP_3__cam_instance/*/Q]
  #
  #set_switching_activity -toggle_rate 0 -static_probability 0 [get_pins issueq/issueQfreelist/*/*/*/INST_LOOP_2__ram_instance/*/Q]
  #set_switching_activity -toggle_rate 0 -static_probability 0 [get_pins issueq/issueQfreelist/*/*/*/INST_LOOP_3__ram_instance/*/Q]
  #
  #set_switching_activity -toggle_rate 0 -static_probability 0 [get_pins lsu/*/*/*/*/INST_LOOP_1__ram_instance/*/Q]
  #set_switching_activity -toggle_rate 0 -static_probability 0 [get_pins lsu/*/*/*/*/INST_LOOP_1__cam_instance/*/Q]
  #
  #set_switching_activity -toggle_rate 0 -static_probability 0 [get_pins lsu/*/*/*/*/INST_LOOP_1__ram_instance/*/Q]
  #set_switching_activity -toggle_rate 0 -static_probability 0 [get_pins lsu/*/*/*/*/INST_LOOP_1__cam_instance/*/Q]
}

set rails {VDD VDD_PRF_Active_Free_2 VDD_Issue_Structure_1}


update_power
echo "==Begin Cumulative Data==" > ${REPORT_DIR}/power_ptpx_${MODNAME}_${RUN_ID}.rpt
report_power -hierarchy -verbose -rails $rails -nosplit -sort_by name >> ${REPORT_DIR}/power_ptpx_${MODNAME}_${RUN_ID}.rpt
report_power -groups isolation >> ${REPORT_DIR}/power_ptpx_${MODNAME}_${RUN_ID}.rpt
echo "==End Cumulative Data==" >> ${REPORT_DIR}/power_ptpx_${MODNAME}_${RUN_ID}.rpt
echo "==Begin Register Data==" >> ${REPORT_DIR}/power_ptpx_${MODNAME}_${RUN_ID}.rpt
report_power -hierarchy -verbose -rails $rails -nosplit -sort_by name -groups register >> ${REPORT_DIR}/power_ptpx_${MODNAME}_${RUN_ID}.rpt
echo "==End Register Data==" >> ${REPORT_DIR}/power_ptpx_${MODNAME}_${RUN_ID}.rpt
echo "==Begin Combo Data==" >> ${REPORT_DIR}/power_ptpx_${MODNAME}_${RUN_ID}.rpt
report_power -hierarchy -verbose -rails $rails -nosplit -sort_by name -groups combinational >> ${REPORT_DIR}/power_ptpx_${MODNAME}_${RUN_ID}.rpt
echo "==End Combo Data==" >> ${REPORT_DIR}/power_ptpx_${MODNAME}_${RUN_ID}.rpt
