###################################################
#
# run_init.tcl
# Last modified: Randy Widialaksono
# Fri May 18
# Template: Rhett Davis
#
#####################################################

set begintime [clock seconds]

## P&R Flow: init_floorplan, init_powerplan, placed, cts_1prects, cts_2preopt, cts, routed_1preopt, routed
############ Floorplan + Powerplan ##################
source ../../scripts/setup_pnr.tcl
loadConfig design.conf
#floorplan -d 5240 5240 60 60 60 60 #ignore warning: fplan box is not large enough to accommodate all the io pads
floorplan -flip n -su 1.0 0.60 40 40 40 40 #ignore warning: fplan box is not large enough to accommodate all the io pads
#loadIoFile io.place
#loadFPlan init.fp
#addIoFiller -cell PFILLQ_T  -prefix FILLERIO 
#addIoFiller -cell PFILLH_T -prefix FILLERIO 
#addIoFiller -cell PFILL1_T -prefix FILLERIO
verifyGeometry
saveDesign ./work/${modname}_init_floorplan.enc

if {${USE_CPF} == 1} {
  loadCPF ../SYNTH/netlist/FABSCALAR_1.cpf
  commitCPF -power_domain -power_switch -keepRows
  
  modifyPowerDomainAttr PG_FE_Lane_1 -box 50 100 1275 50  -rsExts 15 15 15 15 -minGaps 10 10 10 10
  modifyPowerDomainAttr PG_FE_Lane_2 -box 50 320 1275 120  -rsExts 15 15 15 15 -minGaps 10 10 10 10
  modifyPowerDomainAttr PG_PRF_Active_Free_2 -box 900 1275 1275 1025   -rsExts 15 15 15 15 -minGaps 10 10 10 10
  modifyPowerDomainAttr PG_PRF_Active_Free_3 -box 900 1000 1275 750   -rsExts 15 15 15 15 -minGaps 10 10 10 10
  modifyPowerDomainAttr PG_Issue_Structure_1 -box 50 800 275 500 -rsExts 15 15 15 15 -minGaps 10 10 10 10
  modifyPowerDomainAttr PG_Issue_Structure_2 -box 300 800 525 500 -rsExts 15 15 15 15 -minGaps 10 10 10 10
  modifyPowerDomainAttr PG_Issue_Structure_3 -box 550 800 800 500 -rsExts 15 15 15 15 -minGaps 10 10 10 10
  modifyPowerDomainAttr PG_LSU_1 -box 50 1275 200 1050  -rsExts 15 15 15 15 -minGaps 10 10 10 10

  source ../scripts/route_power.tcl

  clearGlobalNets
  
  #globalNetConnect VVDD -type pgpin -pin VDD -powerDomain PD_PART0
  globalNetConnect VSS -type pgpin -pin VSS
  
  
  #Use Metal 3 for horizontal, and Metal 4 for vertical power ring.
  addRing  -width_left 8 -width_right 8 -width_bottom 8 -width_top 8 \
                  -spacing_top 10 -spacing_bottom 10 -spacing_right 10 -spacing_left 10 \
                  -layer_bottom ub  -around core -center 1 -layer_top ub -layer_right ua -layer_left ua -nets { VSS VDD }
  
  addStripe -block_ring_top_layer_limit ua -max_same_layer_jog_length 0.8 -padcore_ring_bottom_layer_limit m2 \
            -set_to_set_distance 20 -stacked_via_top_layer lb -padcore_ring_top_layer_limit ua -spacing 5 \
            -xleft_offset 20 -xright_offset 20 -merge_stripes_value 0.2 -layer ua -block_ring_bottom_layer_limit m2 \
            -width 2.0 -nets {VSS VDD } -stacked_via_bottom_layer m1
  
  #connect standard cell power rail (m2 horizontal)
  sroute -connect { corePin } -layerChangeRange { m2 ua } -blockPinTarget { nearestTarget } -checkAlignedSecondaryPin 1 \
         -allowJogging 0 -crossoverViaBottomLayer m2 -allowLayerChange 1 -targetViaTopLayer ua -crossoverViaTopLayer ua \
         -targetViaBottomLayer m2 -nets { VSS } -corePinLayer 2 -corePinCheckStdcellGeoms 
  
  
  verifyGeometry
  
  verifyConnectivity -nets {VDD_FE_Lane_1 VDD_FE_Lane_2 VDD_PRF_Active_Free_2 \
                            VDD_PRF_Active_Free_3 VDD_Issue_Structure_1 \
                            VDD_Issue_Structure_2 VDD_Issue_Structure_3 VDD_LSU_1 VSS} -type special -error 1000 -warning 50

} else {

  # Create Power structures
  clearGlobalNets
  globalNetConnect VDD -type pgpin -pin VDD -all
  globalNetConnect VSS -type pgpin -pin VSS -all

  ### Block Ring creation around "PD_PART0" block on ub/ua
  addRing \
     -spacing_bottom 1.3 \
     -width_left 1.5 \
     -width_bottom 1.5 \
     -width_top 1.5 \
     -spacing_top 1.3 \
     -layer_bottom ub \
     -stacked_via_top_layer ub \
     -width_right 1.5 \
     -around power_domain \
     -jog_distance 0.1 \
     -offset_bottom 1 \
     -layer_top ub \
     -threshold 0.1 \
     -offset_left 1 \
     -spacing_right 1.3 \
     -spacing_left 1.3 \
     -type block_rings \
     -offset_right 0.5 \
     -offset_top 0.5 \
     -layer_right ua \
     -nets {VDD VSS} \
     -stacked_via_bottom_layer m2 \
     -layer_left ua  \
     -snap_wire_center_to_grid Grid
  
  ### Power Stripe creation for "PDROM" on M8
  addStripe \
     -block_ring_top_layer_limit ub \
     -max_same_layer_jog_length 0.8 \
     -over_power_domain 1 \
     -padcore_ring_bottom_layer_limit m2 \
     -set_to_set_distance 20 \
     -stacked_via_top_layer lb \
     -padcore_ring_top_layer_limit ub \
     -spacing 3 \
     -xleft_offset 20 \
     -xright_offset 1 \
     -merge_stripes_value 0.1 \
     -layer ua \
     -block_ring_bottom_layer_limit m2 \
     -width 1.4 \
     -nets { VDD VSS} \
     -stacked_via_bottom_layer m1 \
     -snap_wire_center_to_grid Grid 
  
  sroute -connect { corePin } -layerChangeRange { m2 ua } -blockPinTarget { nearestTarget } -checkAlignedSecondaryPin 1 \
         -allowJogging 0 -crossoverViaBottomLayer m2 -allowLayerChange 1 -targetViaTopLayer ua -crossoverViaTopLayer ua \
         -targetViaBottomLayer m2 -nets {VDD VSS} -corePinLayer 2 -corePinCheckStdcellGeoms 
  
  verifyGeometry
  verifyConnectivity -nets {VDD VSS} -type special -error 1000 -warning 50
}

saveDesign ./work/${modname}_init_powerplan.enc

set endtime [clock seconds]
set timestr [timef [expr $endtime-$begintime]]
puts "run_init.tcl completed successfully (elapsed time: $timestr actual)"
exit



