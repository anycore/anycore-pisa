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

/***************************************************************************

Assumption:  
[1] `DISPATCH_WIDTH-instructions can be renamed in one cycle.
[2] There are 4-Functional Units (Integer Type) including
AGEN block which is a dedicated FU for Load/Store.
FU0  2'b00     // Simple ALU
FU1  2'b01     // Complex ALU (for MULTIPLY & DIVIDE)
FU2  2'b10     // ALU for CONTROL Instructions
FU3  2'b11     // LOAD/STORE Address Generator
[3] All the Functional Units are pipelined.

granted packet contains following information:
(14) Branch mask:
(13) Issue Queue ID:
(12) Src Reg-1:
(11) Src Reg-2:
(10) LD/ST Queue ID:
(9)  Active List ID:
(8)  Checkpoint ID:
(7)  Destination Reg:
(6)  Immediate data:
(5)  LD/ST Type:
(4)  Opcode:
(3)  Program Counter:
(2)  Predicted Target Addr:
(1)  CTI Queue ID:
(0)  Branch Prediction:

***************************************************************************/

module IssueQueue ( 
    input                                  clk,
    input                                  reset,
    input                                  flush_i,

`ifdef DYNAMIC_CONFIG    
    input  [`ISSUE_WIDTH-1:0]              issueLaneActive_i,
    input  [`DISPATCH_WIDTH-1:0]           dispatchLaneActive_i,
    input  [`EXEC_WIDTH-1:0]               execLaneActive_i,
    input  [`STRUCT_PARTS-1:0]             iqPartitionActive_i,
    input                                  reconfigureCore_i,
    output reg [`DISPATCH_WIDTH-1:0]       valid_bundle_o,
`endif    

    input                                  exceptionFlag_i,

    input                                  backEndReady_i,

    input  iqPkt                           iqPacket_i [0:`DISPATCH_WIDTH-1],

    input  phys_reg                        phyDest_i [0:`DISPATCH_WIDTH-1],

	  input  [`SIZE_ACTIVELIST_LOG-1:0]      alHead_i,
	  input  [`SIZE_ACTIVELIST_LOG-1:0]      alTail_i,
    input  [`SIZE_ACTIVELIST_LOG-1:0]      alID_i [0:`DISPATCH_WIDTH-1],
    input  [`SIZE_LSQ_LOG-1:0]             lsqID_i [0:`DISPATCH_WIDTH-1],

    /* Payload and Destination of instructions */
    output payloadPkt                      rrPacket_o [0:`ISSUE_WIDTH-1],

`ifdef PERF_MON
    output reg [`SIZE_LSQ_LOG:0]           reqCount_o,
    output reg [`SIZE_LSQ_LOG:0]           issuedCount_o,
`endif

    /* Bypass tags + valid bit for LD/ST */
    input  [`SIZE_PHYSICAL_LOG:0]          rsr0Tag_i,

    /* Count of Valid Issue Q Entries goes to Dispatch */
    output [`SIZE_ISSUEQ_LOG:0]            cntInstIssueQ_o
);


/* Newly definied register. This has been shifteg from the RegRead Stage*/	//modified
reg  [`SIZE_PHYSICAL_TABLE-1:0]        phyRegValidVect;

/************************************************************************************
 *  exePipeVect: FU type of the instructions in the Issue Queue. This information is
 *             used for selecting ready instructions for scheduling per functional
 *             unit.
 ************************************************************************************/
//reg  [`ISSUE_WIDTH_LOG-1:0]            exePipeVect [`SIZE_ISSUEQ-1:0];
reg  [`SIZE_ISSUEQ-1:0][`ISSUE_WIDTH_LOG-1:0]  exePipeVect;


/************************************************************************************
 *  iqScheduledVect: 1-bit indicating whether the issue queue entry has been issued
 *                    for execution.
 ************************************************************************************/
//reg  [`SIZE_ISSUEQ-1:0]                iqScheduledVect;


/************************************************************************************
 *  phyDestVect: Used by the select tree to mux tags down so that wakeup can be
 *  done a cycle earlier. 
 *  Every entry is read every cycle by the select tree
 ***********************************************************************************/
//reg [`SIZE_PHYSICAL_LOG-1:0]           phyDestVect [`SIZE_ISSUEQ-1:0];
//phys_reg                               phyDestVect [`SIZE_ISSUEQ-1:0];
phys_reg  [`SIZE_ISSUEQ-1:0]             phyDestVect;

/***********************************************************************************/

/* IQ entries for incoming instructions */
iqEntryPkt                             freeEntry_t [0:`DISPATCH_WIDTH-1];
iqEntryPkt                             freeEntry   [0:`DISPATCH_WIDTH-1];

/* IQ entries of selected instructions */
iqEntryPkt                             grantedEntry    [0:`ISSUE_WIDTH-1];
iqEntryPkt                             grantedEntry_t  [0:`ISSUE_WIDTH-1];
iqEntryPkt                             selectedEntry   [0:`ISSUE_WIDTH-1];
wire                                   selectedEntryValid   [0:`ISSUE_WIDTH-1];

/* IQ entries being freed (not all granted entries get freed together) */
iqEntryPkt                             freedEntry      [0:`IQ_FREEING_WIDTH-1];

reg     [0:`DISPATCH_WIDTH-1]          src1RsrMatch;
reg     [0:`DISPATCH_WIDTH-1]          src2RsrMatch;
reg     [0:`DISPATCH_WIDTH-1]          src1RsrMatch_t  [0:`ISSUE_WIDTH-1];
reg     [0:`DISPATCH_WIDTH-1]          src2RsrMatch_t  [0:`ISSUE_WIDTH-1];
reg     [0:`DISPATCH_WIDTH-1]          src1RsrMatch_lane  [0:`ISSUE_WIDTH-1];
reg     [0:`DISPATCH_WIDTH-1]          src2RsrMatch_lane  [0:`ISSUE_WIDTH-1];

/* newSrcReady sets the srcReady bits of the dispatched instructions */
reg                                    newSrc1Ready    [0:`DISPATCH_WIDTH-1];
reg                                    newSrc2Ready    [0:`DISPATCH_WIDTH-1];



reg  [`SIZE_ISSUEQ-1:0]                reqVect;


/* Wires to "alias" the RSR + valid bit*/
`ifdef DYNAMIC_CONFIG
  wire                                   payloadRamReady_o;
  phys_reg                               rsrTag_t [0:`ISSUE_WIDTH-1];
`else
  phys_reg                               rsrTag_t [0:`ISSUE_WIDTH-1];
`endif
phys_reg                               rsrTag   [0:`ISSUE_WIDTH-1];


reg [`SIZE_ISSUEQ-1:0] ISsimple;
reg ISsimple_t [0:`ISSUE_WIDTH-1];


// Counting the number of active DISPATCH lanes
// Should be 1 bit wider as it should hold values from 1 to `DISPATCH_WIDTH
// RBRC
reg [`DISPATCH_WIDTH_LOG:0] numDispatchLaneActive;
//reg [`ISSUE_WIDTH_LOG:0]    numIssueLaneActive;
always_comb
begin
`ifdef DYNAMIC_CONFIG_AND_WIDTH 
  int i;
  numDispatchLaneActive = 0;
  for(i = 0; i < `DISPATCH_WIDTH; i++)
    numDispatchLaneActive = numDispatchLaneActive + dispatchLaneActive_i[i];

  //numIssueLaneActive = 0;
  //for(i = 0; i < `ISSUE_WIDTH; i++)
  //  numIssueLaneActive = numIssueLaneActive + issueLaneActive_i[i];

`else
  numDispatchLaneActive = `DISPATCH_WIDTH;
  //numIssueLaneActive    = `ISSUE_WIDTH;
`endif
end

reg [`SIZE_ISSUEQ_LOG:0] iqSize;
localparam IQ_PARTITION_SIZE = `SIZE_ISSUEQ/`STRUCT_PARTS;
always_comb
begin
`ifdef DYNAMIC_CONFIG_AND_SIZE 
  case(iqPartitionActive_i)
    4'b1111:iqSize =  IQ_PARTITION_SIZE*4;
    4'b0111:iqSize =  IQ_PARTITION_SIZE*3;
    4'b0011:iqSize =  IQ_PARTITION_SIZE*2;
    4'b0001:iqSize =  IQ_PARTITION_SIZE*1;
    default:iqSize = `SIZE_ISSUEQ; 
  endcase

`else
  iqSize  = `SIZE_ISSUEQ;
`endif    
end


/************************************************************************************
 * Issue Queue Free List.
 *   A circular buffer that keeps tracks of free IQ entries.
 ************************************************************************************/

IssueQFreeList issueQfreelist (

    .clk                (clk),
    .iqSize_i           (iqSize),
    .numDispatchLaneActive_i (numDispatchLaneActive),
    //.numIssueLaneActive_i    (numIssueLaneActive),

`ifdef DYNAMIC_CONFIG
    .reset              (reset | flush_i | reconfigureCore_i),
    .dispatchLaneActive_i(dispatchLaneActive_i),
    .issueLaneActive_i (issueLaneActive_i),
    .iqPartitionActive_i(iqPartitionActive_i),
`else    
    .reset              (reset | flush_i),
`endif    

    .backEndReady_i     (backEndReady_i),

    /* IQ entries selected for issuing this cycle */
    .grantedEntry_i     (selectedEntry),

    /* IQ entries freed this cycle. Not all granted entries are freed. */
    .freedEntry_o       (freedEntry),

    /* Free IQ entries for the incoming instructions. */
    .freeEntry_o        (freeEntry_t),

    /* Count of valid IQ entries. Goes to dispatch */
    .cntInstIssueQ_o    (cntInstIssueQ_o)
);

`ifdef DYNAMIC_CONFIG
  genvar wr;
  generate
	  for (wr = 0; wr < `DISPATCH_WIDTH; wr = wr + 1)
    begin:CLAMP_WR
        PGIsolationCell #(
          .WIDTH(`SIZE_ISSUEQ_LOG+1)
        ) wrAddrClamp
        (
          .clampEn(~dispatchLaneActive_i[wr]),
          .signalIn(freeEntry_t[wr]),
          .signalOut(freeEntry[wr]),
          .clampValue({(`SIZE_ISSUEQ_LOG+1){1'b0}})
        );
    end
  endgenerate
`else
  always_comb
  begin
    int wr;
	  for (wr = 0; wr < `DISPATCH_WIDTH; wr = wr + 1)
	  begin
      freeEntry[wr]   = freeEntry_t[wr]  ;
    end
  end
`endif

//IssueQFreeList_t issueQfreelist_t (
//
//    .clk                (clk),
//    .iqSize_i           (iqSize),
//    .numDispatchLaneActive_i (numDispatchLaneActive),
//
//`ifdef DYNAMIC_CONFIG
//    .reset              (reset | flush_i | reconfigureCore_i),
//    .dispatchLaneActive_i(dispatchLaneActive_i),
//    .issueLaneActive_i (issueLaneActive_i),
//    .iqPartitionActive_i(iqPartitionActive_i),
//`else    
//    .reset              (reset | flush_i),
//`endif    
//
//    .backEndReady_i     (backEndReady_i),
//
//    /* IQ entries selected for issuing this cycle */
//    .grantedEntry_i     (selectedEntry),
//
//    /* IQ entries freed this cycle. Not all granted entries are freed. */
//    .freedEntry_o       (),
//
//    /* Free IQ entries for the incoming instructions. */
//    .freeEntry_o        (),
//
//    /* Count of valid IQ entries. Goes to dispatch */
//    .cntInstIssueQ_o    ()
//);



/************************************************************************************
 * Set and clear the physical register valid bits. Set the bits of tags broadcasted 
 * by the RSR. Clear the bits of incoming instruction's destination register (if valid)
 ************************************************************************************/
always_ff @(posedge clk or posedge reset)
begin:UPDATE_PHY_REG
    int i;

    if (reset)
    begin
        for (i = 0; i < `SIZE_RMT; i++)
        begin
            phyRegValidVect[i] <= 1'b1;
        end

        for (i = `SIZE_RMT; i < `SIZE_PHYSICAL_TABLE; i++)
        begin
            phyRegValidVect[i] <= 1'b0;
        end
    end

    else if (exceptionFlag_i)
    begin
        for (i = 0; i < `SIZE_RMT; i++)
        begin
            phyRegValidVect[i] <= 1'b1;
        end

        for (i = `SIZE_RMT; i < `SIZE_PHYSICAL_TABLE; i++)
        begin
            phyRegValidVect[i] <= 1'b0;
        end
    end

`ifdef DYNAMIC_CONFIG    
    else if (reconfigureCore_i)
    begin
        for (i = 0; i < `SIZE_RMT; i++)
        begin
            phyRegValidVect[i] <= 1'b1;
        end

        for (i = `SIZE_RMT; i < `SIZE_PHYSICAL_TABLE; i++)
        begin
            phyRegValidVect[i] <= 1'b0;
        end
    end
`endif    

    else
    begin

        /* Clear ready bit of incoming instruction's dest reg */
        for (i = 0; i < `DISPATCH_WIDTH; i++)
        begin
            // The valid bit in an inactive dispatch lane should never be 1
        `ifdef DYNAMIC_CONFIG            
            if (phyDest_i[i].valid & dispatchLaneActive_i[i]) 
        `else              
            if (phyDest_i[i].valid) 
        `endif              
            begin
                phyRegValidVect[phyDest_i[i].reg_id] <= 1'b0;
            end
        end


        /* Set ready bit of instructions leaving the RSR */
        for (i = 0; i < `ISSUE_WIDTH; i++)
        begin
            if (rsrTag[i].valid)  
            begin
                phyRegValidVect[rsrTag[i].reg_id]    <= 1'b1;
            end
        end
    end
end


/************************************************************************************
 * ISSUEQ_PAYLOAD: Has all the necessary information required by function unit to
 *  execute the instruction. Implemented as payloadRAM
 *  (Source registers, LD/ST queue ID, Active List ID, Destination register,
 *  Immediate data, LD/ST data size, Opcode, Program counter, Predicted
 *  Target Address, Ctiq Tag, Predicted Branch direction)
 ************************************************************************************/

payloadPkt                             payloadData   [0:`ISSUE_WIDTH-1];

payloadPkt                             payloadWrData [0:`DISPATCH_WIDTH-1];
reg                                    payloadWe     [0:`DISPATCH_WIDTH-1];


always_comb
begin
    int i;
    for (i = 0; i < `DISPATCH_WIDTH; i++)
    begin
        payloadWrData[i].seqNo    = iqPacket_i[i].seqNo;
        payloadWrData[i].pc       = iqPacket_i[i].pc;
        payloadWrData[i].opcode   = iqPacket_i[i].opcode;
        payloadWrData[i].logDest  = iqPacket_i[i].logDest;
        payloadWrData[i].phyDest  = iqPacket_i[i].phyDest;
        payloadWrData[i].phySrc2  = iqPacket_i[i].phySrc2;
        payloadWrData[i].phySrc1  = iqPacket_i[i].phySrc1;
        payloadWrData[i].immed    = iqPacket_i[i].immed;
        payloadWrData[i].lsqID    = lsqID_i[i];
        payloadWrData[i].alID     = alID_i[i];
        /* payloadWrData[i].ldstSize = iqPacket_i[i].ldstSize; */
        payloadWrData[i].predNPC  = iqPacket_i[i].predNPC;
        payloadWrData[i].isSimple = iqPacket_i[i].isSimple;
        payloadWrData[i].ctrlType = iqPacket_i[i].ctrlType;
        payloadWrData[i].ctiID    = iqPacket_i[i].ctiID;
        payloadWrData[i].predDir  = iqPacket_i[i].predDir;
        payloadWrData[i].valid    = 0;
      `ifdef DYNAMIC_CONFIG_AND_WIDTH
        payloadWe[i]              = backEndReady_i & dispatchLaneActive_i[i];
      `else
        payloadWe[i]              = backEndReady_i;
      `endif
    end
end


IQPAYLOAD_RAM #(
    .DEPTH       (`SIZE_ISSUEQ),
    .INDEX       (`SIZE_ISSUEQ_LOG),
    .WIDTH       (`PAYLOAD_PKT_SIZE)
)

payloadRAM (

    .addr0_i    (grantedEntry[0].id),
    .data0_o    (payloadData[0]),

    `ifdef ISSUE_TWO_WIDE
    .addr1_i    (grantedEntry[1].id),
    .data1_o    (payloadData[1]),
    `endif

    `ifdef ISSUE_THREE_WIDE
    .addr2_i    (grantedEntry[2].id),
    .data2_o    (payloadData[2]),
    `endif

    `ifdef ISSUE_FOUR_WIDE
    .addr3_i    (grantedEntry[3].id),
    .data3_o    (payloadData[3]),
    `endif

    `ifdef ISSUE_FIVE_WIDE
    .addr4_i    (grantedEntry[4].id),
    .data4_o    (payloadData[4]),
    `endif

    `ifdef ISSUE_SIX_WIDE
    .addr5_i    (grantedEntry[5].id),
    .data5_o    (payloadData[5]),
    `endif

    `ifdef ISSUE_SEVEN_WIDE
    .addr6_i    (grantedEntry[6].id),
    .data6_o    (payloadData[6]),
    `endif

    `ifdef ISSUE_EIGHT_WIDE
    .addr7_i    (grantedEntry[7].id),
    .data7_o    (payloadData[7]),
    `endif


    .addr0wr_i  (freeEntry[0].id),
    .data0wr_i  (payloadWrData[0]),
    .we0_i      (payloadWe[0]),

    `ifdef DISPATCH_TWO_WIDE
    .addr1wr_i  (freeEntry[1].id),
    .data1wr_i  (payloadWrData[1]),
    .we1_i      (payloadWe[1]),
    `endif

    `ifdef DISPATCH_THREE_WIDE
    .addr2wr_i  (freeEntry[2].id),
    .data2wr_i  (payloadWrData[2]),
    .we2_i      (payloadWe[2]),
    `endif

    `ifdef DISPATCH_FOUR_WIDE
    .addr3wr_i  (freeEntry[3].id),
    .data3wr_i  (payloadWrData[3]),
    .we3_i      (payloadWe[3]),
    `endif

    `ifdef DISPATCH_FIVE_WIDE
    .addr4wr_i  (freeEntry[4].id),
    .data4wr_i  (payloadWrData[4]),
    .we4_i      (payloadWe[4]),
    `endif

    `ifdef DISPATCH_SIX_WIDE
    .addr5wr_i  (freeEntry[5].id),
    .data5wr_i  (payloadWrData[5]),
    .we5_i      (payloadWe[5]),
    `endif

    `ifdef DISPATCH_SEVEN_WIDE
    .addr6wr_i  (freeEntry[6].id),
    .data6wr_i  (payloadWrData[6]),
    .we6_i      (payloadWe[6]),
    `endif

    `ifdef DISPATCH_EIGHT_WIDE
    .addr7wr_i  (freeEntry[7].id),
    .data7wr_i  (payloadWrData[7]),
    .we7_i      (payloadWe[7]),
    `endif

`ifdef DYNAMIC_CONFIG    
    .dispatchLaneActive_i (dispatchLaneActive_i),
    .issueLaneActive_i    (issueLaneActive_i),
    .iqPartitionActive_i  (iqPartitionActive_i),
    .payloadRamReady_o    (payloadRamReady),
`endif    

    .clk        (clk),
    .reset      (reset)
);


/************************************************************************************
 * WAKEUP
 *   (1) Search the src1 and src2 CAMs for entries matching the RSR tags
 *   (2) OR the match vectors for all tags
 *   (3) Determine the ready bits for incoming instruction's sources
 *   (4) Shift the ready bits to their assigned entries
 *   (5) Update src1ValidVect and src2ValidVect with the vectors from (2) and (4)
 ************************************************************************************/

reg  [`SIZE_ISSUEQ-1:0]                src1MatchVect_t [0:`ISSUE_WIDTH-1];
reg  [`SIZE_ISSUEQ-1:0]                src1MatchVect;

reg  [`SIZE_ISSUEQ-1:0]                src2MatchVect_t [0:`ISSUE_WIDTH-1];
reg  [`SIZE_ISSUEQ-1:0]                src2MatchVect;


/* (1) Search the src1 CAM for entries matching the RSR tags */
WAKEUP_CAM #(
    .DEPTH       (`SIZE_ISSUEQ),
    .INDEX       (`SIZE_ISSUEQ_LOG),
    .WIDTH       (`SIZE_PHYSICAL_LOG)
)

src1Cam (

    .tag0_i      (rsrTag[0].reg_id),
    .vect0_o     (src1MatchVect_t[0]),

    `ifdef ISSUE_TWO_WIDE
    .tag1_i      (rsrTag[1].reg_id),
    .vect1_o     (src1MatchVect_t[1]),
    `endif

    `ifdef ISSUE_THREE_WIDE
    .tag2_i      (rsrTag[2].reg_id),
    .vect2_o     (src1MatchVect_t[2]),
    `endif

    `ifdef ISSUE_FOUR_WIDE
    .tag3_i      (rsrTag[3].reg_id),
    .vect3_o     (src1MatchVect_t[3]),
    `endif

    `ifdef ISSUE_FIVE_WIDE
    .tag4_i      (rsrTag[4].reg_id),
    .vect4_o     (src1MatchVect_t[4]),
    `endif

    `ifdef ISSUE_SIX_WIDE
    .tag5_i      (rsrTag[5].reg_id),
    .vect5_o     (src1MatchVect_t[5]),
    `endif

    `ifdef ISSUE_SEVEN_WIDE
    .tag6_i      (rsrTag[6].reg_id),
    .vect6_o     (src1MatchVect_t[6]),
    `endif

    `ifdef ISSUE_EIGHT_WIDE
    .tag7_i      (rsrTag[7].reg_id),
    .vect7_o     (src1MatchVect_t[7]),
    `endif


    .wrAddr0_i   (freeEntry[0].id),
    .wrData0_i   (iqPacket_i[0].phySrc1),
    .we0_i       (backEndReady_i),

    `ifdef DISPATCH_TWO_WIDE
    .wrAddr1_i   (freeEntry[1].id),
    .wrData1_i   (iqPacket_i[1].phySrc1),
    .we1_i       (backEndReady_i),
    `endif

    `ifdef DISPATCH_THREE_WIDE
    .wrAddr2_i   (freeEntry[2].id),
    .wrData2_i   (iqPacket_i[2].phySrc1),
    .we2_i       (backEndReady_i),
    `endif

    `ifdef DISPATCH_FOUR_WIDE
    .wrAddr3_i   (freeEntry[3].id),
    .wrData3_i   (iqPacket_i[3].phySrc1),
    .we3_i       (backEndReady_i),
    `endif

    `ifdef DISPATCH_FIVE_WIDE
    .wrAddr4_i   (freeEntry[4].id),
    .wrData4_i   (iqPacket_i[4].phySrc1),
    .we4_i       (backEndReady_i),
    `endif

    `ifdef DISPATCH_SIX_WIDE
    .wrAddr5_i   (freeEntry[5].id),
    .wrData5_i   (iqPacket_i[5].phySrc1),
    .we5_i       (backEndReady_i),
    `endif

    `ifdef DISPATCH_SEVEN_WIDE
    .wrAddr6_i   (freeEntry[6].id),
    .wrData6_i   (iqPacket_i[6].phySrc1),
    .we6_i       (backEndReady_i),
    `endif

    `ifdef DISPATCH_EIGHT_WIDE
    .wrAddr7_i   (freeEntry[7].id),
    .wrData7_i   (iqPacket_i[7].phySrc1),
    .we7_i       (backEndReady_i),
    `endif

`ifdef DYNAMIC_CONFIG    
    .dispatchLaneActive_i(dispatchLaneActive_i),
    .issueLaneActive_i(issueLaneActive_i),
    .iqPartitionActive_i  (iqPartitionActive_i),
`endif    

    .clk         (clk),
    .reset       (reset)
);


WAKEUP_CAM #(
    .DEPTH       (`SIZE_ISSUEQ),
    .INDEX       (`SIZE_ISSUEQ_LOG),
    .WIDTH       (`SIZE_PHYSICAL_LOG)
)

src2Cam (

    .tag0_i      (rsrTag[0].reg_id),
    .vect0_o     (src2MatchVect_t[0]),

    `ifdef ISSUE_TWO_WIDE
    .tag1_i      (rsrTag[1].reg_id),
    .vect1_o     (src2MatchVect_t[1]),
    `endif

    `ifdef ISSUE_THREE_WIDE
    .tag2_i      (rsrTag[2].reg_id),
    .vect2_o     (src2MatchVect_t[2]),
    `endif

    `ifdef ISSUE_FOUR_WIDE
    .tag3_i      (rsrTag[3].reg_id),
    .vect3_o     (src2MatchVect_t[3]),
    `endif

    `ifdef ISSUE_FIVE_WIDE
    .tag4_i      (rsrTag[4].reg_id),
    .vect4_o     (src2MatchVect_t[4]),
    `endif

    `ifdef ISSUE_SIX_WIDE
    .tag5_i      (rsrTag[5].reg_id),
    .vect5_o     (src2MatchVect_t[5]),
    `endif

    `ifdef ISSUE_SEVEN_WIDE
    .tag6_i      (rsrTag[6].reg_id),
    .vect6_o     (src2MatchVect_t[6]),
    `endif

    `ifdef ISSUE_EIGHT_WIDE
    .tag7_i      (rsrTag[7].reg_id),
    .vect7_o     (src2MatchVect_t[7]),
    `endif


    .wrAddr0_i   (freeEntry[0].id),
    .wrData0_i   (iqPacket_i[0].phySrc2),
    .we0_i       (backEndReady_i),

    `ifdef DISPATCH_TWO_WIDE
    .wrAddr1_i   (freeEntry[1].id),
    .wrData1_i   (iqPacket_i[1].phySrc2),
    .we1_i       (backEndReady_i),
    `endif

    `ifdef DISPATCH_THREE_WIDE
    .wrAddr2_i   (freeEntry[2].id),
    .wrData2_i   (iqPacket_i[2].phySrc2),
    .we2_i       (backEndReady_i),
    `endif

    `ifdef DISPATCH_FOUR_WIDE
    .wrAddr3_i   (freeEntry[3].id),
    .wrData3_i   (iqPacket_i[3].phySrc2),
    .we3_i       (backEndReady_i),
    `endif

    `ifdef DISPATCH_FIVE_WIDE
    .wrAddr4_i   (freeEntry[4].id),
    .wrData4_i   (iqPacket_i[4].phySrc2),
    .we4_i       (backEndReady_i),
    `endif

    `ifdef DISPATCH_SIX_WIDE
    .wrAddr5_i   (freeEntry[5].id),
    .wrData5_i   (iqPacket_i[5].phySrc2),
    .we5_i       (backEndReady_i),
    `endif

    `ifdef DISPATCH_SEVEN_WIDE
    .wrAddr6_i   (freeEntry[6].id),
    .wrData6_i   (iqPacket_i[6].phySrc2),
    .we6_i       (backEndReady_i),
    `endif

    `ifdef DISPATCH_EIGHT_WIDE
    .wrAddr7_i   (freeEntry[7].id),
    .wrData7_i   (iqPacket_i[7].phySrc2),
    .we7_i       (backEndReady_i),
    `endif

`ifdef DYNAMIC_CONFIG    
    .dispatchLaneActive_i(dispatchLaneActive_i),
    .issueLaneActive_i(issueLaneActive_i),
    .iqPartitionActive_i  (iqPartitionActive_i),
`endif    

    .clk         (clk),
    .reset       (reset)
);


// TODO: This logic can go inside the WAKEUP_CAM and become partitioned
/* (2) OR the match vectors for all tags */
always_comb
begin
    int i;

    src1MatchVect = 0;
    src2MatchVect = 0;

    for (i = 0; i < `ISSUE_WIDTH; i++)
    begin
        src1MatchVect = src1MatchVect | (src1MatchVect_t[i] & {`SIZE_ISSUEQ{rsrTag[i].valid}});
        src2MatchVect = src2MatchVect | (src2MatchVect_t[i] & {`SIZE_ISSUEQ{rsrTag[i].valid}});
    end
end

/* Create payload packet using updated branch mask and read payload */
always_comb
begin
    int i;

    for (i = 0; i < `ISSUE_WIDTH; i++)
    begin
        rrPacket_o[i]        = payloadData[i];
        rrPacket_o[i].valid  = grantedEntry[i].valid;
    end
end





`ifndef DYNAMIC_CONFIG




  reg  [`SIZE_ISSUEQ-1:0]                freedVect;
  reg  [`SIZE_ISSUEQ-1:0]                freeVect;

  wire [`ISSUE_WIDTH-1:0]                ignoreSimple;

  phys_reg                               grantedDest     [0:`ISSUE_WIDTH-1];
  reg  [`SIZE_ISSUEQ-1:0]                grantedVect;

  /************************************************************************************
   *  iqValidVect: 1-bit indicating validity of each entry in the Issue Queue.
   ************************************************************************************/
  reg  [`SIZE_ISSUEQ-1:0]                iqValidVect;

  /* srcValidVect indicates whether operands are ready or not */
  reg  [`SIZE_ISSUEQ-1:0]                src1ValidVect;
  reg  [`SIZE_ISSUEQ-1:0]                src1Valid_t1;
  
  reg  [`SIZE_ISSUEQ-1:0]                src2ValidVect;
  reg  [`SIZE_ISSUEQ-1:0]                src2Valid_t1;


  /************************************************************************************
   * (3) Set the incoming instruction's source operand ready bit if any of these
   *     conditions are true:
   *       (i)   A broadcasted RSR tag matches
   *       (ii)  The phyRegValidVect entry is set
   *       (iii) The source valid bit is not set (no source reg)
   ************************************************************************************/
  
  // NOTE: This is the logic that checks the packets written into the
  // issue queue for a match against the RSR tags so that they can
  // be woken up in the very next cycle if necessary. The match vector
  // passes into the valid vector in the same cycle as they are
  // dispatched and can be selected and issued in the next cycle if possible. 

  always_comb
  begin:CHECK_NEW_INSTS_SOURCE_OPERAND
      int i;
  
      for (i = 0; i < `DISPATCH_WIDTH; i++)
      begin
          src1RsrMatch[i]   = 0;
          src2RsrMatch[i]   = 0;
      end
  
  
      /************************************************************************************
       * (i) Check the broadcasted RSR tags for a match.
       * This is the common "If reading a location being written into this cycle, bypass the
       * 'being written into' value instead of reading the currently stored value" logic.
       ************************************************************************************/
      // TODO: Part of IssueQLane Each creating one DISPATCH_WIDTH long vector. These ISSUE_WIDTH
      // number of vectors are then ORed together here to form the src1RsrMatch
      for (i = 0; i < `ISSUE_WIDTH; i++)
      begin
          src1RsrMatch[0] = src1RsrMatch[0] | ((iqPacket_i[0].phySrc1 == rsrTag[i].reg_id) & rsrTag[i].valid);
          src2RsrMatch[0] = src2RsrMatch[0] | ((iqPacket_i[0].phySrc2 == rsrTag[i].reg_id) & rsrTag[i].valid);
  
          `ifdef DISPATCH_TWO_WIDE
          src1RsrMatch[1] = src1RsrMatch[1] | ((iqPacket_i[1].phySrc1 == rsrTag[i].reg_id) & rsrTag[i].valid);
          src2RsrMatch[1] = src2RsrMatch[1] | ((iqPacket_i[1].phySrc2 == rsrTag[i].reg_id) & rsrTag[i].valid);
          `endif
  
          `ifdef DISPATCH_THREE_WIDE
          src1RsrMatch[2] = src1RsrMatch[2] | ((iqPacket_i[2].phySrc1 == rsrTag[i].reg_id) & rsrTag[i].valid);
          src2RsrMatch[2] = src2RsrMatch[2] | ((iqPacket_i[2].phySrc2 == rsrTag[i].reg_id) & rsrTag[i].valid);
          `endif
  
          `ifdef DISPATCH_FOUR_WIDE
          src1RsrMatch[3] = src1RsrMatch[3] | ((iqPacket_i[3].phySrc1 == rsrTag[i].reg_id) & rsrTag[i].valid);
          src2RsrMatch[3] = src2RsrMatch[3] | ((iqPacket_i[3].phySrc2 == rsrTag[i].reg_id) & rsrTag[i].valid);
          `endif
  
          `ifdef DISPATCH_FIVE_WIDE
          src1RsrMatch[4] = src1RsrMatch[4] | ((iqPacket_i[4].phySrc1 == rsrTag[i].reg_id) & rsrTag[i].valid);
          src2RsrMatch[4] = src2RsrMatch[4] | ((iqPacket_i[4].phySrc2 == rsrTag[i].reg_id) & rsrTag[i].valid);
          `endif
  
          `ifdef DISPATCH_SIX_WIDE
          src1RsrMatch[5] = src1RsrMatch[5] | ((iqPacket_i[5].phySrc1 == rsrTag[i].reg_id) & rsrTag[i].valid);
          src2RsrMatch[5] = src2RsrMatch[5] | ((iqPacket_i[5].phySrc2 == rsrTag[i].reg_id) & rsrTag[i].valid);
          `endif
  
          `ifdef DISPATCH_SEVEN_WIDE
          src1RsrMatch[6] = src1RsrMatch[6] | ((iqPacket_i[6].phySrc1 == rsrTag[i].reg_id) & rsrTag[i].valid);
          src2RsrMatch[6] = src2RsrMatch[6] | ((iqPacket_i[6].phySrc2 == rsrTag[i].reg_id) & rsrTag[i].valid);
          `endif
  
          `ifdef DISPATCH_EIGHT_WIDE
          src1RsrMatch[7] = src1RsrMatch[7] | ((iqPacket_i[7].phySrc1 == rsrTag[i].reg_id) & rsrTag[i].valid);
          src2RsrMatch[7] = src2RsrMatch[7] | ((iqPacket_i[7].phySrc2 == rsrTag[i].reg_id) & rsrTag[i].valid);
          `endif
      end
  
  
      for (i = 0; i < `DISPATCH_WIDTH; i++)
      begin
  
          newSrc1Ready[i] = ( src1RsrMatch[i]                        || /* (i)   */
                              phyRegValidVect[iqPacket_i[i].phySrc1] || /* (ii)  */
                              ~iqPacket_i[i].phySrc1Valid)           ?  /* (iii) */
                              1'h1 : 1'h0;
  
          newSrc2Ready[i] = ( src2RsrMatch[i]                        || /* (i)   */
                              phyRegValidVect[iqPacket_i[i].phySrc2] || /* (ii)  */
                              ~iqPacket_i[i].phySrc2Valid)           ?  /* (iii) */
                              1'h1 : 1'h0;
  
      end
  end



  /************************************************************************************
   * (4) Update the ready bit in the IQ for the incoming instructions by
   *     shifting newSrcReady to the free entry given to the instruction
   ************************************************************************************/
  // TODO: Part of IssueQueue Partition
  always_comb
  begin: UPDATE_SRC_READY_BIT
      int i;
  
      src1Valid_t1 = 0;
      src2Valid_t1 = 0;
  
      /* TODO: Try rewriting this */
      // This builds an explicit priority logic to 
      // wirte into the valid registers with lower
      // lanes having higher priority. This inspite
      // of the fact that all the freeEntry.id s are
      // unique.
      for (i = 0; i < `SIZE_ISSUEQ; i++)
      begin
          if(backEndReady_i & (i == freeEntry[0].id))
          begin
              src1Valid_t1[i]  =  newSrc1Ready[0];
              src2Valid_t1[i]  =  newSrc2Ready[0];
          end
  
          `ifdef DISPATCH_TWO_WIDE
          else if(backEndReady_i & (i == freeEntry[1].id))
          begin
              src1Valid_t1[i]  =  newSrc1Ready[1];
              src2Valid_t1[i]  =  newSrc2Ready[1];
          end
          `endif
  
          `ifdef DISPATCH_THREE_WIDE
          else if(backEndReady_i & (i == freeEntry[2].id))
          begin
              src1Valid_t1[i]  =  newSrc1Ready[2];
              src2Valid_t1[i]  =  newSrc2Ready[2];
          end
          `endif
  
          `ifdef DISPATCH_FOUR_WIDE
          else if(backEndReady_i & (i == freeEntry[3].id))
          begin
              src1Valid_t1[i]  =  newSrc1Ready[3];
              src2Valid_t1[i]  =  newSrc2Ready[3];
          end
          `endif
  
          `ifdef DISPATCH_FIVE_WIDE
          else if(backEndReady_i & (i == freeEntry[4].id))
          begin
              src1Valid_t1[i]  =  newSrc1Ready[4];
              src2Valid_t1[i]  =  newSrc2Ready[4];
          end
          `endif
  
          `ifdef DISPATCH_SIX_WIDE
          else if(backEndReady_i & (i == freeEntry[5].id))
          begin
              src1Valid_t1[i]  =  newSrc1Ready[5];
              src2Valid_t1[i]  =  newSrc2Ready[5];
          end
          `endif
  
          `ifdef DISPATCH_SEVEN_WIDE
          else if(backEndReady_i & (i == freeEntry[6].id))
          begin
              src1Valid_t1[i]  =  newSrc1Ready[6];
              src2Valid_t1[i]  =  newSrc2Ready[6];
          end
          `endif
  
          `ifdef DISPATCH_EIGHT_WIDE
          else if(backEndReady_i & (i == freeEntry[7].id))
          begin
              src1Valid_t1[i]  =  newSrc1Ready[7];
              src2Valid_t1[i]  =  newSrc2Ready[7];
          end
          `endif
  
          else
          begin
              src1Valid_t1[i]  =  0;
              src2Valid_t1[i]  =  0;
          end
      end
  end
  
  
  /************************************************************************************
   * (5) Update src1ValidVect and src2ValidVect 
   ************************************************************************************/
  // TODO: Part of IssueQueue Partition
  always_ff @(posedge clk or posedge reset)
  begin
      if (reset)
      begin
          src1ValidVect  <= 0;
          src2ValidVect  <= 0;
      end
      else if (flush_i)
      begin
          src1ValidVect  <= 0;
          src2ValidVect  <= 0;
      end
      else
      begin
          src1ValidVect  <= (src1ValidVect | src1MatchVect) & iqValidVect | src1Valid_t1;
          src2ValidVect  <= (src2ValidVect | src2MatchVect) & iqValidVect | src2Valid_t1;
      end
  end



  /************************************************************************************
   * Get vectors for updating iqValidVect and iqScheduledVect 
   * (1) Free entries assigned to incoming instructions
   * (2) Entries freed by the IQ free list
   * (3) Entries granted by the select logic
   ************************************************************************************/
  // TODO: Part of IssueQueue Partition
  always_comb
  begin: PREPARE_VALID_ARRAY_NORMAL
      int i, j;
  
      reg                    freeEntryMatch;
      reg                    freedEntryMatch;
      reg                    grantedEntryMatch;
  
      freeVect   = 0;
      freedVect  = 0;
      grantedVect = 0;
  
  
  // TODO: This minimal logic should work but its not    
  //    /* (1) Set entries assigned to incoming instructions to 1 */
  //    // TODO: Ladder logic
  //    for (j = 0; j < `DISPATCH_WIDTH; j++)
  //    begin
  //`ifdef DYNAMIC_CONFIG
  //      freeVect[freeEntry[j].id] = 1'b1 & dispatchLaneActive_i[j];
  //`else
  //      freeVect[freeEntry[j].id] = 1'b1;
  //`endif
  //    end
  //
  //    /* (2) Set freed entries to 0 */
  //    for (j = 0; j < `ISSUE_WIDTH; j++)
  //    begin
  //      if(freedEntry[j].valid)
  //        freedVect[freedEntry[j].id] = 1'b1;
  //    end
  //
  //    /* (3) Set granted entries to 1 */
  //    for (j = 0; j < `ISSUE_WIDTH; j++)
  //    begin
  //      if(selectedEntry[j].valid)
  //        grantedVect[selectedEntry[j].id] = 1'b1;
  //    end
  //end
  
      
      /* (1) Set entries assigned to incoming instructions to 1 */
      for (i = 0; i < `SIZE_ISSUEQ; i++)
      begin
  
          freeEntryMatch = 0;
  
          // TODO: Ladder logic
          for (j = 0; j < `DISPATCH_WIDTH; j++)
          begin
  //`ifdef DYNAMIC_CONFIG
  //            freeEntryMatch = freeEntryMatch || ((i == freeEntry[j].id) & dispatchLaneActive_i[j]);
  //`else
              freeEntryMatch = freeEntryMatch || (i == freeEntry[j].id);
  //`endif
          end
  
          if (backEndReady_i && freeEntryMatch)
          begin
              freeVect[i] = 1'h1;
          end
  
          else
          begin
              freeVect[i] = 1'h0;
          end
      end
  
      /* (2) Set freed entries to 0 */
      for (i = 0; i < `SIZE_ISSUEQ; i++)
      begin
  
          freedEntryMatch = 0;
  
          for (j = 0; j < `IQ_FREEING_WIDTH; j++)
          begin
              freedEntryMatch = freedEntryMatch || (freedEntry[j].valid & (i == freedEntry[j].id));
          end
  
          if (freedEntryMatch)
          begin
              freedVect[i] = 1'h1;
          end
  
          else
          begin
              freedVect[i] = 1'h0;
          end
      end
  
      /* (2) Set granted entries to 1 */
      for (i = 0; i < `SIZE_ISSUEQ; i++)
      begin
  
          grantedEntryMatch = 0;
  
          for (j = 0; j < `ISSUE_WIDTH; j++)
          begin
              grantedEntryMatch = grantedEntryMatch || (selectedEntry[j].valid & (i == selectedEntry[j].id));
          end
  
          if (grantedEntryMatch)
          begin
              grantedVect[i] = 1'h1;
          end
  
          else
          begin
              grantedVect[i] = 1'h0;
          end
      end
  end
  
  /************************************************************************************
   * Update iqValidVect: set free entries and clear freed entries
   ************************************************************************************/
  always_ff @(posedge clk or posedge reset)
  begin
      if (reset)
      begin
          iqValidVect     <= 0;
      end
  
      else if (flush_i)
      begin
          iqValidVect     <= 0;
      end
      else
      begin
          iqValidVect     <= (iqValidVect | freeVect) & ~grantedVect;
      end
  end
  
  
  /************************************************************************************
   * Select Logic. 
   *
   * (1) Create a request vector (reqVect) indicating which IQ entries are
   *     (a) Valid
   *     (b) Not already scheduled
   *     (c) Have both source operands ready
   *
   * (2) Create a subset vector for each execution pipe containing the entries 
   *     going to that pipe.
   *
   * (3) Select one instruction (if any are valid) to be issued to each pipe.
   ************************************************************************************/
  
  // TODO: Should be part of IssueQueuePartiton
  /* (1) Create a request vector (reqVect) */

`ifdef ROUND_ROBIN_ORDERING

  logic [`SIZE_ISSUEQ-1:0]  rrReqMask;
  
  always_ff @(posedge clk or posedge reset)
  begin
    if(reset)
    begin
      rrReqMask   <=  {{`SIZE_ISSUEQ/2{1'b0}},{`SIZE_ISSUEQ/2{1'b1}}};
    end
    else
    begin
      if(flush_i)
      begin
        rrReqMask   <=  {{`SIZE_ISSUEQ/2{1'b0}},{`SIZE_ISSUEQ/2{1'b1}}};
      end
      else
      begin
        rrReqMask   <=  {rrReqMask[`SIZE_ISSUEQ/2-1:0],rrReqMask[`SIZE_ISSUEQ-1:`SIZE_ISSUEQ/2]};
      end
    end
  end

`endif  //ROUND_ROBIN_ORDERING


  always_comb
  begin
  `ifdef ROUND_ROBIN_ORDERING
    `ifdef ISSUE_TWO_DEEP
        reqVect = rrReqMask & iqValidVect & src1ValidVect & src2ValidVect;
    `else /* ISSUE_ONE_DEEP */
        reqVect = rrReqMask & iqValidVect & (src1MatchVect | src1ValidVect) & (src2MatchVect | src2ValidVect);
    `endif
  `else
    `ifdef ISSUE_TWO_DEEP
        reqVect = iqValidVect & src1ValidVect & src2ValidVect;
    `else /* ISSUE_ONE_DEEP */
        reqVect = iqValidVect & (src1MatchVect | src1ValidVect) & (src2MatchVect | src2ValidVect);
    `endif
  `endif
  end

`ifdef AGE_BASED_ORDERING

  logic [`SIZE_ISSUEQ-1:0]        agedReqVect [0:`ISSUE_WIDTH-1];

  AgeOrdering ageOrdering(
	  .clk                (clk),
	  .reset              (reset|flush_i),
    .iqSize_i           (),
    .flush_i            (flush_i),
	  .backEndReady_i     (backEndReady_i),
    .alHead_i           (alHead_i),
    .alTail_i           (alTail_i),
    .alID_i             (alID_i),
	  .freeEntry_i        (freeEntry),
    .iqPacket_i         (iqPacket_i),
	  .freedEntry_i       (freedEntry),
	  .rrPacket_i         (rrPacket_o),
    .requestVector_i    (reqVect),

    .agedReqVector_o    (agedReqVect) 

	);

`endif //AGE_BASED_ORDERING

// NOTE: Everything below here is Issue Lane wise
// RBRC


  /* (2) Create the subset vector for pipe 0 */
  reg  [`SIZE_ISSUEQ-1:0]                reqVectFU0;
  
  always_comb
  begin : PIPE0_REQ_VECT
      int i;
  
      for (i = 0; i < `SIZE_ISSUEQ; i++)
      begin
        `ifdef AGE_BASED_ORDERING_LANE0
          reqVectFU0[i] = agedReqVect[0][i];
        `else
          reqVectFU0[i] = (reqVect[i]  &   (exePipeVect[i] == 0)) ? 1'h1 : 1'h0;
        `endif
      end
  end
  
  // TODO: Select logic can be optimized for dynamic config
  /* (3) Select one instruction for pipe 0 */
  Select #(
      .ISSUE_DEPTH       (`SIZE_ISSUEQ),
      .SIZE_SELECT_BLOCK (`SIZE_SELECT_BLOCK)
  )
  
  select0(
  
      .clk             (clk),
      .reset           (reset),
      .requestVector_i (reqVectFU0),
  
      .grantedEntryA_o (selectedEntry[0].id),
      .grantedValidA_o (selectedEntry[0].valid)
  );
  
  
  /* (2) Create the subset vector for pipe 1 */
  reg  [`SIZE_ISSUEQ-1:0]                reqVectFU1;
  
  always_comb
  begin : PIPE1_REQ_VECT
      int i;
  
      for (i = 0; i < `SIZE_ISSUEQ; i++)
      begin
        `ifdef AGE_BASED_ORDERING_LANE1
          reqVectFU1[i] = agedReqVect[1][i];
        `else
          reqVectFU1[i] = (reqVect[i]   &    (exePipeVect[i] == 1)) ? 1'h1 : 1'h0;
        `endif
      end
  end
  
  
  /* (3) Select one instruction for pipe 1 */
  Select #(
      .ISSUE_DEPTH       (`SIZE_ISSUEQ),
      .SIZE_SELECT_BLOCK (`SIZE_SELECT_BLOCK)
  )
  select1(
  
      .clk             (clk),
      .reset           (reset),
      .requestVector_i (reqVectFU1),
  
      .grantedEntryA_o (selectedEntry[1].id),
      .grantedValidA_o (selectedEntry[1].valid)
  );
  
  
  /* (2) Create the subset vector for pipe 2 */
  reg  [`SIZE_ISSUEQ-1:0]                reqVectFU2;
  
  always_comb
  begin : PIPE2_REQ_VECT
      int i;
  
      for (i = 0; i < `SIZE_ISSUEQ; i++)
      begin
        `ifdef AGE_BASED_ORDERING_LANE2
          reqVectFU2[i] = agedReqVect[2][i] & (!ignoreSimple[2] | !ISsimple[i]);
        `else
          reqVectFU2[i] = reqVect[i] && (exePipeVect[i] == 2) && (!ignoreSimple[2] || !ISsimple[i]);
        `endif
      end
  end
  
  
  /* (3) Select one instruction for pipe 2 */
  Select #(
      .ISSUE_DEPTH       (`SIZE_ISSUEQ),
      .SIZE_SELECT_BLOCK (`SIZE_SELECT_BLOCK)
  )
  select2 (
  
      .clk             (clk),
      .reset           (reset),
      .requestVector_i (reqVectFU2),
  
      .grantedEntryA_o (selectedEntry[2].id),
      .grantedValidA_o (selectedEntry[2].valid)
  );
  
  
  `ifdef ISSUE_FOUR_WIDE
  /* (2) Create the subset vector for pipe 3 */
  reg  [`SIZE_ISSUEQ-1:0]                reqVectFU3;
  
  always_comb
  begin : PIPE3_REQ_VECT
      int i;
  
      for (i = 0; i < `SIZE_ISSUEQ; i++)
      begin
        `ifdef AGE_BASED_ORDERING_LANE3
          reqVectFU3[i] = agedReqVect[3][i] & (!ignoreSimple[3] | !ISsimple[i]);
        `else
          reqVectFU3[i] = reqVect[i] && (exePipeVect[i] == 3) && (!ignoreSimple[3] || !ISsimple[i]);
        `endif
      end
  end
  
  /* (3) Select one instruction for pipe 3 */
  Select #(
      .ISSUE_DEPTH       (`SIZE_ISSUEQ),
      .SIZE_SELECT_BLOCK (`SIZE_SELECT_BLOCK)
  )
  select3 (
  
      .clk             (clk),
      .reset           (reset),
      .requestVector_i (reqVectFU3),
  
      .grantedEntryA_o (selectedEntry[3].id),
      .grantedValidA_o (selectedEntryValid[3])
  );
  
    assign selectedEntry[3].valid = selectedEntryValid[3];
  
  `endif
  
  
  `ifdef ISSUE_FIVE_WIDE
  /* (2) Create the subset vector for pipe 4 */
  reg  [`SIZE_ISSUEQ-1:0]                reqVectFU4;
  
  always_comb
  begin : PIPE4_REQ_VECT
      int i;
  
      for (i = 0; i < `SIZE_ISSUEQ; i++)
      begin
        `ifdef AGE_BASED_ORDERING_LANE4
          reqVectFU4[i] = agedReqVect[4][i] & (!ignoreSimple[4] | !ISsimple[i]);
        `else
          reqVectFU4[i] = reqVect[i] && (exePipeVect[i] == 4) && (!ignoreSimple[4] || !ISsimple[i]);
        `endif
      end
  end
  
  /* (3) Select one instruction for pipe 4 */
  Select #(
      .ISSUE_DEPTH       (`SIZE_ISSUEQ),
      .SIZE_SELECT_BLOCK (`SIZE_SELECT_BLOCK)
  )
  select4 (
  
      .clk             (clk),
      .reset           (reset),
      .requestVector_i (reqVectFU4),
  
      .grantedEntryA_o (selectedEntry[4].id),
      .grantedValidA_o (selectedEntryValid[4])
  );
  
    assign selectedEntry[4].valid = selectedEntryValid[4];
  
  `endif
  
  
  `ifdef ISSUE_SIX_WIDE
  /* (2) Create the subset vector for pipe 5 */
  reg  [`SIZE_ISSUEQ-1:0]                reqVectFU5;
  
  always_comb
  begin : PIPE5_REQ_VECT
      int i;
  
      for (i = 0; i < `SIZE_ISSUEQ; i++)
      begin
        `ifdef AGE_BASED_ORDERING_LANE5
          reqVectFU5[i] = agedReqVect[5][i] & (!ignoreSimple[5] | !ISsimple[i]);
        `else
          reqVectFU5[i] = reqVect[i] && (exePipeVect[i] == 5) && (!ignoreSimple[5] || !ISsimple[i]);
        `endif
      end
  end
  
  /* (3) Select one instruction for pipe 5 */
  Select #(
      .ISSUE_DEPTH       (`SIZE_ISSUEQ),
      .SIZE_SELECT_BLOCK (`SIZE_SELECT_BLOCK)
  )
  select5 (
  
      .clk             (clk),
      .reset           (reset),
      .requestVector_i (reqVectFU5),
  
      .grantedEntryA_o (selectedEntry[5].id),
      .grantedValidA_o (selectedEntryValid[5])
  );
  
    assign selectedEntry[5].valid = selectedEntryValid[5];
  
  `endif
  
  
  
  `ifdef ISSUE_SEVEN_WIDE
  /* (2) Create the subset vector for pipe 6 */
  reg  [`SIZE_ISSUEQ-1:0]                reqVectFU6;
  
  always_comb
  begin : PIPE6_REQ_VECT
      int i;
  
      for (i = 0; i < `SIZE_ISSUEQ; i++)
      begin
        `ifdef AGE_BASED_ORDERING_LANE6
          reqVectFU6[i] = agedReqVect[6][i] & (!ignoreSimple[6] | !ISsimple[i]);
        `else
          reqVectFU6[i] = reqVect[i] && (exePipeVect[i] == 6) && (!ignoreSimple[6] || !ISsimple[i]);
        `endif
      end
  end
  
  /* (3) Select one instruction for pipe 6 */
  Select #(
      .ISSUE_DEPTH       (`SIZE_ISSUEQ),
      .SIZE_SELECT_BLOCK (`SIZE_SELECT_BLOCK)
  )
  select6 (
  
      .clk             (clk),
      .reset           (reset),
      .requestVector_i (reqVectFU6),
  
      .grantedEntryA_o (selectedEntry[6].id),
      .grantedValidA_o (selectedEntryValid[6])
  );
  
    assign selectedEntry[6].valid = selectedEntryValid[6];
  
  `endif
  
  
  
  `ifdef ISSUE_EIGHT_WIDE
  /* (2) Create the subset vector for pipe 7 */
  reg  [`SIZE_ISSUEQ-1:0]                reqVectFU7;
  
  always_comb
  begin : PIPE7_REQ_VECT
      int i;
  
      for (i = 0; i < `SIZE_ISSUEQ; i++)
      begin
        `ifdef AGE_BASED_ORDERING_LANE7
          reqVectFU7[i] = agedReqVect[7][i] & (!ignoreSimple[7] | !ISsimple[i]);
        `else
          reqVectFU7[i] = reqVect[i] && (exePipeVect[i] == 7) && (!ignoreSimple[7] || !ISsimple[i]);
        `endif
      end
  end
  
  /* (3) Select one instruction for pipe 7 */
  Select #(
      .ISSUE_DEPTH       (`SIZE_ISSUEQ),
      .SIZE_SELECT_BLOCK (`SIZE_SELECT_BLOCK)
  )
  select7 (
  
      .clk             (clk),
      .reset           (reset),
      .requestVector_i (reqVectFU7),
  
      .grantedEntryA_o (selectedEntry[7].id),
      .grantedValidA_o (selectedEntryValid[7])
  );
  
    assign selectedEntry[7].valid = selectedEntryValid[7];
  
  `endif
  
  
  /* Put the created packet into the select/payload pipeline register */
  `ifdef ISSUE_THREE_DEEP
  always_ff @(posedge clk or posedge reset)
  begin: SELECT_PAYLOAD_PIPELINE_REGISTER
      int i;
  
      if (reset)
      begin
          for (i = 0; i < `ISSUE_WIDTH; i++)
          begin
              grantedEntry[i]                  <= 0;
          end
      end
      else if(flush_i)
      begin
          for (i = 0; i < `ISSUE_WIDTH; i++)
          begin
              grantedEntry[i]                  <= 0;
          end
      end
      else
      begin
          for (i = 0; i < `ISSUE_WIDTH; i++)
          begin
              grantedEntry[i]                  <= selectedEntry[i];
          end
      end
  end
  
  `else
  
  always_comb
  begin: SELECT_PAYLOAD_PIPELINE
      int i;
  
      for (i = 0; i < `ISSUE_WIDTH; i++)
      begin
          grantedEntry[i]                    = selectedEntry[i];
      end
  end
  
  `endif
  
  
  /************************************************************************************
   * Write the incoming instruction's physical destination register and 
   * execution pipe assignment.
   ************************************************************************************/
  always_ff @(posedge clk or posedge reset)
  begin: newInstructions
      int i;
  
      if (reset)
      begin
          for (i = 0; i < `SIZE_ISSUEQ; i++)
          begin
              phyDestVect[i] <= 0;
              exePipeVect[i] <= 0;
              ISsimple[i]    <= 0;
          end
      end
      else if (flush_i)
      begin
          for (i = 0; i < `SIZE_ISSUEQ; i++)
          begin
              phyDestVect[i] <= 0;
              exePipeVect[i] <= 0;
              ISsimple[i]    <= 0;
          end
      end
      else if (backEndReady_i)
      begin
          for (i = 0; i < `DISPATCH_WIDTH; i++)
          begin
            phyDestVect[freeEntry[i].id] <= {iqPacket_i[i].phyDest,iqPacket_i[i].phyDestValid};
            exePipeVect[freeEntry[i].id] <= iqPacket_i[i].fu;
            ISsimple[freeEntry[i].id]    <= iqPacket_i[i].isSimple;
          end
      end
  end


  
  /****************************
   * RSR INSIDE ISSUEQ MODULE *
   ***************************/
  
  always_comb
  begin
      int i;
  
      for (i = 0; i < `ISSUE_WIDTH; i++)
      begin
          grantedDest[i].reg_id       = phyDestVect[selectedEntry[i].id].reg_id;
          // RSR
          // Broadcasted RSR tags should not be valid if instruction does not have a valid destination
          grantedDest[i].valid        = selectedEntry[i].valid & phyDestVect[selectedEntry[i].id].valid ;
          ISsimple_t[i]               = ISsimple[selectedEntry[i].id];
      end
  end
  
  // LANE: Should be modified to per lane RSRs so
  // that gating is simpler
  // TODO
  RSR
  rsr(
  
      .clk              (clk),
      .reset            (reset | flush_i),
  
      .ISsimple_i       (ISsimple_t),
      .grantedDest_i    (grantedDest),
      .rsrTag_o         (rsrTag_t),
      .ignoreSimple_o   (ignoreSimple)
  );

  /* rsrTag contain the producer tags for wake-up */

  `ifdef LD_SPECULATIVELY_WAKES_DEPENDENT
    assign rsrTag[0].valid  = rsrTag_t[0].valid;
    assign rsrTag[0].reg_id = rsrTag_t[0].valid ? rsrTag_t[0].reg_id : 0;
  `else
    assign rsrTag[0] = rsr0Tag_i;
  `endif
  
  always_comb
  begin
      int i;
      for (i = 1; i < `ISSUE_WIDTH; i++)
      begin
          rsrTag[i].valid  = rsrTag_t[i].valid;
          rsrTag[i].reg_id = rsrTag_t[i].valid ? rsrTag_t[i].reg_id : 0;
      end
  end





`else // DYNAMIC_CONFIG





  always_comb
  begin:CHECK_NEW_INSTS_SOURCE_OPERAND
      int i;
  
      for (i = 0; i < `DISPATCH_WIDTH; i++)
      begin
          src1RsrMatch[i]   = 0;
          src2RsrMatch[i]   = 0;
      end
  
  
      // Bitwise OR the vectors together
      for (i = 0; i < `ISSUE_WIDTH; i++)
      begin
          src1RsrMatch   = src1RsrMatch | src1RsrMatch_lane[i];
          src2RsrMatch   = src2RsrMatch | src2RsrMatch_lane[i];
      end
  
      `ifdef DYNAMIC_WIDTH
        for (i = 0; i < `DISPATCH_WIDTH; i++)
        begin
  
            newSrc1Ready[i] = ( src1RsrMatch[i]                        || /* (i)   */
                                phyRegValidVect[iqPacket_i[i].phySrc1] || /* (ii)  */
                                ~iqPacket_i[i].phySrc1Valid)           &  /* (iii) */
                                dispatchLaneActive_i[i]?                  /* Is active? */
                                1'h1 : 1'h0;
  
            newSrc2Ready[i] = ( src2RsrMatch[i]                        || /* (i)   */
                                phyRegValidVect[iqPacket_i[i].phySrc2] || /* (ii)  */
                                ~iqPacket_i[i].phySrc2Valid)           &  /* (iii) */
                                dispatchLaneActive_i[i]?                  /* Is active? */
                                1'h1 : 1'h0;
  
        end
      `else
        for (i = 0; i < `DISPATCH_WIDTH; i++)
        begin
  
            newSrc1Ready[i] = ( src1RsrMatch[i]                        || /* (i)   */
                                phyRegValidVect[iqPacket_i[i].phySrc1] || /* (ii)  */
                                ~iqPacket_i[i].phySrc1Valid)           ?  /* (iii) */
                                1'h1 : 1'h0;
  
            newSrc2Ready[i] = ( src2RsrMatch[i]                        || /* (i)   */
                                phyRegValidVect[iqPacket_i[i].phySrc2] || /* (ii)  */
                                ~iqPacket_i[i].phySrc2Valid)           ?  /* (iii) */
                                1'h1 : 1'h0;
  
        end
      `endif
  end

`ifdef DYNAMIC_SIZE
  localparam PARTITION_SIZE = `SIZE_ISSUEQ/`STRUCT_PARTS;
  localparam PARTITION_SIZE_LOG = `SIZE_ISSUEQ_LOG - `STRUCT_PARTS_LOG;


  genvar part;
  generate
    for (part = 0; part < `STRUCT_PARTS; part++)
    begin:ISSUE_PART
      IssuePartition #(
          .PARTITION_SIZE(PARTITION_SIZE),
          .PARTITION_SIZE_LOG(PARTITION_SIZE_LOG),
          .PARTITION_ID(part)) 
        part_inst (

          .clk          (clk),
          .reset        (reset),
          .flush_i      (flush_i),

          .dispatchLaneActive_i(dispatchLaneActive_i),
          .partitionActive_i(iqPartitionActive_i[part]),

          .backEndReady_i(backEndReady_i),

          .newSrc1Ready (newSrc1Ready),
          .newSrc2Ready (newSrc2Ready),
          .freeEntry    (freeEntry),
          .selectedEntry(selectedEntry),
          .iqPacket_i   (iqPacket_i), 

          .src1MatchVect(src1MatchVect[((part+1)*PARTITION_SIZE-1):part*PARTITION_SIZE]),
          .src2MatchVect(src2MatchVect[((part+1)*PARTITION_SIZE-1):part*PARTITION_SIZE]),

          .phyDestVect_o(phyDestVect[((part+1)*PARTITION_SIZE-1):part*PARTITION_SIZE]),
          .exePipeVect_o(exePipeVect[((part+1)*PARTITION_SIZE-1):part*PARTITION_SIZE]),
          .ISsimple_o   (ISsimple[((part+1)*PARTITION_SIZE-1):part*PARTITION_SIZE]),
          .reqVect_o    (reqVect[((part+1)*PARTITION_SIZE-1):part*PARTITION_SIZE])

        );

    end
  endgenerate
`else

  localparam PARTITION_SIZE = `SIZE_ISSUEQ;
  localparam PARTITION_SIZE_LOG = `SIZE_ISSUEQ_LOG;


  genvar part;
  generate
    for (part = 0; part < 1; part++)
    begin:ISSUE_PART
      IssuePartition #(
          .PARTITION_SIZE(PARTITION_SIZE),
          .PARTITION_SIZE_LOG(PARTITION_SIZE_LOG),
          .PARTITION_ID(part)) 
        part_inst (

          .clk          (clk),
          .reset        (reset),
          .flush_i      (flush_i),

          .dispatchLaneActive_i(dispatchLaneActive_i),
          .partitionActive_i(1'b1),

          .backEndReady_i(backEndReady_i),

          .newSrc1Ready (newSrc1Ready),
          .newSrc2Ready (newSrc2Ready),
          .freeEntry    (freeEntry),
          .selectedEntry(selectedEntry),
          .iqPacket_i   (iqPacket_i), 

          .src1MatchVect(src1MatchVect[((part+1)*PARTITION_SIZE-1):part*PARTITION_SIZE]),
          .src2MatchVect(src2MatchVect[((part+1)*PARTITION_SIZE-1):part*PARTITION_SIZE]),

          .phyDestVect_o(phyDestVect[((part+1)*PARTITION_SIZE-1):part*PARTITION_SIZE]),
          .exePipeVect_o(exePipeVect[((part+1)*PARTITION_SIZE-1):part*PARTITION_SIZE]),
          .ISsimple_o   (ISsimple[((part+1)*PARTITION_SIZE-1):part*PARTITION_SIZE]),
          .reqVect_o    (reqVect[((part+1)*PARTITION_SIZE-1):part*PARTITION_SIZE])

        );

    end
  endgenerate
`endif // DYNAMIC_SIZE

`ifdef AGE_BASED_ORDERING

  logic [`SIZE_ISSUEQ-1:0]        agedReqVect [0:`ISSUE_WIDTH-1];

  AgeOrdering ageOrdering(
	  .clk                (clk),
	  .reset              (reset|flush_i),
    .iqSize_i           (),
    .flush_i            (flush_i),
	  .backEndReady_i     (backEndReady_i),
    .alHead_i           (alHead_i),
    .alTail_i           (alTail_i),
    .alID_i             (alID_i),
	  .freeEntry_i        (freeEntry),
    .iqPacket_i         (iqPacket_i),
	  .freedEntry_i       (freedEntry),
	  .rrPacket_i         (rrPacket_o),
    .requestVector_i    (reqVect),

    .agedReqVector_o    (agedReqVect) 

	);

  logic [`ISSUE_WIDTH-1:0]  ageBasedOrdering;

  always_comb
  begin
    ageBasedOrdering = 0;

    `ifdef AGE_BASED_ORDERING_LANE0
      ageBasedOrdering[0] = 1'b1;
    `endif

    `ifdef AGE_BASED_ORDERING_LANE1
      ageBasedOrdering[1] = 1'b1;
    `endif

    `ifdef AGE_BASED_ORDERING_LANE2
      ageBasedOrdering[2] = 1'b1;
    `endif

    `ifdef AGE_BASED_ORDERING_LANE3
      ageBasedOrdering[3] = 1'b1;
    `endif

    `ifdef AGE_BASED_ORDERING_LANE4
      ageBasedOrdering[4] = 1'b1;
    `endif

    `ifdef AGE_BASED_ORDERING_LANE5
      ageBasedOrdering[4] = 1'b1;
    `endif

    `ifdef AGE_BASED_ORDERING_LANE6
      ageBasedOrdering[6] = 1'b1;
    `endif

    `ifdef AGE_BASED_ORDERING_LANE7
      ageBasedOrdering[7] = 1'b1;
    `endif
  end

`endif // AGE_BASED_ORDERING


`ifdef DYNAMIC_WIDTH
  genvar lane;
  generate
    for (lane = 0; lane < `ISSUE_WIDTH; lane++)
    begin:ISSUE_LANE


      IssueLane #(.ISSUE_LANE_ID(lane))
        lane_inst (
          .clk          (clk),
          .reset        (reset),
          .flush_i      (flush_i),
          .backEndReady_i(backEndReady_i),
          .dispatchLaneActive_i(dispatchLaneActive_i),
          .laneActive_i  (issueLaneActive_i[lane]),

          .iqPacket_i   (iqPacket_i),
          .freeEntry    (freeEntry),
          .rsr0Tag_i    (rsr0Tag_i),
          .reqVect      (reqVect),

        `ifdef AGE_BASED_ORDERING
          .ageBasedOrdering  (ageBasedOrdering[lane]),
          .agedReqVect  (agedReqVect[lane]),
        `endif

          .phyDestVect(phyDestVect),
          .exePipeVect(exePipeVect),
          .ISsimple(ISsimple),

          .rsrTag       (rsrTag_t[lane]),
          .grantedEntry (grantedEntry_t[lane]),
          .selectedEntry(selectedEntry[lane]),
          .src1RsrMatch_o(src1RsrMatch_t[lane]),
          .src2RsrMatch_o(src2RsrMatch_t[lane])
        );

      // Mimic Isolation
      always_comb
      begin
        grantedEntry[lane]  = grantedEntry_t[lane];
        rsrTag[lane]        = rsrTag_t[lane];

        if(~issueLaneActive_i[lane])
        begin
          grantedEntry[lane].valid = 1'b0;
          rsrTag[lane].valid = 1'b0;
        end
        
        src1RsrMatch_lane[lane] = src1RsrMatch_t[lane] & {`DISPATCH_WIDTH{issueLaneActive_i[lane]}};
        src2RsrMatch_lane[lane] = src2RsrMatch_t[lane] & {`DISPATCH_WIDTH{issueLaneActive_i[lane]}};
      end

    end
  endgenerate
`else
  genvar lane;
  generate
    for (lane = 0; lane < `ISSUE_WIDTH; lane++)
    begin:ISSUE_LANE

      IssueLane #(.ISSUE_LANE_ID(lane))
        lane_inst (
          .clk          (clk),
          .reset        (reset),
          .flush_i      (flush_i),
          .backEndReady_i(backEndReady_i),
          .dispatchLaneActive_i({`DISPATCH_WIDTH{1'b1}}),
          .laneActive_i  (1'b1),

          .iqPacket_i   (iqPacket_i),
          .freeEntry    (freeEntry),
          .rsr0Tag_i    (rsr0Tag_i),
          .reqVect      (reqVect),

        `ifdef AGE_BASED_ORDERING
          .ageBasedOrdering  (ageBasedOrdering[lane]),
          .agedReqVect  (agedReqVect[lane]),
        `endif

          .phyDestVect(phyDestVect),
          .exePipeVect(exePipeVect),
          .ISsimple(ISsimple),

          .rsrTag       (rsrTag_t[lane]),
          .grantedEntry (grantedEntry_t[lane]),
          .selectedEntry(selectedEntry[lane]),
          .src1RsrMatch_o(src1RsrMatch_t[lane]),
          .src2RsrMatch_o(src2RsrMatch_t[lane])
        );

      // Mimic Isolation
      always_comb
      begin
        grantedEntry[lane]  = grantedEntry_t[lane];
        rsrTag[lane]        = rsrTag_t[lane];
        src1RsrMatch_lane[lane] = src1RsrMatch_t[lane]; 
        src2RsrMatch_lane[lane] = src2RsrMatch_t[lane];
      end

    end
  endgenerate
`endif //DYNAMIC_WIDTH

`endif // DYNAMIC_CONFIG

`ifdef DYNAMIC_CONFIG
 always_comb 
 begin
  int i;
  for (i = 0; i < `DISPATCH_WIDTH; i++)
  begin
    `ifdef DYNAMIC_CONFIG_AND_WIDTH
      valid_bundle_o[i] = backEndReady_i & dispatchLaneActive_i[i];
    `else
      valid_bundle_o[i] = backEndReady_i;
    `endif
  end
 end
`endif

`ifdef PERF_MON
  logic   [`SIZE_LSQ_LOG:0] reqCount_next;
  logic   [`SIZE_LSQ_LOG:0] issuedCount_next;

  always_ff @(posedge clk or posedge reset)
  begin
    if(reset)
    begin
      reqCount_o      <= 0;
      issuedCount_o   <= 0;
    end
    else
    begin
      reqCount_o      <= reqCount_next;
      issuedCount_o   <= issuedCount_next;
    end
  end
 
  `ifdef DYNAMIC_CONFIG
    reg                    grantedEntryMatch;
    reg  [`SIZE_ISSUEQ-1:0]                grantedVect;
    
    always_comb
    begin
      int i,j;
      grantedVect = 0;
      for(i=0;i<`SIZE_ISSUEQ;i++)
      begin

        grantedEntryMatch = 0;
    
        for (j = 0; j < `ISSUE_WIDTH; j++)
        begin
            grantedEntryMatch = grantedEntryMatch || (selectedEntry[j].valid & (i == selectedEntry[j].id));
        end
    
        if (grantedEntryMatch)
        begin
            grantedVect[i] = 1'h1;
        end
    
        else
        begin
            grantedVect[i] = 1'h0;
        end
      end
    end
  `endif

  always_comb
  begin
    int i;
    reqCount_next     = 0;;
    issuedCount_next  = 0;
    for(i=0;i<`SIZE_ISSUEQ;i++)
    begin
      reqCount_next     = reqCount_next + reqVect[i];
      issuedCount_next  = issuedCount_next + grantedVect[i];
    end
  end
`endif

endmodule
