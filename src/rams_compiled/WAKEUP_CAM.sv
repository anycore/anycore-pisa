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

module WAKEUP_CAM #(
	/* Parameters */
	parameter DEPTH       = 16,
	parameter INDEX       = 4,
	parameter WIDTH       = 8
	) (

	input      [WIDTH-1:0]                tag0_i,
	output reg [DEPTH-1:0]                vect0_o,
	
`ifdef ISSUE_TWO_WIDE
	input      [WIDTH-1:0]                tag1_i,
	output reg [DEPTH-1:0]                vect1_o,
`endif

`ifdef ISSUE_THREE_WIDE
	input      [WIDTH-1:0]                tag2_i,
	output reg [DEPTH-1:0]                vect2_o,
`endif

`ifdef ISSUE_FOUR_WIDE
	input      [WIDTH-1:0]                tag3_i,
	output reg [DEPTH-1:0]                vect3_o,
`endif

`ifdef ISSUE_FIVE_WIDE
	input      [WIDTH-1:0]                tag4_i,
	output reg [DEPTH-1:0]                vect4_o,
`endif

`ifdef ISSUE_SIX_WIDE
	input      [WIDTH-1:0]                tag5_i,
	output reg [DEPTH-1:0]                vect5_o,
`endif

`ifdef ISSUE_SEVEN_WIDE
	input      [WIDTH-1:0]                tag6_i,
	output reg [DEPTH-1:0]                vect6_o,
`endif

`ifdef ISSUE_EIGHT_WIDE
	input      [WIDTH-1:0]                tag7_i,
	output reg [DEPTH-1:0]                vect7_o,
`endif


	input      [INDEX-1:0]                wrAddr0_i,
	input      [WIDTH-1:0]                wrData0_i,
	input                                 we0_i,

`ifdef DISPATCH_TWO_WIDE
	input      [INDEX-1:0]                wrAddr1_i,
	input      [WIDTH-1:0]                wrData1_i,
	input                                 we1_i,
`endif

`ifdef DISPATCH_THREE_WIDE
	input      [INDEX-1:0]                wrAddr2_i,
	input      [WIDTH-1:0]                wrData2_i,
	input                                 we2_i,
`endif

`ifdef DISPATCH_FOUR_WIDE
	input      [INDEX-1:0]                wrAddr3_i,
	input      [WIDTH-1:0]                wrData3_i,
	input                                 we3_i,
`endif

`ifdef DISPATCH_FIVE_WIDE
	input      [INDEX-1:0]                wrAddr4_i,
	input      [WIDTH-1:0]                wrData4_i,
	input                                 we4_i,
`endif

`ifdef DISPATCH_SIX_WIDE
	input      [INDEX-1:0]                wrAddr5_i,
	input      [WIDTH-1:0]                wrData5_i,
	input                                 we5_i,
`endif

`ifdef DISPATCH_SEVEN_WIDE
	input      [INDEX-1:0]                wrAddr6_i,
	input      [WIDTH-1:0]                wrData6_i,
	input                                 we6_i,
`endif

`ifdef DISPATCH_EIGHT_WIDE
	input      [INDEX-1:0]                wrAddr7_i,
	input      [WIDTH-1:0]                wrData7_i,
	input                                 we7_i,
`endif

`ifdef DYNAMIC_CONFIG
  input [`DISPATCH_WIDTH-1:0]           dispatchLaneActive_i,
  input [`ISSUE_WIDTH-1:0]              issueLaneActive_i,
  input [`STRUCT_PARTS-1:0]             iqPartitionActive_i,
`endif  

	input                                 clk,
	input                                 reset
);


/* The RAM reg */
reg  [WIDTH-1:0]                   ram [DEPTH-1:0];

`ifndef DYNAMIC_CONFIG

  /* Read operation */
  always_comb
  begin
  	int i;
  
  	for (i = 0; i < DEPTH; i++)
  	begin
  		vect0_o[i]   = 1'h0;
  
  		if (ram[i] == tag0_i)
  		begin
  			vect0_o[i] = 1'h1;
  		end
  
  `ifdef ISSUE_TWO_WIDE
  		vect1_o[i]   = 1'h0;
  
  		if (ram[i] == tag1_i)
  		begin
  			vect1_o[i] = 1'h1;
  		end
  `endif
  
  `ifdef ISSUE_THREE_WIDE
  		vect2_o[i]   = 1'h0;
  
  		if (ram[i] == tag2_i)
  		begin
  			vect2_o[i] = 1'h1;
  		end
  `endif
  
  `ifdef ISSUE_FOUR_WIDE
  		vect3_o[i]   = 1'h0;
  
  		if (ram[i] == tag3_i)
  		begin
  			vect3_o[i] = 1'h1;
  		end
  `endif
  
  `ifdef ISSUE_FIVE_WIDE
  		vect4_o[i]   = 1'h0;
  
  		if (ram[i] == tag4_i)
  		begin
  			vect4_o[i] = 1'h1;
  		end
  `endif
  
  `ifdef ISSUE_SIX_WIDE
  		vect5_o[i]   = 1'h0;
  
  		if (ram[i] == tag5_i)
  		begin
  			vect5_o[i] = 1'h1;
  		end
  `endif
  
  `ifdef ISSUE_SEVEN_WIDE
  		vect6_o[i]   = 1'h0;
  
  		if (ram[i] == tag6_i)
  		begin
  			vect6_o[i] = 1'h1;
  		end
  `endif
  
  `ifdef ISSUE_EIGHT_WIDE
  		vect7_o[i]   = 1'h0;
  
  		if (ram[i] == tag7_i)
  		begin
  			vect7_o[i] = 1'h1;
  		end
  `endif
  	end
  end


  /* Write operation */
  always_ff @(posedge clk)
  begin
  	int i;
  
  	if (reset)
  	begin
  		for (i = 0; i < DEPTH; i++)
  		begin
  			ram[i]              <= 0;
  		end
  	end
  
  	else
  	begin
  		if (we0_i)
  		begin
  			ram[wrAddr0_i]      <= wrData0_i;
  		end
  
  `ifdef DISPATCH_TWO_WIDE
  		if (we1_i)
  		begin
  			ram[wrAddr1_i]      <= wrData1_i;
  		end
  `endif
  
  `ifdef DISPATCH_THREE_WIDE
  		if (we2_i)
  		begin
  			ram[wrAddr2_i]      <= wrData2_i;
  		end
  `endif
  
  `ifdef DISPATCH_FOUR_WIDE
  		if (we3_i)
  		begin
  			ram[wrAddr3_i]      <= wrData3_i;
  		end
  `endif
  
  `ifdef DISPATCH_FIVE_WIDE
  		if (we4_i)
  		begin
  			ram[wrAddr4_i]      <= wrData4_i;
  		end
  `endif
  
  `ifdef DISPATCH_SIX_WIDE
  		if (we5_i)
  		begin
  			ram[wrAddr5_i]      <= wrData5_i;
  		end
  `endif
  
  `ifdef DISPATCH_SEVEN_WIDE
  		if (we6_i)
  		begin
  			ram[wrAddr6_i]      <= wrData6_i;
  		end
  `endif
  
  `ifdef DISPATCH_EIGHT_WIDE
  		if (we7_i)
  		begin
  			ram[wrAddr7_i]      <= wrData7_i;
  		end
  `endif
  	end
  end

`else //DYNAMIC_CONFIG

// TODO: Need to optimize in order to reduce power consumption
  /* Read operation */
/*
  reg [DEPTH-1:0]  vect0;
  assign vect0_o = issueLaneActive_i[0] ? vect0 : {DEPTH{1'b0}};

`ifdef ISSUE_TWO_WIDE
  reg [DEPTH-1:0]  vect1;
  assign vect1_o = issueLaneActive_i[0] ? vect1 : {DEPTH{1'b0}};
`endif

`ifdef ISSUE_THREE_WIDE
  reg [DEPTH-1:0]  vect2;
  assign vect2_o = issueLaneActive_i[0] ? vect2 : {DEPTH{1'b0}};
`endif

`ifdef ISSUE_FOUR_WIDE
  reg [DEPTH-1:0]  vect3;
  assign vect3_o = issueLaneActive_i[0] ? vect3 : {DEPTH{1'b0}};
`endif

`ifdef ISSUE_FIVE_WIDE
  reg [DEPTH-1:0]  vect4;
  assign vect4_o = issueLaneActive_i[0] ? vect4 : {DEPTH{1'b0}};
`endif

`ifdef ISSUE_SIX_WIDE
  reg [DEPTH-1:0]  vect5;
  assign vect5_o = issueLaneActive_i[0] ? vect5 : {DEPTH{1'b0}};
`endif

`ifdef ISSUE_SEVEN_WIDE
  reg [DEPTH-1:0]  vect6;
  assign vect6_o = issueLaneActive_i[0] ? vect6 : {DEPTH{1'b0}};
`endif

`ifdef ISSUE_EIGHT_WIDE
  reg [DEPTH-1:0]  vect7;
  assign vect7_o = issueLaneActive_i[0] ? vect7 : {DEPTH{1'b0}};
`endif
*/
  wire [`DISPATCH_WIDTH-1:0]              we;
  wire [`DISPATCH_WIDTH-1:0][INDEX-1:0]   addrWr;
  wire [`DISPATCH_WIDTH-1:0][WIDTH-1:0]   dataWr;

  wire [`ISSUE_WIDTH-1:0][WIDTH-1:0]      tag;
  wire [`ISSUE_WIDTH-1:0][DEPTH-1:0]      vect;

  wire [`DISPATCH_WIDTH-1:0]              writePortGated;
  wire [`ISSUE_WIDTH-1:0]                 readPortGated;
  wire [`STRUCT_PARTS-1:0]                partitionGated; 

  assign writePortGated   = ~dispatchLaneActive_i;
  assign readPortGated    = ~issueLaneActive_i;
  assign partitionGated   = ~iqPartitionActive_i;


    assign we[0] = we0_i;
    assign addrWr[0] = wrAddr0_i;
    assign dataWr[0] = wrData0_i;

  `ifdef DISPATCH_TWO_WIDE
    assign we[1] = we1_i;
    assign addrWr[1] = wrAddr1_i;
    assign dataWr[1] = wrData1_i;
  `endif
  
  `ifdef DISPATCH_THREE_WIDE
    assign we[2] = we2_i;
    assign addrWr[2] = wrAddr2_i;
    assign dataWr[2] = wrData2_i;
  `endif
  
  `ifdef DISPATCH_FOUR_WIDE
    assign we[3] = we3_i;
    assign addrWr[3] = wrAddr3_i;
    assign dataWr[3] = wrData3_i;
  `endif
  
  `ifdef DISPATCH_FIVE_WIDE
    assign we[4] = we4_i;
    assign addrWr[4] = wrAddr4_i;
    assign dataWr[4] = wrData4_i;
  `endif
  
  `ifdef DISPATCH_SIX_WIDE
    assign we[5] = we5_i;
    assign addrWr[5] = wrAddr5_i;
    assign dataWr[5] = wrData5_i;
  `endif
  
  `ifdef DISPATCH_SEVEN_WIDE
    assign we[6] = we6_i;
    assign addrWr[6] = wrAddr6_i;
    assign dataWr[6] = wrData6_i;
  `endif
  
  `ifdef DISPATCH_EIGHT_WIDE
    assign we[7] = we7_i;
    assign addrWr[7] = wrAddr7_i;
    assign dataWr[7] = wrData7_i;
  `endif



  /* Read operation */
    assign tag[0]       = tag0_i;
    assign vect0_o      = vect[0];
  
  `ifdef ISSUE_TWO_WIDE
    assign tag[1]       = tag1_i;
    assign vect1_o      = vect[1];
  `endif

  `ifdef ISSUE_THREE_WIDE
    assign tag[2]       = tag2_i;
    assign vect2_o      = vect[2];
  `endif

  `ifdef ISSUE_FOUR_WIDE
    assign tag[3]       = tag3_i;
    assign vect3_o      = vect[3];
  `endif

  `ifdef ISSUE_FIVE_WIDE
    assign tag[4]       = tag4_i;
    assign vect4_o      = vect[4];
  `endif

  `ifdef ISSUE_SIX_WIDE
    assign tag[5]       = tag5_i;
    assign vect5_o      = vect[5];
  `endif

  `ifdef ISSUE_SEVEN_WIDE
    assign tag[6]       = tag6_i;
    assign vect6_o      = vect[6];
  `endif

  `ifdef ISSUE_EIGHT_WIDE
    assign tag[7]       = tag7_i;
    assign vect7_o      = vect[7];
  `endif



  //TODO: Write the reset state machine


  CAM_PARTITIONED #(
  	/* Parameters */
  	.DEPTH(DEPTH),
  	.INDEX(INDEX),
  	.WIDTH(WIDTH),
    .NUM_WR_PORTS(`DISPATCH_WIDTH),
    .NUM_RD_PORTS(`ISSUE_WIDTH),
    .WR_PORTS_LOG(`DISPATCH_WIDTH_LOG),
    .NUM_PARTS(`STRUCT_PARTS),
    .NUM_PARTS_LOG(`STRUCT_PARTS_LOG),
    .RESET_VAL(`RAM_RESET_ZERO),
    .SEQ_START(0),   // Reset the RMT rams to contain first LOG_REG sequential mappings
    .PARENT_MODULE("WAKEUP") // Used for debug prints inside
  ) cam_partitioned
  (
  
    .writePortGated_i(writePortGated),
    .readPortGated_i(readPortGated),
    .partitionGated_i(partitionGated),
  
  	.tag_i(tag),
  	.vect_o(vect),
  
  	.addrWr_i(addrWr),
  	.dataWr_i(dataWr),
  
  	.wrEn_i(we),
  
  	.clk(clk),
  	.reset(reset),
    .ramReady_o(iqCamReady_o)
  );



`endif //DYNAMIC_CONFIG

endmodule


