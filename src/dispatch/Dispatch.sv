/*******************************************************************************
#                        NORTH CAROLINA STATE UNIVERSITY
#
#                              AnyCore Project
# 
# AnyCore written by NCSU authors Rangeen Basu Roy Chowdhury and Eric Rotenberg.
# 
# AnyCore is based on FabScalar which was written by NCSU authors Niket K. 
# Choudhary, Brandon H. Dwiel, and Eric Rotenberg.
# 
# AnyCore also includes contributions by NCSU authors Elliott Forbes, Jayneel 
# Gandhi, Anil Kumar Kannepalli, Sungkwan Ku, Hiran Mayukh, Hashem Hashemi 
# Najaf-abadi, Sandeep Navada, Tanmay Shah, Ashlesha Shastri, Vinesh Srinivasan, 
# and Salil Wadhavkar.
# 
# AnyCore is distributed under the BSD license.
*******************************************************************************/

//TODO: NOTE: Packets through dispatch keep flowing even thouhg a particular 
// dispatch lane is inactive. This is simply to avoid adding valid bit to packet
// and adding complexity. The various queues (Active List, Issue Queue, LSQ etc) 
// will ignore invalid packets depending dispatchLaneActive bits.

`timescale 1ns/100ps

module Dispatch(
	input                                   clk,
	input                                   reset,

`ifdef DYNAMIC_CONFIG  
  input [`DISPATCH_WIDTH-1:0]             dispatchLaneActive_i,
  input [`EXEC_WIDTH-1:0]                 execLaneActive_i,
  input [`EXEC_WIDTH-1:0]                 saluLaneActive_i,
  input [`EXEC_WIDTH-1:0]                 caluLaneActive_i,
  input [`NUM_PARTS_RF-1:0]               alPartitionActive_i,
  input [`STRUCT_PARTS-1:0]               iqPartitionActive_i,
  input [`STRUCT_PARTS_LSQ-1:0]           lsqPartitionActive_i,
  // Resets the pre-steering logic so that existing lane assignments do
  // not affect the lane assignments post reconfiguration.
  input                                   reconfigureCore_i,    
`endif  

	/* Rename stage is ready with new instructions */
	input                                   renameReady_i,

	input                                   recoverFlag_i,
	input  [`SIZE_PC-1:0]                   recoverPC_i,
	input                                   loadViolation_i,

	input  disPkt                           disPacket_i [0:`DISPATCH_WIDTH-1],

  // TODO: Modify issue queue, active list and lsq for the number of write ports
  // depending upon how many dispatch lanes are active.
	output iqPkt                            iqPacket_o  [0:`DISPATCH_WIDTH-1],
	output alPkt                            alPacket_o  [0:`DISPATCH_WIDTH-1],
	output lsqPkt                           lsqPacket_o [0:`DISPATCH_WIDTH-1],

	/* Current count of instructions in Load Queue */
	input  [`SIZE_LSQ_LOG:0]                loadQueueCnt_i,

	/* Current count of instructions in Store Queue */
	input  [`SIZE_LSQ_LOG:0]                storeQueueCnt_i,

	/* Current count of instructions in Issue Queue */
	input  [`SIZE_ISSUEQ_LOG:0]             issueQueueCnt_i,

	/* Current count of instructions in Active List */
	input  [`SIZE_ACTIVELIST_LOG:0]         activeListCnt_i,

`ifdef PERF_MON
	output                                  loadStall_o,
	output                                  storeStall_o,
	output                                  iqStall_o,
	output                                  alStall_o,
`endif
	/******************************************************************
	*  If there is no empty space in Issue Queue or Active List or
	*  Load-Store Queue, then backEndReady_o is low. Instructions
	*  reading from the Instructrion Queue should be stalled. Also
	*  Front End pipe stages (Decode and Rename) after InstructionBuffer
	*  should be stalled.
	*******************************************************************/
	output                                  backEndReady_o,
	output                                  stallfrontEnd_o
	);

// Counting the number of active DISPATCH lanes
// Should be 1 bit wider as it should hold values from 1 to `DISPATCH_WIDTH
// RBRC
reg [`DISPATCH_WIDTH_LOG:0]         numDispatchLaneActive;
always_comb
begin
`ifdef DYNAMIC_CONFIG_AND_WIDTH 
  int i;
  numDispatchLaneActive = 0;
  for(i = 0; i < `DISPATCH_WIDTH; i++)
    numDispatchLaneActive = numDispatchLaneActive + dispatchLaneActive_i[i];

`else
  numDispatchLaneActive = `DISPATCH_WIDTH;
`endif
end

reg  [`SIZE_ACTIVELIST_LOG:0]       alSize;
reg  [`SIZE_ISSUEQ_LOG:0]           iqSize;
reg  [`SIZE_LSQ_LOG:0]              lsqSize;
localparam AL_PARTITION_SIZE = `SIZE_ACTIVELIST/`NUM_PARTS_RF;
localparam IQ_PARTITION_SIZE = `SIZE_ISSUEQ/`STRUCT_PARTS;
localparam LSQ_PARTITION_SIZE = `SIZE_LSQ/`STRUCT_PARTS_LSQ;
always_comb
begin
`ifdef DYNAMIC_CONFIG_AND_SIZE 
  case(alPartitionActive_i)
    4'b1111:alSize =  AL_PARTITION_SIZE*4; 
    4'b0111:alSize =  AL_PARTITION_SIZE*3;
    4'b0011:alSize =  AL_PARTITION_SIZE*2; //Minimum configuration
    4'b0001:alSize =  AL_PARTITION_SIZE*2; //Minimum configuration
    default:alSize =  `SIZE_ACTIVELIST;
  endcase

  case(iqPartitionActive_i)
    4'b1111:iqSize =  IQ_PARTITION_SIZE*4;
    4'b0111:iqSize =  IQ_PARTITION_SIZE*3;
    4'b0011:iqSize =  IQ_PARTITION_SIZE*2;
    4'b0001:iqSize =  IQ_PARTITION_SIZE*1;
    default:iqSize = `SIZE_ISSUEQ; 
  endcase

  case(lsqPartitionActive_i)
    4'b1111:lsqSize =  LSQ_PARTITION_SIZE*4;
    4'b0111:lsqSize =  LSQ_PARTITION_SIZE*3;
    4'b0011:lsqSize =  LSQ_PARTITION_SIZE*2;
    4'b0001:lsqSize =  LSQ_PARTITION_SIZE*1;
    default:lsqSize =  `SIZE_LSQ;
  endcase

`else
  alSize  = `SIZE_ACTIVELIST;
  iqSize  = `SIZE_ISSUEQ;
  lsqSize = `SIZE_LSQ;
`endif
end


/***********************************************************************************
* Count the number of LD/ST instructions in the incoming set of instructions.
***********************************************************************************/
reg  [`DISPATCH_WIDTH_LOG:0]          loadCnt;
reg  [`DISPATCH_WIDTH_LOG:0]          storeCnt;

always_comb
begin
	int i;

	loadCnt    = 0;
	storeCnt   = 0;

  // the qualifier dispatchLaneActive is required as the renDispatch pipeline register
  // might be clock gated and will hold the last value it saw.
	for (i = 0; i < `DISPATCH_WIDTH; i++) 
	begin
`ifdef DYNAMIC_CONFIG_AND_WIDTH 
  	loadCnt  = loadCnt  + (disPacket_i[i].isLoad & dispatchLaneActive_i[i]); // Parentheses necessary as '+' has operator precedence over '&' 
	  storeCnt = storeCnt + (disPacket_i[i].isStore & dispatchLaneActive_i[i]); 
`else    
  	loadCnt  = loadCnt  + disPacket_i[i].isLoad; 
	  storeCnt = storeCnt + disPacket_i[i].isStore; 
`endif    
	end
end


/***********************************************************************************
* Check for room in LDQ, STQ, IQ and AL for new instructions.
***********************************************************************************/
wire                                  iqStall;
wire                                  loadStall;
wire                                  storeStall;
wire                                  alStall;
wire                                  stall;

//TODO: Modify this stall logic to use activeDispatchLaneCount instead of `DISPATCH_WIDTH
//`ifdef DYNAMIC_CONFIG
// NOTE: numDispatchLaneActive, lsqSize and alSize are constants in case of STATIC_CONFIG
assign iqStall    = ((issueQueueCnt_i + numDispatchLaneActive) > iqSize);
assign loadStall  = ((loadQueueCnt_i  + loadCnt)         > lsqSize);
assign storeStall = ((storeQueueCnt_i + storeCnt)        > lsqSize);
assign alStall    = ((activeListCnt_i + numDispatchLaneActive) > alSize);
//`else
//assign iqStall    = ((issueQueueCnt_i + `DISPATCH_WIDTH) > `SIZE_ISSUEQ);
//assign loadStall  = ((loadQueueCnt_i  + loadCnt)         > `SIZE_LSQ);
//assign storeStall = ((storeQueueCnt_i + storeCnt)        > `SIZE_LSQ);
//assign alStall    = ((activeListCnt_i + `DISPATCH_WIDTH) > `SIZE_ACTIVELIST);
//`endif

assign stall      = (loadStall | storeStall | iqStall | alStall);

`ifdef PERF_MON
  assign loadStall_o  = loadStall ;
  assign storeStall_o = storeStall ;
  assign iqStall_o    = iqStall ;
  assign alStall_o    = alStall ;
`endif

/***********************************************************************************
* Assign each instruction to an execution pipe 
***********************************************************************************/

reg  [`INST_TYPES_LOG-1:0]            instTypes [0:`DISPATCH_WIDTH-1];
reg                                   isSimple  [0:`DISPATCH_WIDTH-1];
reg  [`ISSUE_WIDTH_LOG-1:0]           exePipes  [0:`DISPATCH_WIDTH-1];

always_comb
begin
	int i;
	for (i = 0; i < `DISPATCH_WIDTH; i++)
	begin
		instTypes[i]            = disPacket_i[i].fu;
	end
end

// TODO: The scheduler needs to change depending upon how many execution lanes are active
// at a point of time. Load/Store lane one branch execution lane and atleast one simple/complex 
// lane will always be active.

// TODO: This will also need change in order to handle core splitting as the position of execution
// lanes may change.

ExePipeScheduler exePipeSched (
	.clk                       (clk),
`ifdef DYNAMIC_CONFIG  
	.reset                     (reset | reconfigureCore_i),
  .execLaneActive_i          (execLaneActive_i),
  .saluLaneActive_i          (saluLaneActive_i),
  .caluLaneActive_i          (caluLaneActive_i),
`else  
	.reset                     (reset),
`endif  

	.recoverFlag_i             (recoverFlag_i),
	.backEndReady_i            (~stall & renameReady_i),

	.instTypes_i               (instTypes),
	.isSimple_o                (isSimple),
	.exePipes_o                (exePipes)
);


/***********************************************************************************
* Outputs 
***********************************************************************************/

/* Stalls IQ, LSQ and AL */
assign backEndReady_o       = ~stall & renameReady_i;

/* Stalls IB and Rename */
assign stallfrontEnd_o      = stall;


/***********************************************************************************
* Create the Issue Queue Packets 
***********************************************************************************/
wire [`DISPATCH_WIDTH-1:0]            predLoadVio;

// TODO: The rename dispatch register will be clock gated and so the signlas
// can be anything. Have to make sure that proper gates are used for qualifying
// validity of packets in each lane or just let them flow and not get written
// into the Issue Queue and Active List depending upon dispatchLaneActive
always_comb
begin
	int i;
	for (i = 0; i < `DISPATCH_WIDTH; i++)
	begin
		iqPacket_o[i].seqNo        = disPacket_i[i].seqNo;
		iqPacket_o[i].predLoadVio  = predLoadVio[i];
		iqPacket_o[i].pc           = disPacket_i[i].pc;
		iqPacket_o[i].opcode       = disPacket_i[i].opcode;
		iqPacket_o[i].fu           = exePipes[i];
		iqPacket_o[i].logDest      = disPacket_i[i].logDest;
		iqPacket_o[i].phyDest      = disPacket_i[i].phyDest;
		iqPacket_o[i].phyDestValid = disPacket_i[i].phyDestValid;
		iqPacket_o[i].phySrc1      = disPacket_i[i].phySrc1;
		iqPacket_o[i].phySrc1Valid = disPacket_i[i].phySrc1Valid;
		iqPacket_o[i].phySrc2      = disPacket_i[i].phySrc2;
		iqPacket_o[i].phySrc2Valid = disPacket_i[i].phySrc2Valid;
		iqPacket_o[i].immed        = disPacket_i[i].immed;
		iqPacket_o[i].immedValid   = disPacket_i[i].immedValid;
		iqPacket_o[i].isLoad       = disPacket_i[i].isLoad;
		iqPacket_o[i].isStore      = disPacket_i[i].isStore;
		iqPacket_o[i].ldstSize     = disPacket_i[i].ldstSize;
		iqPacket_o[i].isSimple     = isSimple[i];
		iqPacket_o[i].ctrlType     = disPacket_i[i].ctrlType;
		iqPacket_o[i].ctiID        = disPacket_i[i].ctiID;
		iqPacket_o[i].predNPC      = disPacket_i[i].predNPC;
		iqPacket_o[i].predDir      = disPacket_i[i].predDir;
	end
end


/***********************************************************************************
* Create the Active List Packets 
***********************************************************************************/
// TODO: Adding a valid bit to the packet might help reduce correctness
// logic in ActiveList
always_comb
begin
	int i;
	for (i = 0; i < `DISPATCH_WIDTH; i++)
	begin
		alPacket_o[i].seqNo        = disPacket_i[i].seqNo;
		alPacket_o[i].pc           = disPacket_i[i].pc;
		alPacket_o[i].logDest      = disPacket_i[i].logDest;
		alPacket_o[i].phyDest      = disPacket_i[i].phyDest;
		alPacket_o[i].phyDestValid = disPacket_i[i].phyDestValid;
		alPacket_o[i].isLoad       = disPacket_i[i].isLoad;
		alPacket_o[i].isStore      = disPacket_i[i].isStore;
	end
end


/***********************************************************************************
* Create the LSQ Packets 
***********************************************************************************/
// TODO: Adding a valid bit to the packet might help reduce correctness
// logic in LSU
always_comb
begin
	int i;
	for (i = 0; i < `DISPATCH_WIDTH; i++)
	begin
		lsqPacket_o[i].seqNo       = disPacket_i[i].seqNo;
  `ifdef LD_STALL_AT_ISSUE
		lsqPacket_o[i].predLoadVio = 1'b0;
  `else
		lsqPacket_o[i].predLoadVio = predLoadVio[i];
  `endif
`ifdef DYNAMIC_CONFIG_AND_WIDTH
		lsqPacket_o[i].isLoad      = dispatchLaneActive_i[i] ? disPacket_i[i].isLoad : 1'b0;
		lsqPacket_o[i].isStore     = dispatchLaneActive_i[i] ? disPacket_i[i].isStore : 1'b0;
`else
		lsqPacket_o[i].isLoad      = disPacket_i[i].isLoad;
		lsqPacket_o[i].isStore     = disPacket_i[i].isStore;
`endif
	end
end


`ifdef ENABLE_LD_VIOLATION_PRED
/***********************************************************************************
* Extract PC and if the instruction is a load
***********************************************************************************/
reg  [`SIZE_PC-1:0]                    pc     [0:`DISPATCH_WIDTH-1];
reg                                    isLoad [0:`DISPATCH_WIDTH-1];

always_comb
begin
	int i;
	for (i = 0; i < `DISPATCH_WIDTH; i++)
	begin
		pc[i]                              = disPacket_i[i].pc;
		isLoad[i]                          = disPacket_i[i].isLoad;
	end
end

// TODO: Use dispatchLaneActive_i to gate read and write ports
LoadViolationPred ldVioPred (
	.clk                                  (clk),
	.reset                                (reset),

	.loadViolation_i                      (loadViolation_i),
	.recoverFlag_i                        (recoverFlag_i),
	.recoverPC_i                          (recoverPC_i),

	.pc_i                                 (pc),
	.isLoad_i                             (isLoad),

	.predLoadVio_o                        (predLoadVio)
	);
`else

assign predLoadVio = 0;

`endif

endmodule

