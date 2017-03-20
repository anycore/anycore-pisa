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

module AMT_RAM #(

/* Parameters */
	parameter DEPTH = 16,
	parameter INDEX = 4,
	parameter WIDTH = 8,
	parameter N_PACKETS  = 8
	) (

	input      [INDEX-1:0]       repairAddr_i [0:N_PACKETS-1],
	output reg [WIDTH-1:0]       repairData_o [0:N_PACKETS-1],

`ifdef DYNAMIC_CONFIG  
  // Used to MUX read ports between normal and repair packet reads
  input                        repairFlag_i,
`endif 

	input      [INDEX-1:0]       addr0_i,
	output     [WIDTH-1:0]       data0_o,
                               
`ifdef COMMIT_TWO_WIDE
	input      [INDEX-1:0]       addr1_i,
	output     [WIDTH-1:0]       data1_o,
`endif
                               
`ifdef COMMIT_THREE_WIDE
	input      [INDEX-1:0]       addr2_i,
	output     [WIDTH-1:0]       data2_o,
`endif  
                               
`ifdef COMMIT_FOUR_WIDE
	input      [INDEX-1:0]       addr3_i,
	output     [WIDTH-1:0]       data3_o,
`endif
                               
	input      [INDEX-1:0]       addr0wr_i,
	input      [WIDTH-1:0]       data0wr_i,
	input                        we0_i,

`ifdef COMMIT_TWO_WIDE
	input      [INDEX-1:0]       addr1wr_i,
	input      [WIDTH-1:0]       data1wr_i,
	input                        we1_i,
`endif

`ifdef COMMIT_THREE_WIDE
	input      [INDEX-1:0]       addr2wr_i,
	input      [WIDTH-1:0]       data2wr_i,
	input                        we2_i,
`endif  

`ifdef COMMIT_FOUR_WIDE
	input      [INDEX-1:0]       addr3wr_i,
	input      [WIDTH-1:0]       data3wr_i,
	input                        we3_i,
`endif

`ifdef DYNAMIC_CONFIG
  input [`COMMIT_WIDTH-1:0]    commitLaneActive_i,
  output                       amtReady_o,
`endif

`ifdef AMT_DEBUG_PORT
	input  [`SIZE_RMT_LOG-1:0]     debugAMTAddr_i,
	output [`SIZE_PHYSICAL_LOG-1:0]debugAMTRdData_o,
`endif

	input                        clk,
	input                        reset
);

//synopsys translate_off

`ifndef DYNAMIC_CONFIG
  reg  [WIDTH-1:0]               ram [DEPTH-1:0];
  
  
  /* Read operation */
  assign data0_o               = ram[addr0_i];
  `ifdef COMMIT_TWO_WIDE
  assign data1_o               = ram[addr1_i];
  `endif
  `ifdef COMMIT_THREE_WIDE
  assign data2_o               = ram[addr2_i];
  `endif
  `ifdef COMMIT_FOUR_WIDE
  assign data3_o               = ram[addr3_i];
  `endif
  
  always_comb
  begin
  	int i;
  	for (i = 0; i < N_PACKETS; i++)
  	begin
  		repairData_o[i] = ram[repairAddr_i[i]];
  	end
  end
  
  
  /* Write operation */
  always @(posedge clk)
  begin
  	int i;
  
  	if (reset)
  	begin
  		for (i = 0; i < DEPTH; i++)
  		begin
  			ram[i] <= i;
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

  // Number of read ports is equal to the bigger among the two 
  localparam NUM_READ_PORTS = (N_PACKETS > `COMMIT_WIDTH) ? N_PACKETS : `COMMIT_WIDTH;

  wire [`COMMIT_WIDTH-1:0]              we;
  wire [`COMMIT_WIDTH-1:0][INDEX-1:0]   addrWr;
  wire [`COMMIT_WIDTH-1:0][WIDTH-1:0]   dataWr;

  `ifdef AMT_DEBUG_PORT
    // One extra read port for debug
    reg  [NUM_READ_PORTS:0][INDEX-1:0]    addr_ram;
    wire [NUM_READ_PORTS:0][WIDTH-1:0]    rdData;
  `else 
    reg  [NUM_READ_PORTS-1:0][INDEX-1:0]  addr_ram;
    wire [NUM_READ_PORTS-1:0][WIDTH-1:0]  rdData;
  `endif // AMT_DEBUG_PORT

  wire [`COMMIT_WIDTH-1:0][INDEX-1:0]   addr;

  wire [`COMMIT_WIDTH-1:0]              writePortGated;
  reg  [NUM_READ_PORTS-1:0]             readPortGated;
  wire [`STRUCT_PARTS-1:0]              partitionGated;

  assign writePortGated = ~commitLaneActive_i;
  assign partitionGated = {`STRUCT_PARTS{1'b0}};


    assign we[0] = we0_i;
    assign addrWr[0] = addr0wr_i;
    assign dataWr[0] = data0wr_i;
    assign addr[0]  = addr0_i;

  `ifdef COMMIT_TWO_WIDE
    assign we[1] = we1_i;
    assign addrWr[1] = addr1wr_i;
    assign dataWr[1] = data1wr_i;
    assign addr[1]  = addr1_i;
  `endif
  
  `ifdef COMMIT_THREE_WIDE
    assign we[2] = we2_i;
    assign addrWr[2] = addr2wr_i;
    assign dataWr[2] = data2wr_i;
    assign addr[2]  = addr2_i;
  `endif
  
  `ifdef COMMIT_FOUR_WIDE
    assign we[3] = we3_i;
    assign addrWr[3] = addr3wr_i;
    assign dataWr[3] = data3wr_i;
    assign addr[3]  = addr3_i;
  `endif
  

  //TODO: Write the reset state machine


  RAM_CONFIGURABLE #(
  	/* Parameters */
  	.DEPTH(DEPTH),
  	.INDEX(INDEX),
  	.WIDTH(WIDTH),
    .NUM_WR_PORTS(`COMMIT_WIDTH),

  `ifdef AMT_DEBUG_PORT
    .NUM_RD_PORTS(NUM_READ_PORTS+1),
  `else
    .NUM_RD_PORTS(NUM_READ_PORTS),
  `endif //AMT_DEBUG_PORT

    .WR_PORTS_LOG(`COMMIT_WIDTH_LOG),
    .RESET_VAL(`RAM_RESET_SEQ),
    .SEQ_START(0),   // Reset the RMT rams to contain first LOG_REG sequential mappings
    .USE_PARTITIONED(0),
    .USE_FLIP_FLOP(1),
    .PARENT_MODULE("AMT")
  ) ram_configurable
  (
  
    .writePortGated_i(writePortGated),
  `ifdef AMT_DEBUG_PORT
    .readPortGated_i({1'b0,readPortGated}),
  `else
    .readPortGated_i(readPortGated),
  `endif //AMT_DEBUG_PORT
    .partitionGated_i(partitionGated),
  
  	.addr_i(addr_ram),
  	.data_o(rdData),
  
  	.addrWr_i(addrWr),
  	.dataWr_i(dataWr),
  
  	.wrEn_i(we),
  
  	.clk(clk),
  	.reset(reset),
    .ramReady_o(amtReady_o)
  );


  /* Write operation */
  always_comb
  begin
  	int i;
  
    // TODO: Currently ignores powergating wake up
    // This might need to be changed depending upon the 
    // repair policy. Whether read ports should be
    // woken up or whether use only the existing read ports
    // to read the repair data.
    // TODO: Waking up read ports will involve additional
    // complexity as the woken RAMs will not have any content 
    // in them. Just using the active read ports will also be 
    // complex necessiating complex priority logic.. Need to 
    // decide between the complexities of waking up(multi cycle)
    // using active ports.
  	if (repairFlag_i)
  	begin
      readPortGated  = {NUM_READ_PORTS{1'b0}};
  		for (i = 0; i < NUM_READ_PORTS; i++)
        addr_ram[i]  = repairAddr_i[i];
  	end
    else
    begin
      readPortGated  = {{(NUM_READ_PORTS-`COMMIT_WIDTH){1'b1}},~commitLaneActive_i};
  		for (i = 0; i < NUM_READ_PORTS; i++)
        addr_ram[i]  = 0;

  		for (i = 0; i < `COMMIT_WIDTH; i++)
        addr_ram[i]  = addr[i];
    end

  `ifdef AMT_DEBUG_PORT
    addr_ram[NUM_READ_PORTS]  = debugAMTAddr_i;
  `endif //AMT_DEBUG_PORT
  end

  /* Read operation */

  // Normal read ports
  assign data0_o     = rdData[0];
  `ifdef COMMIT_TWO_WIDE
  assign data1_o     = rdData[1];
  `endif
  `ifdef COMMIT_THREE_WIDE
  assign data2_o     = rdData[2];
  `endif
  `ifdef COMMIT_FOUR_WIDE
  assign data3_o     = rdData[3];
  `endif

`ifdef AMT_DEBUG_PORT
  assign debugAMTRdData_o = rdData[NUM_READ_PORTS];
`endif //AMT_DEBUG_PORT

  // Repair Packets
  always_comb
  begin
  	int i;
  	for (i = 0; i < N_PACKETS; i++)
  	begin
  		repairData_o[i] = rdData[i];
  	end
  end
 
`endif //DYNAMIC_CONFIG

//synopsys translate_on

endmodule


