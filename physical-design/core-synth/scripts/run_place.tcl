###################################################
#
# run_place.tcl
#
# 4/24/2012 Randy Widialaksono (widialaksono@ncsu.edu)
# 3/28/2011 Rhett Davis (rhett_davis@ncsu.edu)
#
#####################################################

source ../../scripts/setup_pnr.tcl
set begintime [clock seconds]
restoreDesign ./work/${modname}_init_powerplan.enc.dat $modname
loadTimingCon design.tc

if [file exists io.place] {
    puts "Reading IO Constraint file: io.place"
    loadIoFile io.place
    set save_io 0
} else {
    puts "IO Constraint file (io.place) not found, saving template in (io.tmpl)"
    puts "Suggest modifying io.tmpl and saving as io.place"
    set save_io 1
}

# Add TAPs
#addWellTap -cell STN_TAP_DS -prefix TAP -cellInterval 30

#setPlaceMode -clkGateAware true
setPlaceMode -reorderScan false
#setPlaceMode -checkPinLayerForAccess {1 2}
setPlaceMode -checkRoute true   
#setPlaceMode -viaInPin true
setPlaceMode -maxRouteLayer ${topmetal}
placeDesign -prePlaceOpt
globalNetConnect VDD -type tiehi -inst * -override
globalNetConnect VSS -type tielo -inst * -override
#globalNetConnect VDD -type pgpin -pin VBP -inst * -override -verbose
#globalNetConnect VSS -type pgpin -pin VBN -inst * -override -verbose
saveDesign ./work/${modname}_placed.enc

# Save the IO Constraint Template
if $save_io {
    saveIoFile io.tmpl
}

set endtime [clock seconds]
set timestr [timef [expr $endtime-$begintime]]
puts "run_place.tcl completed successfully (elapsed time: $timestr actual)"
exit
