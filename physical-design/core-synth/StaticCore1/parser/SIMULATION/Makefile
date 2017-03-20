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
#DEFINES    = +define+SIM+USE_VPI+VERIFY+PRINT_EN -INCDIR /afs/eos.ncsu.edu/dist/syn2013.03/dw/sim_ver/ 
DEFINES    = +define+SIM+USE_VPI+VERIFY -INCDIR /afs/eos.ncsu.edu/dist/syn2013.03/dw/sim_ver/ 

CURRENT    = ../../..
CORE_NAME  = src

# Overwrite CONFIG to change the superset configuration.
CONFIG     = StaticConfig1

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

ICACHE	 = $(CURRENT)/../$(CORE_NAME)/icache/*.sv

DCACHE	 = $(CURRENT)/../$(CORE_NAME)/dcache/*.sv

MISC     = $(PARAMFILE) \
           $(CURRENT)/../$(CORE_NAME)/ISA/SimpleScalar_ISA.v \
           $(CURRENT)/../$(CORE_NAME)/include/structs.svh \
           $(CURRENT)/../$(CORE_NAME)/lib/*.sv \
	         $(CURRENT)/../$(CORE_NAME)/bist/*.sv

MEM      = $(CURRENT)/../$(CORE_NAME)/rams/*.sv	\
           $(CURRENT)/../$(CORE_NAME)/rams_configurable/*.svh	\
           $(CURRENT)/../$(CORE_NAME)/rams_configurable/*.sv	\

TOP      = $(CURRENT)/../$(CORE_NAME)/fabscalar/*.sv

TESTBENCH	=	$(CURRENT)/../$(CORE_NAME)/testbenches/l2_icache.sv	\
						$(CURRENT)/../$(CORE_NAME)/testbenches/l2_dcache.sv	\
						$(CURRENT)/../$(CORE_NAME)/testbenches/memory_hier.sv	\
						$(CURRENT)/../$(CORE_NAME)/testbenches/simulate.sv

## Config files for dynamic configuration
TB_CONFIG  = $(CURRENT)/../$(CORE_NAME)/testbenches/TbConfig1.svh
#TB_CONFIG  = $(CURRENT)/../$(CORE_NAME)/testbenches/TbConfig2.svh
#TB_CONFIG  = $(CURRENT)/../$(CORE_NAME)/testbenches/TbConfig3.svh
#TB_CONFIG  = $(CURRENT)/../$(CORE_NAME)/testbenches/TbConfig4.svh
#TB_CONFIG  = $(CURRENT)/../$(CORE_NAME)/testbenches/TbConfig5.svh
#TB_CONFIG  = $(CURRENT)/../$(CORE_NAME)/testbenches/TbConfig6.svh

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


SERDES				=	$(CURRENT)/../$(CORE_NAME)/serdes/*
CHIP_TOP      = $(CURRENT)/../$(CORE_NAME)/top_modules/FABSCALAR.sv
TESTBENCH_CHIP=	$(CURRENT)/../$(CORE_NAME)/testbenches/l2_icache.sv	\
								$(CURRENT)/../$(CORE_NAME)/testbenches/memory_hier.sv	\
								$(CURRENT)/../$(CORE_NAME)/testbenches/simulate_chip.sv


FILES_CHIP = $(MISC) $(DW) $(MEM) $(FETCH) $(DECODE) $(RENAME) $(DISPATCH) \
            $(ISSUEQ) $(REGREAD) $(EXECUTE) $(WRITEBK) $(RETIRE) $(ICACHE) $(DCACHE) $(TOP) $(CHIP_TOP)\
					 	$(LSU) $(SERDES) $(IODINE) $(TB_CONFIG) $(TESTBENCH_CHIP)

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

NCSC_RUNARGS = -access rwc -l run.log -ncsc_runargs "-DSIM_LINUX -I/usr/include -I/usr/local/include -I$(CURRENT)/functional-sim/include -I$(VPI_INCDIR) -L$(CURRENT) -L$(CURRENT)/functional-sim/libss-vpi/lib -lSS_VPI" 


# Variables used for Power simulations

TB_CONFIG		=		$(CURRENT)/../$(CORE_NAME)/testbenches/TbConfig1.svh

RUN_ID	 		= 	1
IDEAL_TFILE =   ../../../scripts/ideal_clock.tfile
#NETLIST	 		= 	../../../SYNTH/netlist/verilog_final_FABSCALAR_$(RUN_ID).v
SDFFILE	 		= 	../../SYNTH/netlist/FABSCALAR_typ_$(RUN_ID).sdf
NETLIST	 		= 	../../SYNTH/netlist/verilog_final_FABSCALAR_$(RUN_ID).v
#SDFFILE	 		= 	../../../SYNTH/netlist/FABSCALAR_typ_pt_$(RUN_ID).sdf
STD_CELLS   =   /afs/eos.ncsu.edu/lockers/research/ece/ibm_dk/12SO/IBM_PDK/std_cell_rvt/ibm/soi12s0/sc12_base_v31_rvt/2009q1v2/verilog/sc12_base_v31_rvt_soi12s0_neg.v	\
							 ../../../libs/power_cells_rvt_soi12s0.v	\
	  					 ../../../libs/generated_rams.sv

MISC_POWER 	= 	$(CURRENT)/../$(CORE_NAME)/configs/$(CONFIG).v \
								$(CURRENT)/../$(CORE_NAME)/ISA/SimpleScalar_ISA.v \
								$(CURRENT)/../$(CORE_NAME)/include/structs.svh \
								$(TB_CONFIG)

TESTBENCH_POWER	=	$(CURRENT)/../$(CORE_NAME)/testbenches/l2_icache.sv \
									$(CURRENT)/../$(CORE_NAME)/testbenches/l2_dcache.sv \
									$(CURRENT)/../$(CORE_NAME)/testbenches/memory_hier.sv \
									$(CURRENT)/../$(CORE_NAME)/testbenches/simulate_power.sv

FILES_POWER    = $(STD_CELLS) $(NETLIST) $(DW) $(SERDES) $(MISC_POWER) $(DECODE) $(TESTBENCH_POWER)

PNR_DIR					=		/local/home/rbasuro/3dic/h3-8rf/pr
#PNR_DIR					=		/local/home/rbasuro/pd2/pr

STD_CELLS_PNR   =   /afs/eos.ncsu.edu/lockers/research/ece/ibm_dk/12SO/IBM_PDK/std_cell_rvt/ibm/soi12s0/sc12_base_v31_rvt/2009q1v2/verilog/sc12_base_v31_rvt_soi12s0_neg.v \
							 			../../../libs/power_cells_rvt_soi12s0.v
NETLIST_PNR	 		= 	$(PNR_DIR)/out/pr_top_routed.v
FILES_PNR    		= 	$(STD_CELLS_PNR) $(NETLIST_PNR) $(DW) $(SERDES) $(MISC_POWER) $(TESTBENCH_POWER)
PNR_SDFFILE	 		= 	$(PNR_DIR)/out/pr_top_routed.sdf

FUNC_SIM_DIR 			= ../../../functional-sim
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
            				$(VPI_SRCDIR_POWER)/getFSCommitCount.cpp \
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
DPI_DIR    = ../../../../iodine
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
	rm -f ./FABSCALAR.sdf
	ln -s ${SDFFILE} ./FABSCALAR.sdf 
#	echo '`define RUN_ID $(RUN_ID)' > RUN_ID.v
#ifdef CONFIG
#	cp $(CURRENT)/../$(CORE_NAME)/configs/$(CONFIG).v $(CURRENT)/../$(CORE_NAME)/FabScalarParam.v
#	#make clean
#endif
	irun -top worklib.simulate:sv -mindelays -tfile $(IDEAL_TFILE) -mcdump $(DEFINES) +notimingcheck +define+POWER_SIM +define+USE_VPI +ncelabargs+"-timescale 1ns/1ps" $(NCSC_RUNARGS_POWER) $(FILES_POWER) $(VPI_FILES_POWER) $(VPI_FLAGS_POWER)
	#irun -top worklib.simulate:sv -maxdelays -tfile $(IDEAL_TFILE) -mcdump $(DEFINES) +notimingcheck +define+POWER_SIM +define+USE_VPI +ncelabargs+"-timescale 1ns/1ps" $(NCSC_RUNARGS_POWER) $(FILES_POWER) $(VPI_FILES_POWER) $(VPI_FLAGS_POWER)

run_nc_px_g:
	clear
	rm -rf *.log results/*
	rm -f ./FABSCALAR.sdf
	ln -s ${SDFFILE} ./FABSCALAR.sdf 
#	echo '`define RUN_ID $(RUN_ID)' > RUN_ID.v
#ifdef CONFIG
#	cp $(CURRENT)/../$(CORE_NAME)/configs/$(CONFIG).v $(CURRENT)/../$(CORE_NAME)/FabScalarParam.v
#	#make clean
#endif
	irun -gui -top worklib.simulate:sv -mindelays -tfile $(IDEAL_TFILE) -mcdump $(DEFINES) +define+POWER_SIM +define+USE_VPI +ncelabargs+"-timescale 1ns/1ps" $(NCSC_RUNARGS_POWER) $(FILES_POWER) $(VPI_FILES_POWER) $(VPI_FLAGS_POWER)
	#irun -gui -top worklib.simulate:sv -maxdelays -tfile $(IDEAL_TFILE) -mcdump $(DEFINES) +notimingcheck +define+POWER_SIM +define+USE_VPI +ncelabargs+"-timescale 1ns/1ps" $(NCSC_RUNARGS_POWER) $(FILES_POWER) $(VPI_FILES_POWER) $(VPI_FLAGS_POWER)

run_nc_pnr:
	clear
	rm -rf *.log results/*
	rm -f ./FABSCALAR.sdf
	ln -s ${PNR_SDFFILE} ./FABSCALAR.sdf 
#ifdef CONFIG
#	cp $(CURRENT)/../$(CORE_NAME)/configs/$(CONFIG).v $(CURRENT)/../$(CORE_NAME)/FabScalarParam.v
#	#make clean
#endif
	irun -top worklib.simulate:sv -mindelays -mcdump $(DEFINES) +define+POWER_SIM+PNR_SIM +define+USE_VPI +ncelabargs+"-timescale 1ns/1ps" $(NCSC_RUNARGS_POWER) $(FILES_PNR) $(VPI_FILES_POWER) $(VPI_FLAGS_POWER)
	#irun -top worklib.simulate:sv -mindelays -mcdump $(DEFINES) +notimingcheck +define+POWER_SIM+PNR_SIM +define+USE_VPI +ncelabargs+"-timescale 1ns/1ps" $(NCSC_RUNARGS_POWER) $(FILES_PNR) $(VPI_FILES_POWER) $(VPI_FLAGS_POWER)
vcd = waves.vcd

vcd:	$(vcd)

$(vcd):	waves.shm/waves.trn
	../../../scripts/trn2vcd run.log

saif = waves.saif

saif:	$(saif)

$(saif):	waves.shm/waves.trn
	../../../scripts/trn2saif run.log

clean:
	rm -rf *.o libvpi.so INCA_libs *.log *.sl work irun.* results/* waves.shm* top outfile .simvision out.* iodine_dpi.so run.log* simvision* *.sdf.X
