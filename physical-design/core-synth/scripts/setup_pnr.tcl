# set variable "modname" to the name of topmost module in design
set modname FABSCALAR

# set variable "topmetal" to the highest usable metal layer
set topmetal 5
set bottommetal 0

# set variable "holdslack" to the difference btw. Encounter & PrimeTime hold-times
set holdslack 0.10

# set variable "setupslack" to the difference btw. Encounter & PrimeTime hold-times
set setupslack 0.10

#setMultiCpuUsage -localCPU 4

setDesignMode -process 45
setQRCTechfile /afs/eos.ncsu.edu/lockers/research/ece/wdavis/tech/FreePDK45/ncsu_basekit/techfile/qrc/qrc.tch

set USE_CPF 0

source ../scripts/setup_pnr_local.tcl

# Define a helpful function for printing out time strings
proc timef {sec} {
  set hrs [expr $sec/3600]
  set sec [expr $sec-($hrs*3600)]
  set min [expr $sec/60]
  set sec [expr $sec-($min*60)]
  return "${hrs}h ${min}m ${sec}s"
}

