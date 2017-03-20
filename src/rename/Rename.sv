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

`timescale 1ns/100ps

module Rename(
	input                             clk,
	input                             reset,

`ifdef DYNAMIC_CONFIG  
  input [`COMMIT_WIDTH-1:0]         commitLaneActive_i,
  input [`DISPATCH_WIDTH-1:0]       dispatchLaneActive_i,
  input [`NUM_PARTS_RF-1:0]         rfPartitionActive_i,
  input                             reconfigureCore_i,
`endif  

	input                             stall_i,

	input                             decodeReady_i,

	input  renPkt                     renPacket_i    [0:`DISPATCH_WIDTH-1],
	output disPkt                     disPacket_o    [0:`DISPATCH_WIDTH-1],

	output phys_reg                   phyDest_o      [0:`DISPATCH_WIDTH-1],

	input  phys_reg                   freedPhyReg_i  [0:`COMMIT_WIDTH-1],

	/* input  recoverPkt                 repairPacket_i [0:`COMMIT_WIDTH-1], */

	input                             recoverFlag_i,
	input                             repairFlag_i,

	input  [`SIZE_RMT_LOG-1:0]        repairAddr_i [0:`N_REPAIR_PACKETS-1],
	input  [`SIZE_PHYSICAL_LOG-1:0]   repairData_i [0:`N_REPAIR_PACKETS-1],
`ifdef PERF_MON
 	output [`SIZE_FREE_LIST_LOG-1:0]  freeListCnt_o,
`endif

	output                            freeListEmpty_o,
	output                            renameReady_o
	);


log_reg                                logDest     [0:`DISPATCH_WIDTH-1];
log_reg                                logSrc1     [0:`DISPATCH_WIDTH-1];
log_reg                                logSrc2     [0:`DISPATCH_WIDTH-1];

phys_reg                               phyDest     [0:`DISPATCH_WIDTH-1];
phys_reg                               phySrc1     [0:`DISPATCH_WIDTH-1];
phys_reg                               phySrc2     [0:`DISPATCH_WIDTH-1];

reg  [`SIZE_PHYSICAL_LOG-1:0]          freePhyReg  [0:`DISPATCH_WIDTH-1];
reg                                    reqPhyReg   [0:`DISPATCH_WIDTH-1];

wire                                   freeListEmpty;

`ifdef DYNAMIC_CONFIG  
  wire rmtReady;
  wire freeListReady;
`endif


reg [`DISPATCH_WIDTH_LOG:0]     numDispatchLaneActive;
//reg [`SIZE_FREE_LIST_LOG-1:0]   freeListSize;
always_comb
begin
`ifdef DYNAMIC_CONFIG_AND_WIDTH 
  int i;
  numDispatchLaneActive = 0;

  for(i = 0; i < `DISPATCH_WIDTH; i++)
    numDispatchLaneActive = numDispatchLaneActive + dispatchLaneActive_i[i];

  //case(rfPartitionActive_i)
  //  4'b1111:freeListSize =  `SIZE_FREE_LIST;
  //  4'b0111:freeListSize =  `SIZE_FREE_LIST - ((`SIZE_PHYSICAL_TABLE/4)*1);
  //  4'b0011:freeListSize =  `SIZE_FREE_LIST - ((`SIZE_PHYSICAL_TABLE/4)*2); //Minimum configuration
  //  4'b0001:freeListSize =  `SIZE_FREE_LIST - ((`SIZE_PHYSICAL_TABLE/4)*3); //Invalid configuration
  //  default:freeListSize =  `SIZE_FREE_LIST;
  //endcase

`else
  numDispatchLaneActive = `DISPATCH_WIDTH;
  //freeListSize = `SIZE_FREE_LIST;
`endif
end


//* Create Rename Packets
always_comb
begin
	int i;
	for (i = 0; i < `DISPATCH_WIDTH; i++)
	begin
		logDest[i].reg_id               = renPacket_i[i].logDest;
		logDest[i].valid                = renPacket_i[i].logDestValid;
		logSrc1[i].reg_id               = renPacket_i[i].logSrc1;
		logSrc1[i].valid                = renPacket_i[i].logSrc1Valid;
		logSrc2[i].reg_id               = renPacket_i[i].logSrc2;
		logSrc2[i].valid                = renPacket_i[i].logSrc2Valid;
	end

	for (i = 0; i < `DISPATCH_WIDTH; i++)
	begin
		disPacket_o[i].seqNo            = renPacket_i[i].seqNo;
		disPacket_o[i].pc               = renPacket_i[i].pc;
		disPacket_o[i].opcode           = renPacket_i[i].opcode;
		disPacket_o[i].fu               = renPacket_i[i].fu;
		disPacket_o[i].logDest          = renPacket_i[i].logDest;

// TODO: This validation logic may not be required as
// the subsequent pipeline registers are gated anyways
// TODO: In the subsequent pipeline register, isolation
// cells are required to pull just the valid bits low
// RBRC
//`ifdef DYNAMIC_CONFIG    
//		disPacket_o[i].phyDest          = phyDest[i].reg_id;
//		disPacket_o[i].phyDestValid     = phyDest[i].valid & dispatchLaneActive_i[i];   // Pull low if lane not active
//		disPacket_o[i].phySrc1          = phySrc1[i].reg_id;
//		disPacket_o[i].phySrc1Valid     = phySrc1[i].valid & dispatchLaneActive_i[i];   // Pull low if lane not active
//		disPacket_o[i].phySrc2          = phySrc2[i].reg_id;
//		disPacket_o[i].phySrc2Valid     = phySrc2[i].valid & dispatchLaneActive_i[i];   // Pull low if lane not active
//		disPacket_o[i].immed            = renPacket_i[i].immed;
//		disPacket_o[i].immedValid       = renPacket_i[i].immedValid;
//		disPacket_o[i].isLoad           = renPacket_i[i].isLoad & dispatchLaneActive_i[i];  // Pull low if lane not active
//		disPacket_o[i].isStore          = renPacket_i[i].isStore & dispatchLaneActive_i[i]; // Pull low if lane not active
//`else    
		disPacket_o[i].phyDest          = phyDest[i].reg_id;
		disPacket_o[i].phyDestValid     = phyDest[i].valid;
		disPacket_o[i].phySrc1          = phySrc1[i].reg_id;
		disPacket_o[i].phySrc1Valid     = phySrc1[i].valid;
		disPacket_o[i].phySrc2          = phySrc2[i].reg_id;
		disPacket_o[i].phySrc2Valid     = phySrc2[i].valid;
		disPacket_o[i].immed            = renPacket_i[i].immed;
		disPacket_o[i].immedValid       = renPacket_i[i].immedValid;
		disPacket_o[i].isLoad           = renPacket_i[i].isLoad;
		disPacket_o[i].isStore          = renPacket_i[i].isStore;
//`endif
		disPacket_o[i].ldstSize         = renPacket_i[i].ldstSize;
		disPacket_o[i].ctrlType         = renPacket_i[i].ctrlType;
		disPacket_o[i].ctiID            = renPacket_i[i].ctiID;
		disPacket_o[i].predNPC          = renPacket_i[i].predNPC;
		disPacket_o[i].predDir          = renPacket_i[i].predDir;
	end
end


/***********************************************************************************
* Outputs 
***********************************************************************************/

/* Send the physical destination register to be marked as "not ready" */
always_comb
begin
	int i;
	for (i = 0; i < `DISPATCH_WIDTH; i++)
	begin
`ifdef DYNAMIC_CONFIG_WIDTH 
    PHY_DEST_VALID_CHK_RENAME : assert (~phyDest[i].valid | dispatchLaneActive_i[i])
    else $warning("Assert Failed for %d",i);
`endif    

		phyDest_o[i].reg_id                 = phyDest[i].reg_id;
		phyDest_o[i].valid                  = phyDest[i].valid & ~freeListEmpty;
	end
end


SpecFreeList specfreelist(

	.clk                               (clk),

`ifdef DYNAMIC_CONFIG  
	.reset                             (reset | reconfigureCore_i),
  .commitLaneActive_i                (commitLaneActive_i),
  .dispatchLaneActive_i              (dispatchLaneActive_i),
  .rfPartitionActive_i               (rfPartitionActive_i),
  .numDispatchLaneActive_i           (numDispatchLaneActive),
  .freeListReady_o                   (freeListReady),
`else  
	.reset                             (reset),
`endif

	.recoverFlag_i                     (recoverFlag_i),
                                     
	.stall_i                           (stall_i | ~decodeReady_i),
                                     
	.reqPhyReg_i                       (reqPhyReg),
                                     
	.freePhyReg_o                      (freePhyReg),
                                    
	.freedPhyReg_i                     (freedPhyReg_i),
`ifdef PERF_MON
	.freeListCnt_o                     (freeListCnt_o),
`endif
                                     
	.freeListEmpty_o                   (freeListEmpty)
	);


RenameMapTable RMT(
	.clk                               (clk),

`ifdef DYNAMIC_CONFIG 
	.reset                             (reset | reconfigureCore_i),
  .dispatchLaneActive_i              (dispatchLaneActive_i),
  .rmtReady_o                        (rmtReady),
`else  
	.reset                             (reset),
`endif

	
	.stall_i                           (stall_i | ~decodeReady_i | freeListEmpty),

	.logDest_i                         (logDest),
	.logSrc1_i                         (logSrc1),
	.logSrc2_i                         (logSrc2),
	
	.free_phys_i                       (freePhyReg),

	.phyDest_o                         (phyDest),
	.phySrc1_o                         (phySrc1),
	.phySrc2_o                         (phySrc2),

	.recoverFlag_i                     (recoverFlag_i),
	.repairFlag_i                      (repairFlag_i),

	/* .repairPacket_i                    (repairPacket_i), */
	.repairAddr_i                      (repairAddr_i),
	.repairData_i                      (repairData_i)
	);


// TODO: Assert that dest is not valid when lane is inactive
always_comb
begin
	int i;
	for (i = 0; i < `DISPATCH_WIDTH; i = i + 1)
	begin
`ifdef DYNAMIC_CONFIG_AND_WIDTH 
    //LOG_DEST_VALID_CHK_RENAME : assert (~renPacket_i[i].logDestValid | dispatchLaneActive_i[i])
    //else $warning("Assert Failed for %d",i);

    //TODO: This gating with dispatchLaneActive is probably not required as
    // the pipeline register before this should clamp destValid as well
		reqPhyReg[i] =  decodeReady_i & renPacket_i[i].logDestValid & ~stall_i & dispatchLaneActive_i[i];
`else
		reqPhyReg[i] =  decodeReady_i & renPacket_i[i].logDestValid & ~stall_i;
`endif    
	end
end

`ifdef DYNAMIC_CONFIG_AND_WIDTH
  assign renameReady_o     = decodeReady_i & ~freeListEmpty & rmtReady;
`else
  assign renameReady_o     = decodeReady_i & ~freeListEmpty;
`endif
assign freeListEmpty_o   = freeListEmpty;


endmodule

