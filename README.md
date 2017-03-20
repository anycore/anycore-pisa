anycore
=======

*This contains the RTL for Anycore and associated simulation and synthesis framework
*This branch should be used for anything PISA related.

This README explains how to simulate standard benchmarks on a FabGen-generated
core out-of-the-box.


DIRECTORY STRUCTURE

1. "functional-sim": This directory contains files required to run a compiled
   program on the RTL design. The RTL is coupled to a C++ functional simulator 
   through the Verilog Procedural Interface (VPI), providing a convenient 
   Verilog and C++ co-simulation environment. The functional simulator is a 
   C++ derivative of the sim-fast functional simulator from the SimpleScalar 
   tool suite. The RTL model leverages the functional simulator to load a 
   compiled binary and initialize the processor state, giving the Verilog 
   simulator the flexibility to simulate any standard application benchmark.

2. "benchmarks": This directory contains folders and files to run SPEC2000 
   integer benchmarks.


SIMULATING BENCHMARKS

Currently, we have been able to simulate 100M SimPoints for the following
SPEC2000 integer benchmarks. To find out more about SimPoint, please refer to
"http://cseweb.ucsd.edu/~calder/simpoint/".

        Benchmark               SimPoint
        ----------------------------------------
        bzip                     40,600,000,000
        gap                     161,900,000,000
        gzip                     77,400,000,000
        mcf                      44,100,000,000
        parser                  280,300,000,000
        vortex                   40,700,000,000

To run these benchmarks:

1. First compile the functional simulator.
   Go to "functional-sim/libss-vpi/lib.src".
   Type "make clean" and "make" to compile it.
2. Download the benchmark tar-ball files from:
   http://people.engr.ncsu.edu/ericro/research/fabscalar/pre-release.htm
3. Copy each tar-ball file into its corresponding benchmark directory
   ("benchmarks/<benchmark>") and untar it.
4. Go to the directory of a benchmark that you want to run on a core. 
5. Enter "add cadence2010" on the command line.
6. Enter "make run_nc" 

Note:
Each tar-ball file contains the corresponding benchmark executable,
benchmark inputs, and SimPoint checkpoint. The checkpoint file contains
a snapshot of the process' architectural state (register and memory state)
at the SimPoint minus 100M instructions.

Note:
The file "../src/fabscalar/simulate.v" is the top-level
verilog file for simulation. This file also has performance counters: these
counters are not intended to be part of the synthesized hardware. This file
also handles system calls: only application code is explicitly simulated
since the environment is not yet set up for full-system simulation (i.e., 
operating system code).
