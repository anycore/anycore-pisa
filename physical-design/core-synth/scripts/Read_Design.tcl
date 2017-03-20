#*******************************************************************************
#                        NORTH CAROLINA STATE UNIVERSITY
#
#                               FabScalar Project
#
# FabScalar Copyright (c) 2007-2011 by Niket K. Choudhary, Brandon H. Dwiel,
# and Eric Rotenberg.  All Rights Reserved.
#
# This is a beta-release version.  It must not be redistributed at this time.
#
# Purpose: This script is used to read RTL design in the Design-Compiler.
#*******************************************************************************

# set verilog search path. "RTL_DIR" is set in the "setup.tcl".
set verilog_search_path "$RTL_DIR/"

# points to cores/dcache/
#set dcache_search_path  "../../../dcache/"

# points to cores/icache/
#set icache_search_path  "../../../icache/"

# points to cores/serdes/
#set serdes_search_path  "../../../serdes/"

set search_path         [concat  $verilog_search_path $search_path]

set fetch      "${PARAM_FILE} \
                ISA/SimpleScalar_ISA.v \
                include/structs.svh \
                fetch/RAS.sv \
                fetch/BTB.sv \
                fetch/BranchPrediction_2-bit.sv \
                fetch/FetchStage1.sv \
                fetch/Fetch1Fetch2.sv \
                fetch/FetchStage2.sv \
                fetch/Fetch2Decode.sv \
                fetch/L1ICache.sv \
                fetch/CtrlQueue.sv"

set decode     "${PARAM_FILE} \
                ISA/SimpleScalar_ISA.v \
                include/structs.svh \
                decode/Decode.sv \
                decode/Decode_PISA.sv \
                decode/PreDecode_PISA.sv \
                decode/InstructionBuffer.sv \
                decode/InstBufRename.sv"

set rename     "${PARAM_FILE} \
                ISA/SimpleScalar_ISA.v \
                include/structs.svh \
                rename/SpecFreeList.sv \
                rename/RenameMapTable.sv \
                rename/Rename.sv \
                rename/RenameDispatch.sv"

set dispatch   "${PARAM_FILE} \
                ISA/SimpleScalar_ISA.v \
                include/structs.svh \
                dispatch/Dispatch.sv \
                dispatch/ExePipeScheduler.sv \
                dispatch/ldViolationPred.sv"

set issueq     "${PARAM_FILE} \
                ISA/SimpleScalar_ISA.v \
                include/structs.svh \
                issue/IssueQFreeList.sv \
                issue/IssueQueue.sv \
                issue/IssueQRegRead.sv \
                issue/RSR.sv \
                issue/Select.sv \
                issue/SelectBlock.sv \
                issue/SelectFromBlock.sv \
                issue/PriorityEncoder.sv \
                issue/Encoder.sv \
                issue/SelectBetweenBlocks.sv \
                issue/PriorityEncoderRR.sv \
                issue/AgeOrdering.sv \
                issue/FreeIssueq.sv"

set regread    "${PARAM_FILE} \
                ISA/SimpleScalar_ISA.v \
                include/structs.svh \
                regRead/Bypass_1D.sv \
                regRead/PhyRegFile.sv \
                regRead/RegRead.sv \
                regRead/RegReadExecute.sv"

set execute    "${PARAM_FILE} \
                ISA/SimpleScalar_ISA.v \
                include/structs.svh \
                execute/AgenLsu.sv \
                execute/AGEN_ALU.sv \
                execute/Complex_ALU.sv \
                execute/Ctrl_ALU.sv \
                execute/Demux.sv \
                execute/Execute_Ctrl.sv \
                execute/Execute_M.sv \
                execute/Execute_SC.sv \
                execute/ExecutionPipe_Ctrl.sv \
                execute/ExecutionPipe_M.sv \
                execute/ExecutionPipe_SC.sv \
                execute/ForwardCheck.sv \
                execute/Mux.sv \
                execute/Simple_ALU.sv"

set lsu        "${PARAM_FILE} \
                ISA/SimpleScalar_ISA.v \
                include/structs.svh \
                lsu/LSUControl.sv \
                lsu/DispatchedLoad.sv \
                lsu/DispatchedStore.sv \
                lsu/CommitLoad.sv \
                lsu/CommitStore.sv \
                lsu/LSUDatapath.sv \
                lsu/STX_path.sv \
                lsu/LDX_path.sv \
                lsu/L1DataCache.sv \
                lsu/LoadStoreUnit.sv"

set writebk    "${PARAM_FILE} \
                ISA/SimpleScalar_ISA.v \
                include/structs.svh \
                writeback/Writeback_Ctrl.sv \
                writeback/Writeback_M.sv \
                writeback/Writeback_SC.sv"

set retire     "${PARAM_FILE} \
                ISA/SimpleScalar_ISA.v \
                include/structs.svh \
                retire/ActiveList.sv \
                retire/ArchMapTable.sv"

set rams       "${PARAM_FILE} \
                ISA/SimpleScalar_ISA.v \
                rams/ALCTRL_RAM.sv \
                rams/ALDATA_RAM.sv \
                rams/ALNPC_RAM.sv \
                rams/ALREADY_RAM.sv \
                rams/ALVIO_RAM.sv \
                rams/AMT_RAM.sv \
                rams/CTI_COMMIT_RAM.sv \
                rams/CTI_COUNTER_RAM.sv \
                rams/FREELIST_RAM.sv \
                rams/IBUFF_RAM.sv \
                rams/IQFREELIST_RAM.sv \
                rams/IQPAYLOAD_RAM.sv \
                rams/LDVIO_RAM.sv \
                rams/LDVIO_VALID_RAM.sv \
                rams/PRF_RAM.sv \
                rams/RAS_RAM.sv \
                rams/RAM_1R1W.sv \
                rams/RAM_1R2W.sv \
                rams/RAM_4R1W.sv \
                rams/RMT_RAM.sv \
                rams/WAKEUP_CAM.sv \
                rams/BTB_RAM.sv \
                rams/BP_RAM.sv"

set configurable_rams "${PARAM_FILE} \
                      configs/RAM_Params.svh \
                      rams_configurable/RAM_STATIC_CONFIG.sv \
                      rams_configurable/CAM_STATIC_CONFIG.sv \
                      rams_configurable/CAM_RAM_STATIC_CONFIG.sv \
                      rams_configurable/RAM_STATIC_CONFIG_NO_DECODE.sv \
                      rams_configurable/RAM_PARTITIONED.sv \
                      rams_configurable/RAM_PARTITIONED_SHARED_DECODE.sv \
                      rams_configurable/CAM_PARTITIONED.sv \
                      rams_configurable/CAM_RAM_PARTITIONED.sv \
                      rams_configurable/RAM_PARTITIONED_NO_DECODE.sv \
                      rams_configurable/RAM_CONFIGURABLE.sv"

set serdes      "${PARAM_FILE} \
                serdes/asym_fifo_2c.v \
                serdes/Packetizer.v \
                serdes/Depacketizer.v \
                serdes/Packetizer_wide.v \
                serdes/Depacketizer_wide.v "

set icache     "${PARAM_FILE} \
                ISA/SimpleScalar_ISA.v \
                icache/ICache_controller.sv"

set dcache     "${PARAM_FILE} \
                dcache/DCache_controller.sv"


set top        "${PARAM_FILE} \
                ISA/SimpleScalar_ISA.v \
                include/structs.svh \
                fabscalar/PerfMon.sv \
                fabscalar/PowerManager.sv \
                fabscalar/RegisterConsolidate.sv \
                fabscalar/FABSCALAR.sv"

               
# start reading RTL files.
analyze -library WORK -format sverilog $fetch
analyze -library WORK -format sverilog $decode
analyze -library WORK -format sverilog $rename
analyze -library WORK -format sverilog $dispatch
analyze -library WORK -format sverilog $issueq
analyze -library WORK -format sverilog $regread
analyze -library WORK -format sverilog $execute
analyze -library WORK -format sverilog $lsu
analyze -library WORK -format sverilog $writebk
analyze -library WORK -format sverilog $retire
analyze -library WORK -format sverilog $rams
analyze -library WORK -format sverilog $configurable_rams
#analyze -library WORK -format sverilog $dcache
#analyze -library WORK -format sverilog $icache
#analyze -library WORK -format sverilog $serdes
analyze -library WORK -format sverilog $top
