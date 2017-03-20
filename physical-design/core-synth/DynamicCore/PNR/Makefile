all: trialroute

init: run_init

place: run_init run_place

cts: run_init run_place run_cts

trialroute: run_init run_place run_cts run_trialroute

route: run_init run_place run_cts run_route

run_init: ../../scripts/run_init.tcl
	encounter -64 -nowin -overwrite -replay ../../scripts/run_init.tcl -log logs/run_init.log

run_place: ../../scripts/run_place.tcl
	encounter -64 -nowin -overwrite -replay ../../scripts/run_place.tcl -log logs/run_place.log

run_cts: ../../scripts/run_cts.tcl
	encounter -64 -nowin -overwrite -replay ../../scripts/run_cts.tcl -log logs/run_cts.log

run_trialroute: ../../scripts/run_trialroute.tcl
	encounter -64 -nowin -overwrite -replay ../../scripts/run_trialroute.tcl -log logs/run_trialroute.log

run_route: ../../scripts/run_route.tcl
	encounter -64 -nowin -overwrite -replay ../../scripts/run_route.tcl -log logs/run_route.log

uniquify:
	uniquifyNetlist -conf uniquify.conf ../SYNTH/counter_final.v

clean:
	rm -rf *.enc *.enc.dat *.tdf
