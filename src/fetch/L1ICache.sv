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

module L1ICache (
	/* Address of the insts to be fetched */
	input      [`SIZE_PC-1:0]             PC_i,
  input                                 fetchReq_i,
	input      [`SIZE_INSTRUCTION-1:0]    inst_i   [0:`FETCH_WIDTH-1],
	input      [0:`FETCH_WIDTH-1]         instValid_i,
	input                                 reset,
  input                                 clk,

  input                                 stallFetch_i,
`ifdef DYNAMIC_CONFIG
  input     [`FETCH_WIDTH-1:0]          fetchLaneActive_i,
`endif

//`ifdef SCRATCH_PAD
//  input [`DEBUG_INST_RAM_LOG+`DEBUG_INST_RAM_WIDTH_LOG-1:0]   instScratchAddr_i   ,
//  input [7:0]                           instScratchWrData_i ,
//  input                                 instScratchWrEn_i   ,
//  output [7:0]                          instScratchRdData_o ,
//  input                                 instScratchPadEn_i,
//`endif

`ifdef INST_CACHE
  output [`ICACHE_SIZE_MEM_ADDR-1:0]    ic2memReqAddr_o,      // memory read address
  output                                ic2memReqValid_o,     // memory read enable
  input  [`ICACHE_TAG_BITS-1:0]         mem2icTag_i,          // tag of the incoming data
  input  [`ICACHE_INDEX_BITS-1:0]       mem2icIndex_i,        // index of the incoming data
  input  [`ICACHE_LINE_SIZE-1:0]        mem2icData_i,         // requested data
  input                                 mem2icRespValid_i,    // requested data is ready
  input                                 instCacheBypass_i,
  input                                 icScratchModeEn_i,    // Should ideally be disabled by default
  input [`ICACHE_INDEX_BITS+`ICACHE_BYTES_IN_LINE_LOG-1:0]  icScratchWrAddr_i,
  input                                                     icScratchWrEn_i,
  input [7:0]                                               icScratchWrData_i,
  output [7:0]                                              icScratchRdData_o,
`endif  

  output                                icMiss_o,

	output reg [`SIZE_PC-1:0]             instPC_o [0:`FETCH_WIDTH-1],
  output reg                            fetchReq_o,
	output reg [`SIZE_INSTRUCTION-1:0]    inst_o   [0:`FETCH_WIDTH-1],
	output reg [0:`FETCH_WIDTH-1]         instValid_o

	);

	logic   [`SIZE_INSTRUCTION-1:0]       inst_dbg   [0:`FETCH_WIDTH-1];

//`ifdef SCRATCH_PAD
//
//    wire [`DEBUG_INST_RAM_LOG-1:0]                addr0;
//    wire [`DEBUG_INST_RAM_WIDTH-1:0]              inst0;
//    assign addr0                                  = PC_i[(`DEBUG_INST_RAM_LOG+3)-1:3];
//    assign inst_dbg[0]                            = {24'h0, inst0};
//  
//  `ifdef FETCH_TWO_WIDE
//    wire [`DEBUG_INST_RAM_LOG-1:0]                addr1;
//    wire [`DEBUG_INST_RAM_WIDTH-1:0]              inst1;
//    assign addr1                                  = PC_i[(`DEBUG_INST_RAM_LOG+3)-1:3] + 1;
//    assign inst_dbg[1]                            = {24'h0, inst1};
//  `endif
//  
//  `ifdef FETCH_THREE_WIDE
//    wire [`DEBUG_INST_RAM_LOG-1:0]                addr2;
//    wire [`DEBUG_INST_RAM_WIDTH-1:0]              inst2;
//    assign addr2                                  = PC_i[(`DEBUG_INST_RAM_LOG+3)-1:3] + 2;
//    assign inst_dbg[2]                            = {24'h0, inst2};
//  `endif
//  
//  `ifdef FETCH_FOUR_WIDE
//    wire [`DEBUG_INST_RAM_LOG-1:0]                addr3;
//    wire [`DEBUG_INST_RAM_WIDTH-1:0]              inst3;
//    assign addr3                                  = PC_i[(`DEBUG_INST_RAM_LOG+3)-1:3] + 3;
//    assign inst_dbg[3]                            = {24'h0, inst3};
//  `endif
//  
//  `ifdef FETCH_FIVE_WIDE
//    wire [`DEBUG_INST_RAM_LOG-1:0]                addr4;
//    wire [`DEBUG_INST_RAM_WIDTH-1:0]              inst4;
//    assign addr4                                  = PC_i[(`DEBUG_INST_RAM_LOG+3)-1:3] + 4;
//    assign inst_dbg[4]                            = {24'h0, inst4};
//  `endif
//  
//  `ifdef FETCH_SIX_WIDE
//    wire [`DEBUG_INST_RAM_LOG-1:0]                addr5;
//    wire [`DEBUG_INST_RAM_WIDTH-1:0]              inst5;
//    assign addr5                                  = PC_i[(`DEBUG_INST_RAM_LOG+3)-1:3] + 5;
//    assign inst_dbg[5]                            = {24'h0, inst5};
//  `endif
//  
//  `ifdef FETCH_SEVEN_WIDE
//    wire [`DEBUG_INST_RAM_LOG-1:0]                addr6;
//    wire [`DEBUG_INST_RAM_WIDTH-1:0]              inst6;
//    assign addr6                                  = PC_i[(`DEBUG_INST_RAM_LOG+3)-1:3] + 6;
//    assign inst_dbg[6]                            = {24'h0, inst6};
//  `endif
//  
//  `ifdef FETCH_EIGHT_WIDE
//    wire [`DEBUG_INST_RAM_LOG-1:0]                addr7;
//    wire [`DEBUG_INST_RAM_WIDTH-1:0]              inst7;
//    assign addr7                                  = PC_i[(`DEBUG_INST_RAM_LOG+3)-1:3] + 7;
//    assign inst_dbg[7]                            = {24'h0, inst7};
//  `endif
//    
//    
//    
//    
//    DEBUG_INST_RAM #(
//        .DEPTH                                (`DEBUG_INST_RAM_DEPTH),
//        .INDEX                                (`DEBUG_INST_RAM_LOG),
//        .WIDTH                                (`DEBUG_INST_RAM_WIDTH)
//        ) ic (
//        .clk                                  (clk),
//        .reset                                (reset),
//    
//        .addr0_i                              (addr0),
//        .data0_o                              (inst0),
//    
//  `ifdef FETCH_TWO_WIDE
//        .addr1_i                              (addr1),
//        .data1_o                              (inst1),
//  `endif
//    
//  `ifdef FETCH_THREE_WIDE
//        .addr2_i                              (addr2),
//        .data2_o                              (inst2),
//  `endif
//    
//  `ifdef FETCH_FOUR_WIDE
//        .addr3_i                              (addr3),
//        .data3_o                              (inst3),
//  `endif
//    
//  `ifdef FETCH_FIVE_WIDE
//        .addr4_i                              (addr4),
//        .data4_o                              (inst4),
//  `endif
//    
//  `ifdef FETCH_SIX_WIDE
//        .addr5_i                              (addr5),
//        .data5_o                              (inst5),
//  `endif
//    
//  `ifdef FETCH_SEVEN_WIDE
//        .addr6_i                              (addr6),
//        .data6_o                              (inst6),
//  `endif
//    
//  `ifdef FETCH_EIGHT_WIDE
//        .addr7_i                              (addr7),
//        .data7_o                              (inst7),
//  `endif
//    
//        .instScratchAddr_i                    (instScratchAddr_i),
//        .instScratchWrData_i                  (instScratchWrData_i),
//        .instScratchWrEn_i                    (instScratchWrEn_i),
//        .instScratchRdData_o                  (instScratchRdData_o)
//      );
//
//
//  // When scratch pad is enabled, it is the default source
//  // until the instScratchPadEn_i is changed to 0.
//  always_comb
//  begin
//    if(instScratchPadEn_i)
//    begin
//      inst_o  = inst_dbg;
//      instValid_o = {`FETCH_WIDTH{1'b1}};
//    end
//    else
//    begin
//      inst_o  = inst_i;
//      instValid_o = instValid_i;
//    end
//  end
//
//`else //`ifdef SCRATCH_PAD

  `ifdef INST_CACHE
    logic [`SIZE_INSTRUCTION-1:0]   inst           [0:`FETCH_WIDTH-1];
    logic [0:`FETCH_WIDTH-1]        instValid;
    // TODO: Place holder for an I-Cache
    // Currently assigns the instructions
    // being read in the testbench using VPI
    // routines
    ICache_controller #(
        .FETCH_WIDTH            (`FETCH_WIDTH)
    )
        icache (
    
        .clk                    (clk),
        .reset                  (reset),
        .icScratchModeEn_i      (icScratchModeEn_i),

        .icMiss_o               (icMiss_o),
    
        .fetchReq_i             (fetchReq_i),
        .pc_i                   (PC_i),
        .inst_o                 (inst),
        .instValid_o            (instValid),
        
        .ic2memReqAddr_o        (ic2memReqAddr_o),
        .ic2memReqValid_o       (ic2memReqValid_o),
        
        .icScratchWrAddr_i      (icScratchWrAddr_i),
        .icScratchWrEn_i        (icScratchWrEn_i  ),
        .icScratchWrData_i      (icScratchWrData_i),
        .icScratchRdData_o      (icScratchRdData_o),
    
        .mem2icTag_i            (mem2icTag_i),
        .mem2icIndex_i          (mem2icIndex_i),
        .mem2icData_i           (mem2icData_i),
        .mem2icRespValid_i      (mem2icRespValid_i)
    );

    // When scratch pad is enabled, it is the default source
    // until the instScratchPadEn_i is changed to 0.
    always_comb
    begin
      int i;
      if(~instCacheBypass_i)
      begin
        inst_o  = inst;
        for(i = 0; i < `FETCH_WIDTH; i++)
        begin
        `ifdef DYNAMIC_CONFIG_AND_WIDTH
          //Use the instValid from the ICACHE
          instValid_o[i] = instValid[i] & fetchLaneActive_i[i];
        `else
          instValid_o[i] = instValid[i];
        `endif
        end
      end
      else
      begin
        inst_o  = inst_i;
        for(i = 0; i < `FETCH_WIDTH; i++)
        begin
        `ifdef DYNAMIC_CONFIG_AND_WIDTH
          //Use the instValid from the parallel interface
          instValid_o[i] = instValid_i[i] & fetchLaneActive_i[i];
        `else
          instValid_o[i] = instValid_i[i];
        `endif
        end
      end
    end

  `else  // No CACHE and No SCRATCH_PAD

    always_comb
    begin
      int i;
      inst_o  = inst_i;
      for(i = 0; i < `FETCH_WIDTH; i++)
      begin
      `ifdef DYNAMIC_CONFIG_AND_WIDTH
        instValid_o[i] = instValid_i[i] & fetchLaneActive_i[i] & ~stallFetch_i & fetchReq_i;
//      `elsif DYNAMIC_CONFIG
      `else
        instValid_o[i] = instValid_i[i] & ~stallFetch_i & fetchReq_i;
//      `else
//        instValid_o[i] = instValid_i[i] & fetchReq_i;
      `endif
      end
    end

  `endif //`ifdef INST_CACHE


//`endif //`ifdef SCRATCH_PAD


always_comb
begin
	int i;

	for (i = 0; i < `FETCH_WIDTH; i = i + 1) 
	begin
		instPC_o[i]    = PC_i + (i * 8);
	end
  fetchReq_o  = fetchReq_i;
end

endmodule

