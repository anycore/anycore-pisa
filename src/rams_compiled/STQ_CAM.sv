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

module STQ_CAM #(
	/* Parameters */
	parameter DEPTH       = 16,
	parameter INDEX       = 4,
	parameter WIDTH       = 8,
  parameter FUNCTION    = 0  // 0 = EQUAL_TO,  1 = GREATER_THAN
	) (

	input      [WIDTH-1:0]                tag0_i,
	output reg [DEPTH-1:0]                vect0_o,
	
	input      [INDEX-1:0]                addr0_i,
	output reg [WIDTH-1:0]                data0_o,

	input      [INDEX-1:0]                wrAddr0_i,
	input      [WIDTH-1:0]                wrData0_i,
	input                                 we0_i,

	input      [INDEX-1:0]                wrAddr1_i,
	input      [WIDTH-1:0]                wrData1_i,
	input                                 we1_i,

`ifdef DYNAMIC_CONFIG
  input [`STRUCT_PARTS_LSQ-1:0]         lsqPartitionActive_i,
`endif  

	input                                 clk,
	input                                 reset
);



`ifndef DYNAMIC_CONFIG

  /* The RAM reg */
  reg  [WIDTH-1:0]                   ram [DEPTH-1:0];

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
    end

    data0_o = ram[addr0_i];
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
  
  		if (we1_i)
  		begin
  			ram[wrAddr1_i]      <= wrData1_i;
  		end
    end
  end
 
`else //DYNAMIC_CONFIG

// TODO: Need to optimize in order to reduce power consumption
  /* Read operation */
/*
  reg [DEPTH-1:0]  vect0;
  assign vect0_o = issueLaneActive_i[0] ? vect0 : {DEPTH{1'b0}};
*/

  wire [1:0]              we;
  wire [1:0][INDEX-1:0]   addrWr;
  wire [1:0][WIDTH-1:0]   dataWr;

  wire [0:0][WIDTH-1:0]   tag;
  wire [0:0][DEPTH-1:0]   vect;

  wire [0:0][INDEX-1:0]   addr;
  wire [0:0][WIDTH-1:0]   data;

  wire [1:0]                writePortGated;
  wire                      readPortGated;
  wire [`STRUCT_PARTS_LSQ-1:0]  partitionGated; 

  assign writePortGated   = 2'b00;
  assign readPortGated    = 1'b0;
  assign partitionGated   = ~lsqPartitionActive_i;

    assign addr[0] = addr0_i;
    assign data0_o = data[0];

    assign we[0] = we0_i;
    assign addrWr[0] = wrAddr0_i;
    assign dataWr[0] = wrData0_i;

    assign we[1] = we1_i;
    assign addrWr[1] = wrAddr1_i;
    assign dataWr[1] = wrData1_i;
  

  /* Read operation */
    assign tag[0]       = tag0_i;
    assign vect0_o      = vect[0];
  

  //TODO: Write the reset state machine


  CAM_RAM_PARTITIONED #(
  	/* Parameters */
  	.DEPTH(DEPTH),
  	.INDEX(INDEX),
  	.WIDTH(WIDTH),
    .FUNCTION(FUNCTION),
    .NUM_WR_PORTS(2),
    .NUM_CAM_RD_PORTS(1),
    .NUM_RAM_RD_PORTS(1),
    .WR_PORTS_LOG(1),
    .NUM_PARTS(`STRUCT_PARTS_LSQ),
    .NUM_PARTS_LOG(`STRUCT_PARTS_LSQ_LOG),
    .RESET_VAL(`RAM_RESET_ZERO),
    .SEQ_START(0),   // Reset the RMT rams to contain first LOG_REG sequential mappings
    .PARENT_MODULE("LDX_PATH") // Used for debug prints inside
  ) cam_partitioned
  (
  
    .writePortGated_i(writePortGated),
    .readPortGated_i(readPortGated),
    .partitionGated_i(partitionGated),
  
  	.tag_i(tag),
  	.vect_o(vect),
  
  	.addr_i(addr),
  	.data_o(data),

  	.addrWr_i(addrWr),
  	.dataWr_i(dataWr),
  
  	.wrEn_i(we),
  
  	.clk(clk),
  	.reset(reset),
    .ramReady_o(addr1CamReady_o)
  );



`endif //DYNAMIC_CONFIG

endmodule


