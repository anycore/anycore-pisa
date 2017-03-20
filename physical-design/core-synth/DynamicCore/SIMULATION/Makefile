################################################################################
#                       NORTH CAROLINA STATE UNIVERSITY
#
#                              FabScalar Project
#
# FabScalar Copyright (c) 2007-2011 by Niket K. Choudhary, Salil Wadhavkar,
# and Eric Rotenberg.  All Rights Reserved.
#
# This is a beta-release version.  It must not be redistributed at this time.
#
# Purpose: This is a Makefile for running simulation!!
################################################################################

# Add additional flags
DEFINES    = +define+SIM+USE_VPI+VERIFY
#DEFINES    = +define+SIM+USE_VPI+VERIFY+DYNAMIC_CONFIG
#DEFINES    = +define+SIM+USE_VPI+VERIFY+DYNAMIC_CONFIG+PRINT_EN
#DEFINES    = +define+SIM+USE_VPI+VERIFY+PRINT_EN

CURRENT    = ../..
CORE_NAME  = src

# Overwrite CONFIG to change the superset configuration.
CONFIG     = DynamicConfig

# The Verilog source files
PARAMFILE = $(CURRENT)/../$(CORE_NAME)/configs/$(CONFIG).v

FETCH    = $(CURRENT)/../$(CORE_NAME)/fetch/*.sv

DECODE   = $(CURRENT)/../$(CORE_NAME)/decode/*.sv

RENAME   = $(CURRENT)/../$(CORE_NAME)/rename/*.sv

DISPATCH = $(CURRENT)/../$(CORE_NAME)/dispatch/*.sv

ISSUEQ   = $(CURRENT)/../$(CORE_NAME)/issue/*.sv

REGREAD  = $(CURRENT)/../$(CORE_NAME)/regRead/*.sv

EXECUTE  = $(CURRENT)/../$(CORE_NAME)/execute/*.sv

WRITEBK  = $(CURRENT)/../$(CORE_NAME)/writeback/*.sv

LSU      = $(CURRENT)/../$(CORE_NAME)/lsu/*.sv

RETIRE   = $(CURRENT)/../$(CORE_NAME)/retire/*.sv

MISC     = $(PARAMFILE) \
           $(CURRENT)/../$(CORE_NAME)/ISA/SimpleScalar_ISA.v \
           $(CURRENT)/../$(CORE_NAME)/include/structs.svh \
           $(CURRENT)/../$(CORE_NAME)/lib/*.sv

MEM      = $(CURRENT)/../$(CORE_NAME)/rams/*.sv	\
           $(CURRENT)/../$(CORE_NAME)/rams_configurable/*.svh	\
           $(CURRENT)/../$(CORE_NAME)/rams_configurable/*.sv	\

TOP      = $(CURRENT)/../$(CORE_NAME)/fabscalar/*.sv

TESTBENCH	=	$(CURRENT)/../$(CORE_NAME)/testbenches/simulate.sv

#IODINE   = $(CURRENT)/../iodine/*.sv


# Combines all the files
FILES    = $(MISC) $(MEM) $(FETCH) $(DECODE) $(RENAME) $(DISPATCH) \
            $(ISSUEQ) $(REGREAD) $(EXECUTE) $(WRITEBK) $(RETIRE) $(TOP) \
					 	$(LSU) $(IODINE) $(TESTBENCH)



VPI_DIR = $(CURRENT)/functional-sim/vpi
VPI_INCDIR = $(VPI_DIR)/include
VPI_SRCDIR = $(VPI_DIR)/src
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
            $(VPI_SRCDIR)/getArchPC.cpp \
            $(VPI_SRCDIR)/global_vars.cc \
            $(VPI_SRCDIR)/VPI_global_vars.cc \
            $(VPI_SRCDIR)/veri_memory.cc \
            $(VPI_SRCDIR)/read_config.cc \
            $(VPI_SRCDIR)/getPerfectNPC.cpp \
            $(VPI_SRCDIR)/funcsimRunahead.cpp \
            $(VPI_SRCDIR)/handleTrap.cpp \
            $(VPI_SRCDIR)/resumeTrap.cpp \
            $(VPI_SRCDIR)/register_systf.cpp

NCSC_RUNARGS = -access rwc -l run.log -ncsc_runargs "-DSIM_LINUX -I/usr/include -I/usr/local/include -I$(CURRENT)/functional-sim/include -I$(VPI_INCDIR) -L$(CURRENT) -L$(CURRENT)/functional-sim/libss-vpi/lib -lSS_VPI" 


# Variables used for Power simulations

RUN_ID	 		= 	2
NETLIST	 		= 	../SYNTH/netlist/verilog_final_FABSCALAR_$(RUN_ID).v
STD_CELLS		=		~/ibm_pdk/IBM_PDK/std_cell_rvt/ibm/soi12s0/sc12_base_v31_rvt/2009q1v2/verilog/sc12_base_v31_rvt_soi12s0.v
MISC_POWER 	= 	../../../src/configs/$(CONFIG).v \
								../../../src/fabscalar/memory_hier.sv \
								../../../src/ISA/SimpleScalar_ISA.v \
								../../../src/include/structs.svh
TESTBENCH_POWER	=	../../../src/testbenches/simulate_power.sv

FILES_POWER    = $(STD_CELLS) $(NETLIST) $(MISC_POWER) $(TESTBENCH_POWER)

FUNC_SIM_DIR 			= /afs/eos.ncsu.edu/lockers/people/r/rbasuro/private/FabScalar_svn/FabScalar-SVN/work/branches/anycore/simulation/functional-sim
VPI_DIR_POWER 		= $(FUNC_SIM_DIR)/vpi
VPI_INCDIR_POWER 	= $(VPI_DIR_POWER)/include
VPI_SRCDIR_POWER 	= $(VPI_DIR_POWER)/src
VPI_FLAGS_POWER  	= -loadvpi :initializeSim.initializeSim,readOpcode_calltf.readOpcode_calltf,readOperand_calltf.readOperand_calltf
VPI_FILES_POWER 	= $(VPI_SRCDIR_POWER)/initializeSim.cpp \
            				$(VPI_SRCDIR_POWER)/readOpcode.cpp \
            				$(VPI_SRCDIR_POWER)/readOperand.cpp \
            				$(VPI_SRCDIR_POWER)/readUnsignedByte.cpp \
            				$(VPI_SRCDIR_POWER)/readSignedByte.cpp \
            				$(VPI_SRCDIR_POWER)/readUnsignedHalf.cpp \
            				$(VPI_SRCDIR_POWER)/readSignedHalf.cpp \
            				$(VPI_SRCDIR_POWER)/readWord.cpp \
            				$(VPI_SRCDIR_POWER)/writeByte.cpp \
            				$(VPI_SRCDIR_POWER)/writeHalf.cpp \
            				$(VPI_SRCDIR_POWER)/writeWord.cpp \
            				$(VPI_SRCDIR_POWER)/getArchRegValue.cpp \
            				$(VPI_SRCDIR_POWER)/copyMemory.cpp \
            				$(VPI_SRCDIR_POWER)/getRetireInstPC.cpp \
            				$(VPI_SRCDIR_POWER)/getRetireInstPCNetSim.cpp \
            				$(VPI_SRCDIR_POWER)/getArchPC.cpp \
            				$(VPI_SRCDIR_POWER)/global_vars.cc \
            				$(VPI_SRCDIR_POWER)/VPI_global_vars.cc \
            				$(VPI_SRCDIR_POWER)/veri_memory.cc \
            				$(VPI_SRCDIR_POWER)/read_config.cc \
            				$(VPI_SRCDIR_POWER)/getPerfectNPC.cpp \
            				$(VPI_SRCDIR_POWER)/funcsimRunahead.cpp \
            				$(VPI_SRCDIR_POWER)/handleTrap.cpp \
            				$(VPI_SRCDIR_POWER)/resumeTrap.cpp \
            				$(VPI_SRCDIR_POWER)/register_systf.cpp


NCSC_RUNARGS_POWER = -access rwc -l run.log -ncsc_runargs "-DSIM_LINUX -I/usr/include -I/usr/local/include -I$(FUNC_SIM_DIR)/include -I$(VPI_INCDIR_POWER) -L$(FUNC_SIM_DIR)/libss-vpi/lib -lSS_VPI" 

# DPI files for Iodine
DPI_CC     = g++
DPI_DIR    = ../../../iodine
DPI_CFLAGS = -g -m32 -fPIC -shared -I$(DPI_DIR) -I`ncroot`/tools/inca/include
DPI_FILES  = $(DPI_DIR)/iodine.cc \
             $(DPI_DIR)/iodine_dpi.cpp 
IODINE_FLAGS = -sv_root ./ -sv_lib ./iodine_dpi.so +define+IODINE
DEBUG        = +define+PRINT_EN


run_nc:
	clear
	rm -rf *.log results/*
#ifdef CONFIG
#	cp $(CURRENT)/../$(CORE_NAME)/configs/$(CONFIG).v $(CURRENT)/../$(CORE_NAME)/FabScalarParam.v
#	#make clean
#endif
	irun -top worklib.simulate:sv $(DEFINES) $(NCSC_RUNARGS) $(FILES) $(VPI_FILES) $(VPI_FLAGS)

# Prints signals to the results/ directory and runs with Iodine tracing
debug: iodine_dpi.so 
	clear
	rm -rf *.log results/*
#ifdef CONFIG
#	cp $(CURRENT)/../$(CORE_NAME)/configs/$(CONFIG).v $(CURRENT)/../$(CORE_NAME)/FabScalarParam.v
#	#make clean
#endif
	irun -top worklib.simulate:sv $(IODINE_FLAGS) $(DEBUG) $(DEFINES) $(NCSC_RUNARGS) $(FILES) $(VPI_FILES) $(VPI_FLAGS)

# Runs with Iodine tracing
iodine: iodine_dpi.so 
	clear
	rm -rf *.log results/*
#ifdef CONFIG
#	cp $(CURRENT)/../$(CORE_NAME)/configs/$(CONFIG).v $(CURRENT)/../$(CORE_NAME)/FabScalarParam.v
#	#make clean
#endif
	irun -top worklib.simulate:sv $(IODINE_FLAGS) $(DEFINES) $(NCSC_RUNARGS) $(FILES) $(VPI_FILES) $(VPI_FLAGS)


iodine_dpi.so: $(DPI_FILES)
	$(DPI_CC) $(DPI_CFLAGS) -o iodine_dpi.so $(DPI_FILES)

# Runs with the gui
run_nc_g: 
	clear
	rm -rf *.log results/*
#ifdef CONFIG
#	cp $(CURRENT)/../$(CORE_NAME)/configs/$(CONFIG).v $(CURRENT)/../$(CORE_NAME)/FabScalarParam.v
#	#make clean
#endif
	irun -gui -top worklib.simulate:sv $(DEFINES)  $(NCSC_RUNARGS) $(FILES) $(VPI_FILES) $(VPI_FLAGS)

run_nc_px:
	clear
	rm -rf *.log results/*
#ifdef CONFIG
#	cp $(CURRENT)/../$(CORE_NAME)/configs/$(CONFIG).v $(CURRENT)/../$(CORE_NAME)/FabScalarParam.v
#	#make clean
#endif
	irun -top worklib.simulate:sv +notiming +notimingcheck +delay_mode_zero +define+POWER_SIM +define+USE_VPI +ncelabargs+"-timescale 1ns/1ps" $(NCSC_RUNARGS_POWER) $(FILES_POWER) $(VPI_FILES_POWER) $(VPI_FLAGS_POWER)
	#irun -top worklib.simulate:sv +define+POWER_SIM +define+USE_VPI +ncelabargs+"-timescale 1ns/1ps" $(NCSC_RUNARGS_POWER) $(FILES_POWER) $(VPI_FILES_POWER) $(VPI_FLAGS_POWER)
	#irun -top worklib.simulate:sv +notimingcheck +define+POWER_SIM +define+USE_VPI +ncelabargs+"-timescale 1ns/1ps" $(NCSC_RUNARGS_POWER) $(FILES_POWER) $(VPI_FILES_POWER) $(VPI_FLAGS_POWER)

run_nc_px_g:
	clear
	rm -rf *.log results/*
#ifdef CONFIG
#	cp $(CURRENT)/../$(CORE_NAME)/configs/$(CONFIG).v $(CURRENT)/../$(CORE_NAME)/FabScalarParam.v
#	#make clean
#endif
	irun -gui -top worklib.simulate:sv +notiming +notimingcheck +delay_mode_zero +define+POWER_SIM +define+USE_VPI +ncelabargs+"-timescale 1ns/1ps" $(NCSC_RUNARGS_POWER) $(FILES_POWER) $(VPI_FILES_POWER) $(VPI_FLAGS_POWER)
	#irun -gui -top worklib.simulate:sv +define+POWER_SIM +define+USE_VPI +ncelabargs+"-timescale 1ns/1ps" $(NCSC_RUNARGS_POWER) $(FILES_POWER) $(VPI_FILES_POWER) $(VPI_FLAGS_POWER)
	#irun -gui -top worklib.simulate:sv +notimingcheck +define+POWER_SIM +define+USE_VPI +ncelabargs+"-timescale 1ns/1ps" $(NCSC_RUNARGS_POWER) $(FILES_POWER) $(VPI_FILES_POWER) $(VPI_FLAGS_POWER)

vcd = waves.vcd

vcd:	$(vcd)

$(vcd):	waves.shm/waves.trn
	simvisdbutil -vcd -OUTPUT waves.vcd -OVERWRITE waves.shm/waves.trn

clean:
	rm -rf *.o libvpi.so INCA_libs *.log *.sl work irun.* results/* waves.shm* top outfile .simvision out.* iodine_dpi.so run.log* simvision* *.sdf.X
