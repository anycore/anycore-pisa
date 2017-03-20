###################################################
#
# run_cts.tcl
#
# 4/24/2012 Randy Widialaksono (widialaksono@ncsu.edu)
# 3/28/2011 Rhett Davis (rhett_davis@ncsu.edu)
#
#####################################################

source ../../scripts/setup_pnr.tcl
set begintime [clock seconds]
restoreDesign ./work/${modname}_placed.enc.dat $modname

########## Clock Tree Synthesis ####
loadTimingCon design.tc
setMultiCpuUsage -localCpu 30 -cpuPerRemoteHost 1 -remoteHost 0 -keepLicense true
#optDesign -preCTS

saveDesign ./work/${modname}_cts_1prects.enc

# Load the Clock-Tree Specification file, if it exists
setMultiCpuUsage -localCpu 30 -cpuPerRemoteHost 1 -remoteHost 0 -keepLicense true
if [file exists clock.ctstch] {
    puts "Reading Clock-Tree Specification file: clock.ctstch"
    specifyClockTree -clkfile clock.ctstch
    ckSynthesis -forceReconvergent -rguide cts.rguide -report clock.ctsrpt
    saveClockNets -output clock.ctsntf
} else {
    puts "Clock-Tree Specification file (clock.ctstch) not found, saving template in (clock.tmpl)"
    puts "Suggest modifying clock.tmpl and saving as clock.ctstch"
    createClockTreeSpec -output clock.tmpl
}
saveDesign ./work/${modname}_cts_2preopt.enc
setOptMode -fixFanoutLoad true
setOptMode -holdTargetSlack $holdslack -setupTargetSlack $setupslack
#setOptMode -usefulSkew true
#setOptMode -reclaimArea true
optDesign -postCTS
#optDesign -postCTS -hold
saveDesign ./work/${modname}_cts.enc

set endtime [clock seconds]
set timestr [timef [expr $endtime-$begintime]]
puts "run_cts.tcl completed successfully (elapsed time: $timestr actual)"
exit
