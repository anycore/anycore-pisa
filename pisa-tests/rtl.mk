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

VERILOG_SRC 			= VERILOG_SRC_DIR_PLACE_HOLDER
FUNCSIM_DIR    		= FUNCSIM_DIR_PLACE_HOLDER

PERFMON_DEFINES = +define+TB_PERF_MON_CHECK

# Overwrite CONFIG to change the superset configuration.
CONFIG     = CONFIG_PLACE_HOLDER
CLKPERIOD  = 1.0

# Add additional flags
DEFINES    = -turbo +define+SIM+USE_VPI+VERIFY+PRINT_EN \
						 +defparam+CLKPERIOD=$(CLKPERIOD) \
						 -INCDIR /afs/eos.ncsu.edu/dist/syn2013.03/dw/sim_ver/ \
						 -INCDIR $(VERILOG_SRC)/testbenches/

# The Verilog source files
PARAMFILE = $(VERILOG_SRC)/configs/$(CONFIG).v

FETCH    = $(VERILOG_SRC)/fetch/*.sv

DECODE   = $(VERILOG_SRC)/decode/*.sv

RENAME   = $(VERILOG_SRC)/rename/*.sv

DISPATCH = $(VERILOG_SRC)/dispatch/*.sv

ISSUEQ   = $(VERILOG_SRC)/issue/*.sv

REGREAD  = $(VERILOG_SRC)/regRead/*.sv

EXECUTE  = $(VERILOG_SRC)/execute/*.sv

WRITEBK  = $(VERILOG_SRC)/writeback/*.sv

LSU      = $(VERILOG_SRC)/lsu/*.sv

RETIRE   = $(VERILOG_SRC)/retire/*.sv

ICACHE	 = $(VERILOG_SRC)/icache/*.sv

DCACHE	 = $(VERILOG_SRC)/dcache/*.sv

MISC     = $(PARAMFILE) \
           $(VERILOG_SRC)/ISA/SimpleScalar_ISA.v \
           $(VERILOG_SRC)/include/structs.svh \
           $(VERILOG_SRC)/lib/*.sv

MEM      = $(VERILOG_SRC)/configs/RAM_Params.svh	\
					 $(VERILOG_SRC)/rams/*.sv	\
           $(VERILOG_SRC)/rams_configurable/*.sv	\

TOP      = $(VERILOG_SRC)/fabscalar/*.sv

TESTBENCH	=	$(VERILOG_SRC)/testbenches/l2_icache.sv	\
						$(VERILOG_SRC)/testbenches/l2_dcache.sv	\
						$(VERILOG_SRC)/testbenches/memory_hier.sv	\
						$(VERILOG_SRC)/testbenches/simulate.sv

## Config files for dynamic configuration
TB_CONFIG  = $(VERILOG_SRC)/testbenches/TbConfig1.svh

#IODINE   = $(CURRENT)/../iodine/*.sv

DW       = 	 /afs/eos.ncsu.edu/dist/syn2013.03/dw/sim_ver/DW_fifoctl_s2_sf.v \
             /afs/eos.ncsu.edu/dist/syn2013.03/dw/sim_ver/DW_arb_fcfs.v \
             /afs/eos.ncsu.edu/dist/syn2013.03/dw/sim_ver/DW_mult_pipe.v \
             /afs/eos.ncsu.edu/dist/syn2013.03/dw/sim_ver/DW02_mult.v \
             /afs/eos.ncsu.edu/dist/syn2013.03/dw/sim_ver/DW_div_pipe.v \
             /afs/eos.ncsu.edu/dist/syn2013.03/dw/sim_ver/DW_div.v \
             /afs/eos.ncsu.edu/dist/syn2013.03/dw/sim_ver/DW03_pipe_reg.v


# Combines all the files
FILES    = $(MISC) $(DW) $(MEM) $(FETCH) $(DECODE) $(RENAME) $(DISPATCH) \
            $(ISSUEQ) $(REGREAD) $(EXECUTE) $(WRITEBK) $(RETIRE) $(ICACHE) $(DCACHE) $(TOP) \
					 	$(LSU) $(IODINE) $(TB_CONFIG) $(TESTBENCH)


SERDES				=	$(VERILOG_SRC)/serdes/*
CHIP_TOP      = $(VERILOG_SRC)/top_modules/fab_top.sv
TESTBENCH_CHIP=	$(VERILOG_SRC)/testbenches/l2_icache.sv	\
								$(VERILOG_SRC)/testbenches/l2_dcache.sv	\
								$(VERILOG_SRC)/testbenches/memory_hier.sv	\
								$(VERILOG_SRC)/testbenches/simulate_chip.sv


FILES_CHIP = $(MISC) $(DW) $(MEM) $(FETCH) $(DECODE) $(RENAME) $(DISPATCH) \
            $(ISSUEQ) $(REGREAD) $(EXECUTE) $(WRITEBK) $(RETIRE) $(ICACHE) $(DCACHE) $(TOP) $(CHIP_TOP)\
					 	$(LSU) $(SERDES) $(IODINE) $(TB_CONFIG) $(TESTBENCH_CHIP)


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
	irun -top worklib.simulate:sv $(DEFINES) $(NCSC_RUNARGS) $(FILES) $(VPI_FILES) $(VPI_FLAGS)

# Runs with the gui
run_nc_g: 
	clear
	mkdir -p results
	rm -rf *.log results/*
	irun -gui -top worklib.simulate:sv $(DEFINES)  $(NCSC_RUNARGS) $(FILES) $(VPI_FILES) $(VPI_FLAGS) |tee console.log

chip:
	clear
	mkdir -p results
	rm -rf *.log results/*
	irun -top worklib.simulate:sv $(DEFINES) $(NCSC_RUNARGS) $(FILES_CHIP) $(VPI_FILES) $(VPI_FLAGS)

# Runs with the gui
chip_g:
	clear
	mkdir -p results
	rm -rf *.log results/*
	irun  -gui -top worklib.simulate:sv $(DEFINES) $(NCSC_RUNARGS) $(FILES_CHIP) $(VPI_FILES) $(VPI_FLAGS)

clean:
	rm -rf *.o libvpi.so INCA_libs *.log *.sl work irun.* results/* waves.shm* top outfile .simvision out.* iodine_dpi.so run.log* simvision*
