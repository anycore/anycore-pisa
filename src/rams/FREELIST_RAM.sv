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

module FREELIST_RAM #(
	/* Parameters */
	parameter DEPTH        = 16,
	parameter INDEX        = 4,
	parameter WIDTH        = 8
) (

	input  [INDEX-1:0]            addr0_i,
	output [WIDTH-1:0]            data0_o,

`ifdef DISPATCH_TWO_WIDE
	input  [INDEX-1:0]            addr1_i,
	output [WIDTH-1:0]            data1_o,
`endif

`ifdef DISPATCH_THREE_WIDE
	input  [INDEX-1:0]            addr2_i,
	output [WIDTH-1:0]            data2_o,
`endif

`ifdef DISPATCH_FOUR_WIDE
	input  [INDEX-1:0]            addr3_i,
	output [WIDTH-1:0]            data3_o,
`endif

`ifdef DISPATCH_FIVE_WIDE
	input  [INDEX-1:0]            addr4_i,
	output [WIDTH-1:0]            data4_o,
`endif

`ifdef DISPATCH_SIX_WIDE
	input  [INDEX-1:0]            addr5_i,
	output [WIDTH-1:0]            data5_o,
`endif

`ifdef DISPATCH_SEVEN_WIDE
	input  [INDEX-1:0]            addr6_i,
	output [WIDTH-1:0]            data6_o,
`endif

`ifdef DISPATCH_EIGHT_WIDE
	input  [INDEX-1:0]            addr7_i,
	output [WIDTH-1:0]            data7_o,
`endif


	input  [INDEX-1:0]            addr0wr_i,
	input  [WIDTH-1:0]            data0wr_i,
	input                         we0_i,

`ifdef COMMIT_TWO_WIDE
	input  [INDEX-1:0]            addr1wr_i,
	input  [WIDTH-1:0]            data1wr_i,
	input                         we1_i,
`endif

`ifdef COMMIT_THREE_WIDE
	input  [INDEX-1:0]            addr2wr_i,
	input  [WIDTH-1:0]            data2wr_i,
	input                         we2_i,
`endif

`ifdef COMMIT_FOUR_WIDE
	input  [INDEX-1:0]            addr3wr_i,
	input  [WIDTH-1:0]            data3wr_i,
	input                         we3_i,
`endif

`ifdef DYNAMIC_CONFIG  
  input [`COMMIT_WIDTH-1:0]     commitLaneActive_i,
  input [`DISPATCH_WIDTH-1:0]   dispatchLaneActive_i,
  input [`NUM_PARTS_RF-1:0]     rfPartitionActive_i,
  output                        freeListReady_o,
`endif

	input                         clk,
	input                         reset

);


`ifndef DYNAMIC_CONFIG

  reg [WIDTH-1:0]            ram [DEPTH-1:0];
  
  
  /* Read operation */
  assign data0_o           = ram[addr0_i];
  
  `ifdef DISPATCH_TWO_WIDE
  assign data1_o           = ram[addr1_i];
  `endif
  
  `ifdef DISPATCH_THREE_WIDE
  assign data2_o           = ram[addr2_i];
  `endif
  
  `ifdef DISPATCH_FOUR_WIDE
  assign data3_o           = ram[addr3_i];
  `endif
  
  `ifdef DISPATCH_FIVE_WIDE
  assign data4_o           = ram[addr4_i];
  `endif
  
  `ifdef DISPATCH_SIX_WIDE
  assign data5_o           = ram[addr5_i];
  `endif
  
  `ifdef DISPATCH_SEVEN_WIDE
  assign data6_o           = ram[addr6_i];
  `endif
  
  `ifdef DISPATCH_EIGHT_WIDE
  assign data7_o           = ram[addr7_i];
  `endif
  
  
  /* Write operation */
  always_ff @(posedge clk)
  begin
  	int i;
  
  	if (reset)
  	begin
  		for (i = 0; i < DEPTH; i++)
  		begin
  			ram[i]         <= i + `SIZE_RMT;
  		end
  	end
  
  	else
  	begin
  		if (we0_i)
  		begin
  			ram[addr0wr_i] <= data0wr_i;
  		end
  
  `ifdef COMMIT_TWO_WIDE
  		if (we1_i)
  		begin
  			ram[addr1wr_i] <= data1wr_i;
  		end
  `endif
  
  `ifdef COMMIT_THREE_WIDE
  		if (we2_i)
  		begin
  			ram[addr2wr_i] <= data2wr_i;
  		end
  `endif
  
  `ifdef COMMIT_FOUR_WIDE
  		if (we3_i)
  		begin
  			ram[addr3wr_i] <= data3wr_i;
  		end
  `endif
  	end
  end
  

`else //DYNAMIC_CONFIG

  localparam PARTS_FREELIST = `NUM_PARTS_RF - 1;

  wire [`COMMIT_WIDTH-1:0]                we;
  wire [`COMMIT_WIDTH-1:0][INDEX-1:0]     addrWr;
  wire [`COMMIT_WIDTH-1:0][WIDTH-1:0]     dataWr;

  wire [`DISPATCH_WIDTH-1:0][INDEX-1:0]   addr;
  wire [`DISPATCH_WIDTH-1:0][WIDTH-1:0]   rdData;

  wire [`COMMIT_WIDTH-1:0]                writePortGated;
  wire [`DISPATCH_WIDTH-1:0]              readPortGated;
  wire [PARTS_FREELIST-1:0]               partitionGated;

  assign writePortGated   = ~commitLaneActive_i;
  assign readPortGated    = ~dispatchLaneActive_i;
  assign partitionGated   = ~rfPartitionActive_i[`NUM_PARTS_RF-1:1]; // This depends on the number of RF partitions needed for architectural regs


    assign we[0] = we0_i;
    assign addrWr[0] = addr0wr_i;
    assign dataWr[0] = data0wr_i;

  `ifdef COMMIT_TWO_WIDE
    assign we[1] = we1_i;
    assign addrWr[1] = addr1wr_i;
    assign dataWr[1] = data1wr_i;
  `endif
  
  `ifdef COMMIT_THREE_WIDE
    assign we[2] = we2_i;
    assign addrWr[2] = addr2wr_i;
    assign dataWr[2] = data2wr_i;
  `endif
  
  `ifdef COMMIT_FOUR_WIDE
    assign we[3] = we3_i;
    assign addrWr[3] = addr3wr_i;
    assign dataWr[3] = data3wr_i;
  `endif
  


  // TODO: The freeList must use partitioned RAM
  // To account for 34 architectural registers, make divisible by 3 by making the 
  // depth 2 more than needed - 32 entries in each partition.
  // The circular queue pointer logic makes sure that the extra 2 locations are never referenced.

  RAM_CONFIGURABLE #(
  	/* Parameters */
  	.DEPTH(DEPTH+2),  
  	.INDEX(INDEX),
  	.WIDTH(WIDTH),
    .NUM_WR_PORTS(`COMMIT_WIDTH),
    .NUM_RD_PORTS(`DISPATCH_WIDTH),
    .WR_PORTS_LOG(`COMMIT_WIDTH_LOG),
    .RESET_VAL(`RAM_RESET_SEQ),
    .SEQ_START(`SIZE_RMT),   // Reset the RMT rams to contain first LOG_REG sequential mappings
    .USE_PARTITIONED(1),
    .USE_FLIP_FLOP(0),
    .NUM_PARTS(PARTS_FREELIST),
    .NUM_PARTS_LOG(2),
    .PARENT_MODULE("FREELIST")
  ) ram_configurable
  (
  
    .writePortGated_i(writePortGated),
    .readPortGated_i(readPortGated),
    .partitionGated_i(partitionGated),
  
  	.addr_i(addr),
  	.data_o(rdData),
  
  	.addrWr_i(addrWr),
  	.dataWr_i(dataWr),
  
  	.wrEn_i(we),
  
  	.clk(clk),
  	.reset(reset),
    .ramReady_o(freeListReady_o)
  );


  /* Read operation */
  assign addr[0]     = addr0_i;
  assign data0_o     = rdData[0];
  
  `ifdef DISPATCH_TWO_WIDE
  assign addr[1]     = addr1_i;
  assign data1_o     = rdData[1];
  `endif
  
  `ifdef DISPATCH_THREE_WIDE
  assign addr[2]     = addr2_i;
  assign data2_o     = rdData[2];
  `endif
  
  `ifdef DISPATCH_FOUR_WIDE
  assign addr[3]     = addr3_i;
  assign data3_o     = rdData[3];
  `endif
  
  `ifdef DISPATCH_FIVE_WIDE
  assign addr[4]     = addr4_i;
  assign data4_o     = rdData[4];
  `endif
  
  `ifdef DISPATCH_SIX_WIDE
  assign addr[5]     = addr5_i;
  assign data5_o     = rdData[5];
  `endif
  
  `ifdef DISPATCH_SEVEN_WIDE
  assign addr[6]     = addr6_i;
  assign data6_o     = rdData[6];
  `endif
  
  `ifdef DISPATCH_EIGHT_WIDE
  assign addr[7]     = addr7_i;
  assign data7_o     = rdData[7];
  `endif

 

`endif //DYNAMIC_CONFIG

endmodule

