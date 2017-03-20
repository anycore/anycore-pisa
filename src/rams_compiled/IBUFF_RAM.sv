/***************************************************************************
                     NORTH CAROLINA STATE UNIVERSITY
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
***************************************************************************/
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

module IBUFF_RAM #(

	/* Parameters */
	parameter DEPTH = 16,
	parameter INDEX = 4,
	parameter WIDTH = 8
) (

	input  [INDEX-1:0]                addr0_i,
	output [WIDTH-1:0]                data0_o,

`ifdef DISPATCH_TWO_WIDE
	input  [INDEX-1:0]                addr1_i,
	output [WIDTH-1:0]                data1_o,
`endif

`ifdef DISPATCH_THREE_WIDE
	input  [INDEX-1:0]                addr2_i,
	output [WIDTH-1:0]                data2_o,
`endif

`ifdef DISPATCH_FOUR_WIDE
	input  [INDEX-1:0]                addr3_i,
	output [WIDTH-1:0]                data3_o,
`endif

`ifdef DISPATCH_FIVE_WIDE
	input  [INDEX-1:0]                addr4_i,
	output [WIDTH-1:0]                data4_o,
`endif

`ifdef DISPATCH_SIX_WIDE
	input  [INDEX-1:0]                addr5_i,
	output [WIDTH-1:0]                data5_o,
`endif

`ifdef DISPATCH_SEVEN_WIDE
	input  [INDEX-1:0]                addr6_i,
	output [WIDTH-1:0]                data6_o,
`endif

`ifdef DISPATCH_EIGHT_WIDE
	input  [INDEX-1:0]                addr7_i,
	output [WIDTH-1:0]                data7_o,
`endif


	input  [INDEX-1:0]                addr0wr_i,
	input  [WIDTH-1:0]                data0wr_i,
	input                             we0_i,

	input  [INDEX-1:0]                addr1wr_i,
	input  [WIDTH-1:0]                data1wr_i,
	input                             we1_i,

`ifdef FETCH_TWO_WIDE
	input  [INDEX-1:0]                addr2wr_i,
	input  [WIDTH-1:0]                data2wr_i,
	input                             we2_i,

	input  [INDEX-1:0]                addr3wr_i,
	input  [WIDTH-1:0]                data3wr_i,
	input                             we3_i,
`endif

`ifdef FETCH_THREE_WIDE
	input  [INDEX-1:0]                addr4wr_i,
	input  [WIDTH-1:0]                data4wr_i,
	input                             we4_i,

	input  [INDEX-1:0]                addr5wr_i,
	input  [WIDTH-1:0]                data5wr_i,
	input                             we5_i,
`endif

`ifdef FETCH_FOUR_WIDE
	input  [INDEX-1:0]                addr6wr_i,
	input  [WIDTH-1:0]                data6wr_i,
	input                             we6_i,

	input  [INDEX-1:0]                addr7wr_i,
	input  [WIDTH-1:0]                data7wr_i,
	input                             we7_i,
`endif

`ifdef FETCH_FIVE_WIDE
	input  [INDEX-1:0]                addr8wr_i,
	input  [WIDTH-1:0]                data8wr_i,
	input                             we8_i,

	input  [INDEX-1:0]                addr9wr_i,
	input  [WIDTH-1:0]                data9wr_i,
	input                             we9_i,
`endif

`ifdef FETCH_SIX_WIDE
	input  [INDEX-1:0]                addr10wr_i,
	input  [WIDTH-1:0]                data10wr_i,
	input                             we10_i,

	input  [INDEX-1:0]                addr11wr_i,
	input  [WIDTH-1:0]                data11wr_i,
	input                             we11_i,
`endif

`ifdef FETCH_SEVEN_WIDE
	input  [INDEX-1:0]                addr12wr_i,
	input  [WIDTH-1:0]                data12wr_i,
	input                             we12_i,

	input  [INDEX-1:0]                addr13wr_i,
	input  [WIDTH-1:0]                data13wr_i,
	input                             we13_i,
`endif

`ifdef FETCH_EIGHT_WIDE
	input  [INDEX-1:0]                addr14wr_i,
	input  [WIDTH-1:0]                data14wr_i,
	input                             we14_i,

	input  [INDEX-1:0]                addr15wr_i,
	input  [WIDTH-1:0]                data15wr_i,
	input                             we15_i,
`endif

//`ifdef DYNAMIC_CONFIG
//  input  [`FETCH_WIDTH-1:0]         fetchLaneActive_i,
//  input  [`DISPATCH_WIDTH-1:0]      dispatchLaneActive_i,
//  input  [`STRUCT_PARTS-1:0]        ibuffPartitionActive_i,
//  output                            ibuffRamReady_o,
//`endif

	input                             clk,
	input                             reset
);

//synopsys translate_off

//`ifndef DYNAMIC_CONFIG

  reg  [WIDTH-1:0]                    ram [DEPTH-1:0];
  
  
  /* Read operation */
  assign data0_o                    = ram[addr0_i];
  
  `ifdef DISPATCH_TWO_WIDE
  assign data1_o                    = ram[addr1_i];
  `endif
  
  `ifdef DISPATCH_THREE_WIDE
  assign data2_o                    = ram[addr2_i];
  `endif
  
  `ifdef DISPATCH_FOUR_WIDE
  assign data3_o                    = ram[addr3_i];
  `endif
  
  `ifdef DISPATCH_FIVE_WIDE
  assign data4_o                    = ram[addr4_i];
  `endif
  
  `ifdef DISPATCH_SIX_WIDE
  assign data5_o                    = ram[addr5_i];
  `endif
  
  `ifdef DISPATCH_SEVEN_WIDE
  assign data6_o                    = ram[addr6_i];
  `endif
  
  `ifdef DISPATCH_EIGHT_WIDE
  assign data7_o                    = ram[addr7_i];
  `endif
  
  
  /* Write operation */
  always_ff @(posedge clk)
  begin
  	int i;
  
  	if (reset)
  	begin
  		for (i = 0; i < DEPTH; i++)
  		begin
  			ram[i]         <= {WIDTH{1'b0}};
  		end
  	end
  
  	else
  	begin
  		if (we0_i)
  		begin
  			ram[addr0wr_i] <= data0wr_i;
  		end
  
  		if (we1_i)
  		begin
  			ram[addr1wr_i] <= data1wr_i;
  		end
  
  `ifdef FETCH_TWO_WIDE
  		if (we2_i)
  		begin
  			ram[addr2wr_i] <= data2wr_i;
  		end
  
  		if (we3_i)
  		begin
  			ram[addr3wr_i] <= data3wr_i;
  		end
  `endif
  
  `ifdef FETCH_THREE_WIDE
  		if (we4_i)
  		begin
  			ram[addr4wr_i] <= data4wr_i;
  		end
  
  		if (we5_i)
  		begin
  			ram[addr5wr_i] <= data5wr_i;
  		end
  `endif
  
  `ifdef FETCH_FOUR_WIDE
  		if (we6_i)
  		begin
  			ram[addr6wr_i] <= data6wr_i;
  		end
  
  		if (we7_i)
  		begin
  			ram[addr7wr_i] <= data7wr_i;
  		end
  `endif
  
  `ifdef FETCH_FIVE_WIDE
  		if (we8_i)
  		begin
  			ram[addr8wr_i] <= data8wr_i;
  		end
  
  		if (we9_i)
  		begin
  			ram[addr9wr_i] <= data9wr_i;
  		end
  `endif
  
  `ifdef FETCH_SIX_WIDE
  		if (we10_i)
  		begin
  			ram[addr10wr_i] <= data10wr_i;
  		end
  
  		if (we11_i)
  		begin
  			ram[addr11wr_i] <= data11wr_i;
  		end
  `endif
  
  `ifdef FETCH_SEVEN_WIDE
  		if (we12_i)
  		begin
  			ram[addr12wr_i] <= data12wr_i;
  		end
  
  		if (we13_i)
  		begin
  			ram[addr13wr_i] <= data13wr_i;
  		end
  `endif
  
  `ifdef FETCH_EIGHT_WIDE
  		if (we14_i)
  		begin
  			ram[addr14wr_i] <= data14wr_i;
  		end
  
  		if (we15_i)
  		begin
  			ram[addr15wr_i] <= data15wr_i;
  		end
  `endif
  	end
  end

//`else //DYNAMIC_CONFIG
//
//
//  wire [(2*`FETCH_WIDTH)-1:0]                   we;
//  wire [(2*`FETCH_WIDTH)-1:0][INDEX-1:0]        addrWr;
//  wire [(2*`FETCH_WIDTH)-1:0][WIDTH-1:0]        dataWr;
//
//  wire [`DISPATCH_WIDTH-1:0][INDEX-1:0]         addr;
//  wire [`DISPATCH_WIDTH-1:0][WIDTH-1:0]         rdData;
//
//  reg  [(2*`FETCH_WIDTH)-1:0]                   writePortGated;
//  wire [`DISPATCH_WIDTH-1:0]                    readPortGated;
//  wire [`STRUCT_PARTS-1:0]                      partitionGated;
//
//
//  always_comb
//  begin
//    int i;
//    for(i = 0; i < `FETCH_WIDTH; i = i + 1)
//      writePortGated[2*i+1-:2] = {2{~fetchLaneActive_i[i]}};
//  end
//
//  assign readPortGated  = ~dispatchLaneActive_i;
//  assign partitionGated = ~ibuffPartitionActive_i;
//
//
//    assign we[0] = we0_i;
//    assign addrWr[0] = addr0wr_i;
//    assign dataWr[0] = data0wr_i;
//
//    assign we[1] = we1_i;
//    assign addrWr[1] = addr1wr_i;
//    assign dataWr[1] = data1wr_i;
//
//  `ifdef FETCH_TWO_WIDE
//    assign we[2] = we2_i;
//    assign addrWr[2] = addr2wr_i;
//    assign dataWr[2] = data2wr_i;
//
//    assign we[3] = we3_i;
//    assign addrWr[3] = addr3wr_i;
//    assign dataWr[3] = data3wr_i;
//  `endif
//  
//  `ifdef FETCH_THREE_WIDE
//    assign we[4] = we4_i;
//    assign addrWr[4] = addr4wr_i;
//    assign dataWr[4] = data4wr_i;
//
//    assign we[5] = we5_i;
//    assign addrWr[5] = addr5wr_i;
//    assign dataWr[5] = data5wr_i;
//  `endif
//  
//  `ifdef FETCH_FOUR_WIDE
//    assign we[6] = we6_i;
//    assign addrWr[6] = addr6wr_i;
//    assign dataWr[6] = data6wr_i;
//
//    assign we[7] = we7_i;
//    assign addrWr[7] = addr7wr_i;
//    assign dataWr[7] = data7wr_i;
//  `endif
//  
//  `ifdef FETCH_FIVE_WIDE
//    assign we[8] = we8_i;
//    assign addrWr[8] = addr8wr_i;
//    assign dataWr[8] = data8wr_i;
//
//    assign we[9] = we9_i;
//    assign addrWr[9] = addr9wr_i;
//    assign dataWr[9] = data9wr_i;
//  `endif
//  
//  `ifdef FETCH_SIX_WIDE
//    assign we[10] = we10_i;
//    assign addrWr[10] = addr10wr_i;
//    assign dataWr[10] = data10wr_i;
//
//    assign we[11] = we11_i;
//    assign addrWr[11] = addr11wr_i;
//    assign dataWr[11] = data11wr_i;
//  `endif
//  
//  `ifdef FETCH_SEVEN_WIDE
//    assign we[12] = we12_i;
//    assign addrWr[12] = addr12wr_i;
//    assign dataWr[12] = data12wr_i;
//
//    assign we[13] = we13_i;
//    assign addrWr[13] = addr13wr_i;
//    assign dataWr[13] = data13wr_i;
//  `endif
//  
//  `ifdef FETCH_EIGHT_WIDE
//    assign we[14] = we14_i;
//    assign addrWr[14] = addr14wr_i;
//    assign dataWr[14] = data14wr_i;
//
//    assign we[15] = we15_i;
//    assign addrWr[15] = addr15wr_i;
//    assign dataWr[15] = data15wr_i;
//  `endif
//
//
//
//  /* Read operation */
//  assign addr[0]     = addr0_i;
//  assign data0_o     = rdData[0];
//  
//  `ifdef DISPATCH_TWO_WIDE
//  assign addr[1]     = addr1_i;
//  assign data1_o     = rdData[1];
//  `endif
//  
//  `ifdef DISPATCH_THREE_WIDE
//  assign addr[2]     = addr2_i;
//  assign data2_o     = rdData[2];
//  `endif
//  
//  `ifdef DISPATCH_FOUR_WIDE
//  assign addr[3]     = addr3_i;
//  assign data3_o     = rdData[3];
//  `endif
//  
//  `ifdef DISPATCH_FIVE_WIDE
//  assign addr[4]     = addr4_i;
//  assign data4_o     = rdData[4];
//  `endif
//  
//  `ifdef DISPATCH_SIX_WIDE
//  assign addr[5]     = addr5_i;
//  assign data5_o     = rdData[5];
//  `endif
//  
//  `ifdef DISPATCH_SEVEN_WIDE
//  assign addr[6]     = addr6_i;
//  assign data6_o     = rdData[6];
//  `endif
//
//  `ifdef DISPATCH_EIGHT_WIDE
//  assign addr[7]     = addr7_i;
//  assign data7_o     = rdData[7];
//  `endif
//
//
//
//  //TODO: Write the reset state machine
//
//
//  RAM_CONFIGURABLE #(
//  	/* Parameters */
//  	.DEPTH(DEPTH),
//  	.INDEX(INDEX),
//  	.WIDTH(WIDTH),
//    .NUM_WR_PORTS(2*`FETCH_WIDTH),
//    .NUM_RD_PORTS(`DISPATCH_WIDTH),
//    .WR_PORTS_LOG(`FETCH_WIDTH_LOG+1),
//    .GATING_ENABLED(1),
//    .USE_PARTITIONED(0),
//    .USE_FLIP_FLOP(1),
//    .RESET_VAL(`RAM_RESET_ZERO),
//    .SEQ_START(0),   // Reset the RMT rams to contain first LOG_REG sequential mappings
//    .PARENT_MODULE("IBUFF") // Used for debug prints inside
//  ) ram_configurable
//  (
//  
//    .writePortGated_i(writePortGated),
//    .readPortGated_i(readPortGated),
//    .partitionGated_i(partitionGated),
//  
//  	.addr_i(addr),
//  	.data_o(rdData),
//  
//  	.addrWr_i(addrWr),
//  	.dataWr_i(dataWr),
//  
//  	.wrEn_i(we),
//  
//  	.clk(clk),
//  	.reset(reset),
//    .ramReady_o(ibuffRamReady_o)
//  );
//
//
//
//`endif //DYNAMIC_CONFIG

//synopsys translate_on

endmodule


