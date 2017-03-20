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

module PRF_RAM #(
    /* Parameters */
    parameter DEPTH  = 16,
    parameter INDEX  = 4,
    parameter WIDTH  = 8
    ) (

    input      [DEPTH-1:0]                src1Addr0_i,
    output reg [WIDTH-1:0]                src1Data0_o,
    
    input      [DEPTH-1:0]                src2Addr0_i,
    output reg [WIDTH-1:0]                src2Data0_o,
    
    input      [DEPTH-1:0]                destAddr0_i, // Fully decoded address
    input      [WIDTH-1:0]                destData0_i,
    input                                 destWe0_i,


`ifdef ISSUE_TWO_WIDE
    input      [DEPTH-1:0]                src1Addr1_i,
    output reg [WIDTH-1:0]                src1Data1_o,
    
    input      [DEPTH-1:0]                src2Addr1_i,
    output reg [WIDTH-1:0]                src2Data1_o,
    
    input      [DEPTH-1:0]                destAddr1_i,
    input      [WIDTH-1:0]                destData1_i,
    input                                 destWe1_i,
`endif


`ifdef ISSUE_THREE_WIDE
    input      [DEPTH-1:0]                src1Addr2_i,
    output reg [WIDTH-1:0]                src1Data2_o,
    
    input      [DEPTH-1:0]                src2Addr2_i,
    output reg [WIDTH-1:0]                src2Data2_o,
    
    input      [DEPTH-1:0]                destAddr2_i,
    input      [WIDTH-1:0]                destData2_i,
    input                                 destWe2_i,
`endif

`ifdef ISSUE_FOUR_WIDE
    input      [DEPTH-1:0]                src1Addr3_i,
    output reg [WIDTH-1:0]                src1Data3_o,
    
    input      [DEPTH-1:0]                src2Addr3_i,
    output reg [WIDTH-1:0]                src2Data3_o,
    
    input      [DEPTH-1:0]                destAddr3_i,
    input      [WIDTH-1:0]                destData3_i,
    input                                 destWe3_i,
`endif

`ifdef ISSUE_FIVE_WIDE
    input      [DEPTH-1:0]                src1Addr4_i,
    output reg [WIDTH-1:0]                src1Data4_o,
    
    input      [DEPTH-1:0]                src2Addr4_i,
    output reg [WIDTH-1:0]                src2Data4_o,
    
    input      [DEPTH-1:0]                destAddr4_i,
    input      [WIDTH-1:0]                destData4_i,
    input                                 destWe4_i,
`endif

`ifdef ISSUE_SIX_WIDE
    input      [DEPTH-1:0]                src1Addr5_i,
    output reg [WIDTH-1:0]                src1Data5_o,
    
    input      [DEPTH-1:0]                src2Addr5_i,
    output reg [WIDTH-1:0]                src2Data5_o,
    
    input      [DEPTH-1:0]                destAddr5_i,
    input      [WIDTH-1:0]                destData5_i,
    input                                 destWe5_i,
`endif

`ifdef ISSUE_SEVEN_WIDE
    input      [DEPTH-1:0]                src1Addr6_i,
    output reg [WIDTH-1:0]                src1Data6_o,
    
    input      [DEPTH-1:0]                src2Addr6_i,
    output reg [WIDTH-1:0]                src2Data6_o,
    
    input      [DEPTH-1:0]                destAddr6_i,
    input      [WIDTH-1:0]                destData6_i,
    input                                 destWe6_i,
`endif

`ifdef ISSUE_EIGHT_WIDE
    input      [DEPTH-1:0]                src1Addr7_i,
    output reg [WIDTH-1:0]                src1Data7_o,
    
    input      [DEPTH-1:0]                src2Addr7_i,
    output reg [WIDTH-1:0]                src2Data7_o,
    
    input      [DEPTH-1:0]                destAddr7_i,
    input      [WIDTH-1:0]                destData7_i,
    input                                 destWe7_i,
`endif

`ifdef DYNAMIC_CONFIG
    input [`EXEC_WIDTH-1:0]               execLaneActive_i,
    input [`NUM_PARTS_RF-1:0]             rfPartitionActive_i,
    input [`ISSUE_WIDTH-1:0][`NUM_PARTS_RF_LOG-1:0] src1DataPartitionSelect_i,
    input [`ISSUE_WIDTH-1:0][`NUM_PARTS_RF_LOG-1:0] src2DataPartitionSelect_i,
`endif    
   
`ifdef PRF_DEBUG_PORT
  `ifdef DYNAMIC_CONFIG
    input [`NUM_PARTS_RF_LOG-1:0]         debugPRFPartitionSelect_i,
  `endif
    input      [`SIZE_PHYSICAL_TABLE-1:0] debugPRFRdAddr_i,      
    output reg [`SRAM_DATA_WIDTH-1:0]     debugPRFRdData_o,
    input      [`SRAM_DATA_WIDTH-1:0]     debugPRFWrData_i,
    input			                            debugPRFWrEn_i,
`endif

    input                                 clk,
    input                                 reset
);

`ifndef DYNAMIC_CONFIG

  /* The RAM reg */
  reg  [WIDTH-1:0]                        ram [DEPTH-1:0];
  
  initial
  begin
      int i;
      for (i = 0; i < DEPTH; i++)
      begin
          ram[i]                      = 0;
      end
  end
  
  /* Read operation */
  always_comb
  begin
      int i;
  
          src1Data0_o                           = ram[0];
          src2Data0_o                           = ram[0];
  
  `ifdef ISSUE_TWO_WIDE
          src1Data1_o                           = ram[0];
          src2Data1_o                           = ram[0];
  `endif
  
  `ifdef ISSUE_THREE_WIDE
          src1Data2_o                           = ram[0];
          src2Data2_o                           = ram[0];
  `endif
  
  `ifdef ISSUE_FOUR_WIDE
          src1Data3_o                           = ram[0];
          src2Data3_o                           = ram[0];
  `endif
  
  `ifdef ISSUE_FIVE_WIDE
          src1Data4_o                           = ram[0];
          src2Data4_o                           = ram[0];
  `endif
  
  `ifdef ISSUE_SIX_WIDE
          src1Data5_o                           = ram[0];
          src2Data5_o                           = ram[0];
  `endif
  
  `ifdef ISSUE_SEVEN_WIDE
          src1Data6_o                           = ram[0];
          src2Data6_o                           = ram[0];
  `endif
  
  `ifdef ISSUE_EIGHT_WIDE
          src1Data7_o                           = ram[0];
          src2Data7_o                           = ram[0];
  `endif

  `ifdef PRF_DEBUG_PORT
 	  debugPRFRdData_o                            = ram[0];
  `endif
           
      for (i = 1; i < DEPTH; i++)
      begin
          if (src1Addr0_i[i]) src1Data0_o       = ram[i];
          if (src2Addr0_i[i]) src2Data0_o       = ram[i];
  
  `ifdef ISSUE_TWO_WIDE
          if (src1Addr1_i[i]) src1Data1_o       = ram[i];
          if (src2Addr1_i[i]) src2Data1_o       = ram[i];
  `endif
  
  `ifdef ISSUE_THREE_WIDE
          if (src1Addr2_i[i]) src1Data2_o       = ram[i];
          if (src2Addr2_i[i]) src2Data2_o       = ram[i];
  `endif
  
  `ifdef ISSUE_FOUR_WIDE
          if (src1Addr3_i[i]) src1Data3_o       = ram[i];
          if (src2Addr3_i[i]) src2Data3_o       = ram[i];
  `endif
  
  `ifdef ISSUE_FIVE_WIDE
          if (src1Addr4_i[i]) src1Data4_o       = ram[i];
          if (src2Addr4_i[i]) src2Data4_o       = ram[i];
  `endif
  
  `ifdef ISSUE_SIX_WIDE
          if (src1Addr5_i[i]) src1Data5_o       = ram[i];
          if (src2Addr5_i[i]) src2Data5_o       = ram[i];
  `endif
  
  `ifdef ISSUE_SEVEN_WIDE
          if (src1Addr6_i[i]) src1Data6_o       = ram[i];
          if (src2Addr6_i[i]) src2Data6_o       = ram[i];
  `endif
  
  `ifdef ISSUE_EIGHT_WIDE
          if (src1Addr7_i[i]) src1Data7_o       = ram[i];
          if (src2Addr7_i[i]) src2Data7_o       = ram[i];
  `endif

  `ifdef PRF_DEBUG_PORT
          if (debugPRFRdAddr_i[i]) debugPRFRdData_o = ram[i];
          // read port for debug interface, seperated from the pipeline read ports
          // as no control is available to mux address between pipeline and
          // debug interface.
  `endif
      end
  end
  
  
  /* Write operation */
  always_ff @(posedge clk)
  begin
      int i;
  
      if (reset)
      begin
          /* TODO: Load PRF from inputs instead of accessing from the testbench */
          //for(i = `SIZE_RMT; i < DEPTH; i++)
          // RBRC: 07/01/2013 Need to reset all the registers
          // as Xs in the read data is propagating to writeback 
          // thorugh the ALUs.
          for(i = 0; i < DEPTH; i++)
          begin
              ram[i]              <= 0;
          end
      end
  
      else
      begin
          for (i = 0; i < DEPTH; i++)
          begin
              if (destWe0_i && destAddr0_i[i])
                  ram[i]            <= destData0_i;
  
  `ifdef ISSUE_TWO_WIDE
              if (destWe1_i && destAddr1_i[i])
                  ram[i]            <= destData1_i;
  `endif
  
  `ifdef ISSUE_THREE_WIDE
              if (destWe2_i && destAddr2_i[i])
                  ram[i]            <= destData2_i;
  `endif
  
  `ifdef ISSUE_FOUR_WIDE
              if (destWe3_i && destAddr3_i[i])
                  ram[i]            <= destData3_i;
  `endif
  
  `ifdef ISSUE_FIVE_WIDE
              if (destWe4_i && destAddr4_i[i])
                  ram[i]            <= destData4_i;
  `endif
  
  `ifdef ISSUE_SIX_WIDE
              if (destWe5_i && destAddr5_i[i])
                  ram[i]            <= destData5_i;
  `endif
  
  `ifdef ISSUE_SEVEN_WIDE
              if (destWe6_i && destAddr6_i[i])
                  ram[i]            <= destData6_i;
  `endif
  
  `ifdef ISSUE_EIGHT_WIDE
              if (destWe7_i && destAddr7_i[i])
                  ram[i]            <= destData7_i;
  `endif
 
  `ifdef PRF_DEBUG_PORT
              if ( debugPRFRdAddr_i && debugPRFWrEn_i)
                  ram[i]            <= debugPRFWrData_i; 
  `endif                  
          end
      end
  end

`else //DYNAMIC_CONFIG

  `ifdef PRF_DEBUG_PORT

      localparam NUM_RD_PORTS   = 2*`ISSUE_WIDTH+1;
      localparam RD_PORTS_LOG   = `ISSUE_WIDTH_LOG+1;

      wire [`ISSUE_WIDTH:0]                   we;
      wire [`ISSUE_WIDTH:0][DEPTH-1:0]        addrWr;
      wire [`ISSUE_WIDTH:0][WIDTH-1:0]        dataWr;

      wire [NUM_RD_PORTS-1:0][DEPTH-1:0]        addr;
      wire [NUM_RD_PORTS-1:0][WIDTH-1:0]        rdData;
      wire [NUM_RD_PORTS-1:0][`NUM_PARTS_RF_LOG-1:0]        rdDataPartition;

      wire [`NUM_PARTS_RF-1:0]                  partitionGated;

      assign partitionGated = ~rfPartitionActive_i;
       
        assign we[0] = debugPRFWrEn_i;
        assign addrWr[0] = debugPRFRdAddr_i;
        assign dataWr[0] = debugPRFWrData_i;


        assign we[1] = destWe0_i;
        assign addrWr[1] = destAddr0_i;
        assign dataWr[1] = destData0_i;

      `ifdef ISSUE_TWO_WIDE
        assign we[2] = destWe1_i;
        assign addrWr[2] = destAddr1_i;
        assign dataWr[2] = destData1_i;
      `endif
      
      `ifdef ISSUE_THREE_WIDE
        assign we[3] = destWe2_i;
        assign addrWr[3] = destAddr2_i;
        assign dataWr[3] = destData2_i;
      `endif
      
      `ifdef ISSUE_FOUR_WIDE
        assign we[4] = destWe3_i;
        assign addrWr[4] = destAddr3_i;
        assign dataWr[4] = destData3_i;
      `endif

      `ifdef ISSUE_FIVE_WIDE
        assign we[5] = destWe4_i;
        assign addrWr[5] = destAddr4_i;
        assign dataWr[5] = destData4_i;
      `endif

      `ifdef ISSUE_SIX_WIDE
        assign we[6] = destWe5_i;
        assign addrWr[6] = destAddr5_i;
        assign dataWr[6] = destData5_i;
      `endif

      `ifdef ISSUE_SEVEN_WIDE
        assign we[7] = destWe6_i;
        assign addrWr[7] = destAddr6_i;
        assign dataWr[7] = destData6_i;
      `endif

      `ifdef ISSUE_EIGHT_WIDE
        assign we[8] = destWe7_i;
        assign addrWr[8] = destAddr7_i;
        assign dataWr[8] = destData7_i;
      `endif


      RAM_PARTITIONED_NO_DECODE #(
      	// Parameters 
      	.DEPTH(DEPTH),
      	.INDEX(INDEX),
      	.WIDTH(WIDTH),
        .NUM_WR_PORTS(`ISSUE_WIDTH+1),
        .NUM_RD_PORTS(NUM_RD_PORTS),
        .WR_PORTS_LOG(`ISSUE_WIDTH_LOG+1),
        .NUM_PARTS(`NUM_PARTS_RF),
        .NUM_PARTS_LOG(`NUM_PARTS_RF_LOG),
        .RESET_VAL(`RAM_RESET_ZERO),
        .SEQ_START(0),   // Reset the RMT rams to contain first LOG_REG sequential mappings
        .PARENT_MODULE("PRF")
      ) ram_partitioned_no_decode
      (
      
        .partitionGated_i(partitionGated),

      	.addr_i(addr),
        .rdDataPartition_i(rdDataPartition),
      	.data_o(rdData),
      
      	.addrWr_i(addrWr),
      	.dataWr_i(dataWr),
      
      	.wrEn_i(we),
      
      	.clk(clk),
      	.reset(reset),
        .ramReady_o()
      );


      // Read operation
      assign addr[0]             = debugPRFRdAddr_i ;
      assign rdDataPartition[0]  = debugPRFPartitionSelect_i;
      assign debugPRFRdData_o    = rdData[0];
 
      assign addr[1]     = src1Addr0_i;
      assign addr[2]     = src2Addr0_i;
      assign src1Data0_o = rdData[1];
      assign src2Data0_o = rdData[2];
      assign rdDataPartition[1] = src1DataPartitionSelect_i[0];
      assign rdDataPartition[2] = src2DataPartitionSelect_i[0];
      

      `ifdef ISSUE_TWO_WIDE
      assign addr[3]     = src1Addr1_i;
      assign addr[4]     = src2Addr1_i;
      assign src1Data1_o = rdData[3];
      assign src2Data1_o = rdData[4];
      assign rdDataPartition[3] = src1DataPartitionSelect_i[1];
      assign rdDataPartition[4] = src2DataPartitionSelect_i[1];
      `endif
      
      `ifdef ISSUE_THREE_WIDE
      assign addr[5]     = src1Addr2_i;
      assign addr[6]     = src2Addr2_i;
      assign src1Data2_o = rdData[5];
      assign src2Data2_o = rdData[6];
      assign rdDataPartition[5] = src1DataPartitionSelect_i[2];
      assign rdDataPartition[6] = src2DataPartitionSelect_i[2];
      `endif
      
      `ifdef ISSUE_FOUR_WIDE
      assign addr[7]     = src1Addr3_i;
      assign addr[8]     = src2Addr3_i;
      assign src1Data3_o = rdData[7];
      assign src2Data3_o = rdData[8];
      assign rdDataPartition[7] = src1DataPartitionSelect_i[3];
      assign rdDataPartition[8] = src2DataPartitionSelect_i[3];
      `endif
      
      `ifdef ISSUE_FIVE_WIDE
      assign addr[9]     = src1Addr4_i;
      assign addr[10]     = src2Addr4_i;
      assign src1Data4_o = rdData[9];
      assign src2Data4_o = rdData[10];
      assign rdDataPartition[9] = src1DataPartitionSelect_i[4];
      assign rdDataPartition[10] = src2DataPartitionSelect_i[4];
      `endif
      
      `ifdef ISSUE_SIX_WIDE
      assign addr[11]     = src1Addr5_i;
      assign addr[12]     = src2Addr5_i;
      assign src1Data5_o = rdData[11];
      assign src2Data5_o = rdData[12];
      assign rdDataPartition[11] = src1DataPartitionSelect_i[5];
      assign rdDataPartition[12] = src2DataPartitionSelect_i[5];
      `endif
      
      `ifdef ISSUE_SEVEN_WIDE
      assign addr[13]     = src1Addr6_i;
      assign addr[14]     = src2Addr6_i;
      assign src1Data6_o = rdData[13];
      assign src2Data6_o = rdData[14];
      assign rdDataPartition[13] = src1DataPartitionSelect_i[6];
      assign rdDataPartition[14] = src2DataPartitionSelect_i[6];
      `endif
      
      `ifdef ISSUE_EIGHT_WIDE
      assign addr[15]     = src1Addr7_i;
      assign addr[16]     = src2Addr72_i;
      assign src1Data7_o = rdData[15];
      assign src2Data7_o = rdData[16];
      assign rdDataPartition[15] = src1DataPartitionSelect_i[7];
      assign rdDataPartition[16] = src2DataPartitionSelect_i[7;]
      `endif


  `else // No PRF_DEBUG_PORT

      localparam NUM_RD_PORTS   = 2*`ISSUE_WIDTH;
      localparam RD_PORTS_LOG   = `ISSUE_WIDTH_LOG+1;

      wire [`ISSUE_WIDTH-1:0]                   we;
      wire [`ISSUE_WIDTH-1:0][DEPTH-1:0]        addrWr;
      wire [`ISSUE_WIDTH-1:0][WIDTH-1:0]        dataWr;

      wire [NUM_RD_PORTS-1:0][DEPTH-1:0]        addr;
      wire [NUM_RD_PORTS-1:0][WIDTH-1:0]        rdData;
      wire [NUM_RD_PORTS-1:0][`NUM_PARTS_RF_LOG-1:0]        rdDataPartition;

      wire [`NUM_PARTS_RF-1:0]                  partitionGated;

      assign partitionGated = ~rfPartitionActive_i;
       

        assign we[0] = destWe0_i;
        assign addrWr[0] = destAddr0_i;
        assign dataWr[0] = destData0_i;

      `ifdef ISSUE_TWO_WIDE
        assign we[1] = destWe1_i;
        assign addrWr[1] = destAddr1_i;
        assign dataWr[1] = destData1_i;
      `endif
      
      `ifdef ISSUE_THREE_WIDE
        assign we[2] = destWe2_i;
        assign addrWr[2] = destAddr2_i;
        assign dataWr[2] = destData2_i;
      `endif
      
      `ifdef ISSUE_FOUR_WIDE
        assign we[3] = destWe3_i;
        assign addrWr[3] = destAddr3_i;
        assign dataWr[3] = destData3_i;
      `endif

      `ifdef ISSUE_FIVE_WIDE
        assign we[4] = destWe4_i;
        assign addrWr[4] = destAddr4_i;
        assign dataWr[4] = destData4_i;
      `endif

      `ifdef ISSUE_SIX_WIDE
        assign we[5] = destWe5_i;
        assign addrWr[5] = destAddr5_i;
        assign dataWr[5] = destData5_i;
      `endif

      `ifdef ISSUE_SEVEN_WIDE
        assign we[6] = destWe6_i;
        assign addrWr[6] = destAddr6_i;
        assign dataWr[6] = destData6_i;
      `endif

      `ifdef ISSUE_EIGHT_WIDE
        assign we[7] = destWe7_i;
        assign addrWr[7] = destAddr7_i;
        assign dataWr[7] = destData7_i;
      `endif


      RAM_PARTITIONED_NO_DECODE #(
      	// Parameters 
      	.DEPTH(DEPTH),
      	.INDEX(INDEX),
      	.WIDTH(WIDTH),
        .NUM_WR_PORTS(`ISSUE_WIDTH),
        .NUM_RD_PORTS(NUM_RD_PORTS),
        .WR_PORTS_LOG(`ISSUE_WIDTH_LOG+1),
        .NUM_PARTS(`NUM_PARTS_RF),
        .NUM_PARTS_LOG(`NUM_PARTS_RF_LOG),
        .RESET_VAL(`RAM_RESET_ZERO),
        .SEQ_START(0),   // Reset the RMT rams to contain first LOG_REG sequential mappings
        .PARENT_MODULE("PRF")
      ) ram_partitioned_no_decode
      (
      
        .partitionGated_i(partitionGated),

      	.addr_i(addr),
        .rdDataPartition_i(rdDataPartition),
      	.data_o(rdData),
      
      	.addrWr_i(addrWr),
      	.dataWr_i(dataWr),
      
      	.wrEn_i(we),
      
      	.clk(clk),
      	.reset(reset),
        .ramReady_o()
      );


      // Read operation
 
      assign addr[0]     = src1Addr0_i;
      assign addr[1]     = src2Addr0_i;
      assign src1Data0_o = rdData[0];
      assign src2Data0_o = rdData[1];
      assign rdDataPartition[0] = src1DataPartitionSelect_i[0];
      assign rdDataPartition[1] = src2DataPartitionSelect_i[0];
      

      `ifdef ISSUE_TWO_WIDE
      assign addr[2]     = src1Addr1_i;
      assign addr[3]     = src2Addr1_i;
      assign src1Data1_o = rdData[2];
      assign src2Data1_o = rdData[3];
      assign rdDataPartition[2] = src1DataPartitionSelect_i[1];
      assign rdDataPartition[3] = src2DataPartitionSelect_i[1];
      `endif
      
      `ifdef ISSUE_THREE_WIDE
      assign addr[4]     = src1Addr2_i;
      assign addr[5]     = src2Addr2_i;
      assign src1Data2_o = rdData[4];
      assign src2Data2_o = rdData[5];
      assign rdDataPartition[4] = src1DataPartitionSelect_i[2];
      assign rdDataPartition[5] = src2DataPartitionSelect_i[2];
      `endif
      
      `ifdef ISSUE_FOUR_WIDE
      assign addr[6]     = src1Addr3_i;
      assign addr[7]     = src2Addr3_i;
      assign src1Data3_o = rdData[6];
      assign src2Data3_o = rdData[7];
      assign rdDataPartition[6] = src1DataPartitionSelect_i[3];
      assign rdDataPartition[7] = src2DataPartitionSelect_i[3];
      `endif
      
      `ifdef ISSUE_FIVE_WIDE
      assign addr[8]     = src1Addr4_i;
      assign addr[9]     = src2Addr4_i;
      assign src1Data4_o = rdData[8];
      assign src2Data4_o = rdData[9];
      assign rdDataPartition[8] = src1DataPartitionSelect_i[4];
      assign rdDataPartition[9] = src2DataPartitionSelect_i[4];
      `endif
      
      `ifdef ISSUE_SIX_WIDE
      assign addr[10]     = src1Addr5_i;
      assign addr[11]     = src2Addr5_i;
      assign src1Data5_o = rdData[10];
      assign src2Data5_o = rdData[11];
      assign rdDataPartition[10] = src1DataPartitionSelect_i[5];
      assign rdDataPartition[11] = src2DataPartitionSelect_i[5];
      `endif
      
      `ifdef ISSUE_SEVEN_WIDE
      assign addr[12]     = src1Addr6_i;
      assign addr[13]     = src2Addr6_i;
      assign src1Data6_o = rdData[12];
      assign src2Data6_o = rdData[13];
      assign rdDataPartition[12] = src1DataPartitionSelect_i[6];
      assign rdDataPartition[13] = src2DataPartitionSelect_i[6];
      `endif
      
      `ifdef ISSUE_EIGHT_WIDE
      assign addr[14]     = src1Addr7_i;
      assign addr[15]     = src2Addr72_i;
      assign src1Data7_o = rdData[14];
      assign src2Data7_o = rdData[15];
      assign rdDataPartition[14] = src1DataPartitionSelect_i[7];
      assign rdDataPartition[15] = src2DataPartitionSelect_i[7;]
      `endif


  `endif // PRF_DEBUG_PORT
 

`endif //DYNAMIC_CONFIG

endmodule

