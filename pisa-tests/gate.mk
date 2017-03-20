################################################################################
#                       NORTH CAROLINA STATE UNIVERSITY
#
#                              AnyCore Project
#
# AnyCore Copyright (c) 2007-2011 by Niket K. Choudhary, Salil Wadhavkar,
# and Eric Rotenberg.  All Rights Reserved.
#
# This is a beta-release version.  It must not be redistributed at this time.
#
# Purpose: This is a Makefile for running simulation!!
################################################################################

SYNTH_BASE_DIR		= SYNTH_BASE_DIR_PLACE_HOLDER
VERILOG_SRC 			= VERILOG_SRC_DIR_PLACE_HOLDER
FUNCSIM_DIR    		= FUNCSIM_DIR_PLACE_HOLDER
GATE_RUN_ID				=	1

# Overwrite CONFIG to change the superset configuration.
CONFIG     				= CONFIG_PLACE_HOLDER
CORE_SYNTH_DIR		= $(SYNTH_BASE_DIR)/core-synth/$(CONFIG)/synth

SCRIPT_DIR	=	$(realpath ${SYNTH_BASE_DIR}/core-synth/scripts)
HOOKS_DIR		=	$(realpath ${SYNTH_BASE_DIR}/core-synth/$(CONFIG)/hooks)

# Add additional flags
DEFINES    = -turbo +define+SIM+USE_VPI+VERIFY+GATE_SIM+WAVES+TETRAMAX \
						 -INCDIR /afs/eos.ncsu.edu/dist/syn2013.03/dw/sim_ver/	\
						 -INCDIR $(VERILOG_SRC)/testbenches/


# The Verilog source files
PARAMFILE 	= $(VERILOG_SRC)/configs/$(CONFIG).v

RAMGEN_DIR 	= $(realpath $(SYNTH_BASE_DIR)/ramgen/FabMem)

RAMGEN_CELLS=	$(RAMGEN_DIR)/libs/ram/*.v
#STD_CELLS = /afs/eos.ncsu.edu/lockers/research/ece/wdavis/tech/nangate/NangateOpenCellLibrary_PDKv1_3_v2010_12/Front_End/Verilog/NangateOpenCellLibrary.v \
						/afs/eos.ncsu.edu/lockers/research/ece/wdavis/tech/nangate/NangateOpenCellLibrary_PDKv1_3_v2010_12/Low_Power/Front_End/Verilog/LowPowerOpenCellLibrary.v

STD_CELLS = /home/rbasuro/NangateOpenCellLibrary_PDKv1_3_v2010_12/Front_End/Verilog/NangateOpenCellLibrary.v \
						/home/rbasuro/NangateOpenCellLibrary_PDKv1_3_v2010_12/Low_Power/Front_End/Verilog/LowPowerOpenCellLibrary.v

INCLUDES 	=	$(PARAMFILE) \
						$(VERILOG_SRC)/ISA/SimpleScalar_ISA.v \
						$(VERILOG_SRC)/include/structs.svh \

TESTBENCH	=	$(VERILOG_SRC)/testbenches/l2_icache.sv	\
						$(VERILOG_SRC)/testbenches/l2_dcache.sv	\
						$(VERILOG_SRC)/testbenches/memory_hier.sv	\
						$(VERILOG_SRC)/testbenches/simulate_power.sv

GATE_NETLIST   	= $(CORE_SYNTH_DIR)/netlist/verilog_final_FABSCALAR_$(GATE_RUN_ID).v
GATE_SDF				= $(CORE_SYNTH_DIR)/netlist/FABSCALAR_typ_$(GATE_RUN_ID).sdf

## Config files for dynamic configuration
TB_CONFIG  = $(VERILOG_SRC)/testbenches/TbConfig1.svh

# Combines all the files
FILES    = 	$(STD_CELLS) $(RAMGEN_CELLS) $(GATE_NETLIST) $(INCLUDES) $(TESTBENCH)

VPI_INCDIR = $(FUNCSIM_DIR)/vpi/include
VPI_SRCDIR = $(FUNCSIM_DIR)/vpi/src
VPI_FLAGS  = -loadvpi :initializeSim.initializeSim,readOpcode_calltf.readOpcode_calltf,readOperand_calltf.readOperand_calltf
VPI_FILES = $(VPI_SRCDIR)/initializeSim.cpp \
            $(VPI_SRCDIR)/readOpcode.cpp \
            $(VPI_SRCDIR)/readOperand.cpp \
            $(VPI_SRCDIR)/readUnsignedByte.cpp \
            $(VPI_SRCDIR)/readSignedByte.cpp \
            $(VPI_SRCDIR)/readUnsignedHalf.cpp \
            $(VPI_SRCDIR)/readSignedHalf.cpp \
            $(VPI_SRCDIR)/readWord.cpp \
            $(VPI_SRCDIR)/writeByte.cpp \
            $(VPI_SRCDIR)/writeHalf.cpp \
            $(VPI_SRCDIR)/writeWord.cpp \
            $(VPI_SRCDIR)/getArchRegValue.cpp \
            $(VPI_SRCDIR)/copyMemory.cpp \
            $(VPI_SRCDIR)/getRetireInstPC.cpp \
            $(VPI_SRCDIR)/getRetireInstPCNetSim.cpp \
            $(VPI_SRCDIR)/getArchPC.cpp \
            $(VPI_SRCDIR)/getFSCommitCount.cpp \
            $(VPI_SRCDIR)/global_vars.cc \
            $(VPI_SRCDIR)/VPI_global_vars.cc \
            $(VPI_SRCDIR)/veri_memory.cc \
            $(VPI_SRCDIR)/read_config.cc \
            $(VPI_SRCDIR)/getPerfectNPC.cpp \
            $(VPI_SRCDIR)/funcsimRunahead.cpp \
            $(VPI_SRCDIR)/handleTrap.cpp \
            $(VPI_SRCDIR)/resumeTrap.cpp \
            $(VPI_SRCDIR)/register_systf.cpp

NCSC_RUNARGS = -access rwc -l run.log -ncsc_runargs "-DSIM_LINUX -I/usr/include -I/usr/local/include -I$(FUNCSIM_DIR)/include -I$(VPI_INCDIR) -L$(FUNCSIM_DIR)/libss-vpi/lib -lSS_VPI" 

run_nc:
	clear
	mkdir -p results
	rm -rf *.log results/*
	ln -sf $(GATE_SDF) FABSCALAR.sdf
	irun -top worklib.simulate:sv -mindelays $(DEFINES) +ncelabargs+"-timescale 1ns/1ps" $(NCSC_RUNARGS) $(FILES) $(VPI_FILES) $(VPI_FLAGS) 2>&1 |tee console.log

# Runs with the gui
run_nc_g: 
	clear
	mkdir -p results
	rm -rf *.log results/*
	ln -sf $(GATE_SDF) FABSCALAR.sdf
	irun -gui -top worklib.simulate:sv -mindelays $(DEFINES) +ncelabargs+"-timescale 1ns/1ps" $(NCSC_RUNARGS) $(FILES) $(VPI_FILES) $(VPI_FLAGS) 2>&1 |tee console.log

vcd = waves.vcd

vcd:	$(vcd)

$(vcd):	waves.shm/waves.trn
	$(SYNTH_BASE_DIR)/scripts/trn2vcd run.log

saif = waves.saif

saif:	$(saif)

$(saif):	waves.shm/waves.trn
	$(SYNTH_BASE_DIR)/scripts/trn2saif run.log

ptpx:
	mkdir -p reports
	echo "set HOOKS_DIR $(HOOKS_DIR)"								> 	ptpx.tcl
	echo "set RTL_DIR  $(VERILOG_SRC)"									>>	ptpx.tcl
	echo "set CONFIG_FILE $(CONFIG)"								>>	ptpx.tcl
	echo "set USE_ACTIVITY_FILE 1"									>> 	ptpx.tcl
	echo "source $(SCRIPT_DIR)/Setup.tcl"						>>	ptpx.tcl
	echo "set RUN_ID $(RUN_ID)"											>>  ptpx.tcl
	echo "source $(SCRIPT_DIR)/run_ptpx.tcl"				>>	ptpx.tcl
	tcsh -c 'add synopsys2015 && pt_shell -f ptpx.tcl  | tee ptpx.log'

clean:
	rm -rf *.o libvpi.so INCA_libs *.log *.sl work irun.* results/* waves.shm* top outfile .simvision out.* iodine_dpi.so run.log* simvision*
