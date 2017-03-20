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

module ALNPC_RAM #(

	/* Parameters */
	parameter DEPTH = 16,
	parameter INDEX = 4,
	parameter WIDTH = 8
	) (

	input  [INDEX-1:0]                addr0_i,
	output [WIDTH-1:0]                data0_o,


	input  [INDEX-1:0]                addr0wr_i,
	input  [WIDTH-1:0]                data0wr_i,
	input                             we0_i,

`ifdef ISSUE_TWO_WIDE
	input  [INDEX-1:0]                addr1wr_i,
	input  [WIDTH-1:0]                data1wr_i,
	input                             we1_i,
`endif

`ifdef ISSUE_THREE_WIDE
	input  [INDEX-1:0]                addr2wr_i,
	input  [WIDTH-1:0]                data2wr_i,
	input                             we2_i,
`endif

`ifdef ISSUE_FOUR_WIDE
	input  [INDEX-1:0]                addr3wr_i,
	input  [WIDTH-1:0]                data3wr_i,
	input                             we3_i,
`endif

`ifdef ISSUE_FIVE_WIDE
	input  [INDEX-1:0]                addr4wr_i,
	input  [WIDTH-1:0]                data4wr_i,
	input                             we4_i,
`endif

`ifdef ISSUE_SIX_WIDE
	input  [INDEX-1:0]                addr5wr_i,
	input  [WIDTH-1:0]                data5wr_i,
	input                             we5_i,
`endif

`ifdef ISSUE_SEVEN_WIDE
	input  [INDEX-1:0]                addr6wr_i,
	input  [WIDTH-1:0]                data6wr_i,
	input                             we6_i,
`endif

`ifdef ISSUE_EIGHT_WIDE
	input  [INDEX-1:0]                addr7wr_i,
	input  [WIDTH-1:0]                data7wr_i,
	input                             we7_i,
`endif

`ifdef DYNAMIC_CONFIG
  input  [`ISSUE_WIDTH-1:0]         issueLaneActive_i,
  input  [`NUM_PARTS_RF-1:0]        alPartitionActive_i,
  output                            alNPcReady_o,
`endif

	input                             clk,
	input                             reset
);

//synopsys translate_off

`ifndef DYNAMIC_CONFIG


  reg  [WIDTH-1:0]                    ram [DEPTH-1:0];
  
  
  /* Read operation */
  assign data0_o                    = ram[addr0_i];
  
  
  /* Write operation */
  always_ff @(posedge clk)
  begin
  	int i;
  
  	if (reset)
  	begin
  		for (i = 0; i < DEPTH; i++)
  		begin
  			ram[i]         <= 0;
  		end
  	end
  
  	else
  	begin
  		if (we0_i)
  		begin
  			ram[addr0wr_i] <= data0wr_i;
  		end
  
  `ifdef ISSUE_TWO_WIDE
  		if (we1_i)
  		begin
  			ram[addr1wr_i] <= data1wr_i;
  		end
  `endif
  
  `ifdef ISSUE_THREE_WIDE
  		if (we2_i)
  		begin
  			ram[addr2wr_i] <= data2wr_i;
  		end
  `endif
  
  `ifdef ISSUE_FOUR_WIDE
  		if (we3_i)
  		begin
  			ram[addr3wr_i] <= data3wr_i;
  		end
  `endif
  
  `ifdef ISSUE_FIVE_WIDE
  		if (we4_i)
  		begin
  			ram[addr4wr_i] <= data4wr_i;
  		end
  `endif
  
  `ifdef ISSUE_SIX_WIDE
  		if (we5_i)
  		begin
  			ram[addr5wr_i] <= data5wr_i;
  		end
  `endif
  
  `ifdef ISSUE_SEVEN_WIDE
  		if (we6_i)
  		begin
  			ram[addr6wr_i] <= data6wr_i;
  		end
  `endif
  
  `ifdef ISSUE_EIGHT_WIDE
  		if (we7_i)
  		begin
  			ram[addr7wr_i] <= data7wr_i;
  		end
  `endif
  	end
  end

`else //DYNAMIC_CONFIG

  wire [`ISSUE_WIDTH-1:0]              we;
  wire [`ISSUE_WIDTH-1:0][INDEX-1:0]   addrWr;
  wire [`ISSUE_WIDTH-1:0][WIDTH-1:0]   dataWr;

  wire                    [INDEX-1:0]     addr;
  wire                    [WIDTH-1:0]     rdData;

  wire [`ISSUE_WIDTH-1:0]              writePortGated;
  wire                                 readPortGated;
  wire [`NUM_PARTS_RF-1:0]             partitionGated; 

  assign writePortGated = ~issueLaneActive_i;
  assign readPortGated  = 1'b0;
  assign partitionGated   = ~alPartitionActive_i;


    assign we[0] = we0_i;
    assign addrWr[0] = addr0wr_i;
    assign dataWr[0] = data0wr_i;

  `ifdef ISSUE_TWO_WIDE
    assign we[1] = we1_i;
    assign addrWr[1] = addr1wr_i;
    assign dataWr[1] = data1wr_i;
  `endif
  
  `ifdef ISSUE_THREE_WIDE
    assign we[2] = we2_i;
    assign addrWr[2] = addr2wr_i;
    assign dataWr[2] = data2wr_i;
  `endif
  
  `ifdef ISSUE_FOUR_WIDE
    assign we[3] = we3_i;
    assign addrWr[3] = addr3wr_i;
    assign dataWr[3] = data3wr_i;
  `endif
  
  `ifdef ISSUE_FIVE_WIDE
    assign we[4] = we4_i;
    assign addrWr[4] = addr4wr_i;
    assign dataWr[4] = data4wr_i;
  `endif
  
  `ifdef ISSUE_SIX_WIDE
    assign we[5] = we5_i;
    assign addrWr[5] = addr5wr_i;
    assign dataWr[5] = data5wr_i;
  `endif
  
  `ifdef ISSUE_SEVEN_WIDE
    assign we[6] = we6_i;
    assign addrWr[6] = addr6wr_i;
    assign dataWr[6] = data6wr_i;
  `endif
  
  `ifdef ISSUE_EIGHT_WIDE
    assign we[7] = we7_i;
    assign addrWr[7] = addr7wr_i;
    assign dataWr[7] = data7wr_i;
  `endif



  /* Read operation */
  assign addr        = addr0_i;
  assign data0_o     = rdData;
  


  //TODO: Write the reset state machine


  RAM_CONFIGURABLE #(
  	/* Parameters */
  	.DEPTH(DEPTH),
  	.INDEX(INDEX),
  	.WIDTH(WIDTH),
    .NUM_WR_PORTS(`ISSUE_WIDTH),
    .NUM_RD_PORTS(1),
    .NUM_PARTS(`NUM_PARTS_RF),
    .NUM_PARTS_LOG(`NUM_PARTS_RF_LOG),
    .WR_PORTS_LOG(`ISSUE_WIDTH_LOG),
    .RESET_VAL(`RAM_RESET_ZERO),
    .SEQ_START(0),   // Reset the RMT rams to contain first LOG_REG sequential mappings
    .PARENT_MODULE("ALNPC") // Used for debug prints inside
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
    .ramReady_o(alNPcReady_o)
  );



`endif //DYNAMIC_CONFIG

//synopsys translate_on

endmodule

