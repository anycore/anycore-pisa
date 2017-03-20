###########################################
## physical design instructions
###########################################

## synthesis ##############################
The synthesis base directory is SYNTH/. The scripts and any other input files
(excluding the RTL) are in scripts/. The makefile in SYNTH/ will invoke
Synopsys Design Compiler and synthesize the core. The synthesized netlist is
named netlist/FABSCALAR_final.v, a log file is created in logs/, and all
reports are placed in reports/. 

lines that begin with "$ " are meant to be executed in a shell and lines that
begin with "> " are meant to be executed in the tool.

1) $ cd SYNTH
2) $ add synopsys_new
3) set the clock constraint in scripts/setup.tcl. 
4) $ make

## p&r ####################################
1) $ cd PR/
2) $ add cadence2010
3) $ make uniquify
    This "uniquifies" the synthesized netlist by creating a unique module for
    each instantiation of a module. This should be done by the "uniquify"
    command in design compiler but for some reason it's not working and
    encounter complains about a non-unique design. Maybe "uniquify" needs to
    be moved later in the scripts. For now, this works.
4) Run the desired command. Options are:
    $ make init
    $ make place
    $ make cts
    $ make trialroute
    $ make route
    Each of these (except route) will run all prior steps as well. For
    example, "$ make trialroute" will run init, place, cts and trialroute. "$
    make route" runs all prior steps except trialroute. To run an individual
    step, add "run_" in front of the step you wish to execute (e.g. "$ make
    run_trialroute" will only run trialroute).




## untouched ##############################
4) Place & Route the design 

When modifying this tutorial for another design, remember that you
will probably need to make the follwoing changes:
 design.conf - ui_netlist & ui_topcell
 design.tc - timing constraint
 setup.tcl - modname & topmetal

Use the following commands to run through the complete tutorial.
Refer to the pr_tut1.pdf file for a more detailed explanation.

cd ../PR
encounter -nowin -overwrite -replay run_init.tcl >& run_init.log
encounter -nowin -overwrite -replay run_place.tcl >& run_place.log
encounter -nowin -overwrite -replay run_cts.tcl >& run_cts.log
mv clock.tmpl clock.ctstch
encounter -nowin -overwrite -replay run_cts.tcl >& run_cts.log
encounter -nowin -overwrite -replay run_trialroute.tcl >& run_trialroute.log
encounter -nowin -overwrite -replay run_route.tcl >& run_route.log

5) Verify the Timing

When modifying this tutorial for another design, remember that you
will probably need to modify the parameters at the beginning of 
the run_pt.tcl file.

cd ../SYNTH
cp .synopsys_dc.setup .synopsys_pt.setup
pt_shell -f run_pt.tcl >& run_pt.log
pt_shell -f run_ptsi.tcl >& run_ptsi.log

6) Capture the Swithcing Activity

Open a new shell window, and set up the environment with these commands:
    cd SIMULATION
    source setup.csh
Make the following changes to the code:
  - tb.v file: add the following lines:
      initial begin
        $dumpfile("waves.vcd");
        $dumpvars;
      end
  - fibonacci.c file: make the following change:
      #define ITERATIONS 11
  - build.csh: replace the references to CORTEXM0DS.v and cortexm0ds_logic.v
    with the following:
      vlog ../PR/CORTEXM0DS_routed.v
source setup.csh
make ram.bin
source build.csh
(the following line creates a "waves.vcd" file that is about 410 MB)
source simulate.csh
(the following line creates a "waves.saif" file that is about 4.7 MB)
vcd2saif -input waves.vcd -instance ece720_tb/u_cortexm0ds -output waves.saif

7) Estimate the power

When modifying this tutorial for another design, remember that you
will probably need to modify the parameters at the beginning of 
the run_ptpx.tcl file.  You will likely also need to modify the strip_path
argument to the read_saif command to match the hierarchical instance
name of the simulated module.

switch back to your original shell window, which has the PrimeTime environment
pt_shell -f run_ptpx.tcl >& run_ptpx.log
