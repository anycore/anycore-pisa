###################################################
#
# run_route.tcl
#
# Last modified: Randy Widialaksono (widialaksono@ncsu.edu)
# Tue Jun 26 18:07:44 EDT 2012
# 3/28/2011 Rhett Davis (rhett_davis@ncsu.edu)
#
#####################################################

source ../../scripts/setup_pnr.tcl
set begintime [clock seconds]
if [file exists ./work/${modname}_cts.enc] {
    puts "Restoring design ./${modname}_cts.enc"
    restoreDesign ./work/${modname}_cts.enc.dat $modname
} elseif [file exists ./work/${modname}_cts_2preopt.enc] {
    puts "Restoring design ./${modname}_cts_2preopt.enc"
    restoreDesign ./work/${modname}_cts_2preopt.enc.dat $modname
} else {
    puts "Restoring design ./${modname}_placed.enc"
    restoreDesign ./work/${modname}_placed.enc.dat $modname
}


########### Global Routing ####
setNanoRouteMode -quiet -drouteFixAntenna true
setNanoRouteMode -quiet -routeInsertAntennaDiode true
setNanoRouteMode -quiet -routeInsertDiodeForClockNets true
setNanoRouteMode -quiet -routeAntennaCellName {STN_TIEDIN_1}
setNanoRouteMode -quiet -drouteStartIteration default
setNanoRouteMode -quiet -routeTopRoutingLayer $topmetal
setNanoRouteMode -quiet -routeBottomRoutingLayer $bottommetal
setNanoRouteMode -quiet -drouteEndIteration default
setNanoRouteMode -quiet -routeWithTimingDriven false
setNanoRouteMode -quiet -routeWithSiDriven false
setMultiCpuUsage -localCpu 30 -cpuPerRemoteHost 1 -remoteHost 0 -keepLicense true
routeDesign -globalDetail -wireOpt
saveDesign ./work/${modname}_routed_1preopt.enc

setOptMode -fixFanoutLoad true
setMultiCpuUsage -localCpu 30 -cpuPerRemoteHost 1 -remoteHost 0 -keepLicense true
optDesign -postRoute -si
setOptMode -holdTargetSlack $holdslack -setupTargetSlack $setupslack
setMultiCpuUsage -localCpu 30 -cpuPerRemoteHost 1 -remoteHost 0 -keepLicense true
optDesign -postRoute
optDesign -postRoute -hold
optDesign -postRoute -hold -si
optDesign -postRoute -drv

checkplace
checkroute
deleteEmptyModule
saveNetlist -excludeLeafCell out/${modname}_routed.v
write_sdf ./out/${modname}_routed.sdf


global dbgLefDefOutVersion
set dbgLefDefOutVersion 5.7
defOut -floorplan -unplaced -netlist -scanChain -routing -trialRoute ./qrc/${modname}_routed.def


setAnalysisMode -checkType setup -asyncChecks async -skew true -clockPropagation autoDetectClockTree
buildTimingGraph
setCteReport
timeDesign -reportonly -numPaths  10 -prefix ${modname}_postRoute

########## Save Final State ####
saveDesign ./work/${modname}_routed.enc

########## Stream out GDS ####
streamOut  ./gds/${modname}_routed.gds2 \
            -structureName ${modname} \
            -stripes 1 -units 1000 -mode ALL

set endtime [clock seconds]
set timestr [timef [expr $endtime-$begintime]]
puts "run_route.tcl completed successfully (elapsed time: $timestr actual)"
exit
