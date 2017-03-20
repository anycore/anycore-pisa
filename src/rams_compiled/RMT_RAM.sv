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

module RMT_RAM #(
	/* Parameters */
	parameter DEPTH = 16,
	parameter INDEX = 4,
	parameter WIDTH = 8,
	parameter N_PACKETS  = 8
) (

`ifdef DYNAMIC_CONFIG  
  input  [`DISPATCH_WIDTH-1:0]  dispatchLaneActive_i,
  // In case of dynamic configuration, this ensures that all operations
  // are stalled until this signal is goes hight. This should be pulld
  // low during a reset operation or after reconfiguring width. In case
  // of width reconfiguration, the content of the power gated RAMS need
  // to be restored by reading out from the non-power gated port and
  // writing to them.
  output                   rmtReady_o, 
`endif

	input                    repairFlag_i,
	input  [INDEX-1:0]       repairAddr_i [0:N_PACKETS-1],
	input  [WIDTH-1:0]       repairData_i [0:N_PACKETS-1],

	input  [INDEX-1:0]       addr0_i,
	output [WIDTH-1:0]       data0_o,
	                         
	input  [INDEX-1:0]       addr1_i,
	output [WIDTH-1:0]       data1_o,
	                         
`ifdef DISPATCH_TWO_WIDE   
	input  [INDEX-1:0]       addr2_i,
	output [WIDTH-1:0]       data2_o,
	                         
	input  [INDEX-1:0]       addr3_i,
	output [WIDTH-1:0]       data3_o,
`endif                     
	                         
`ifdef DISPATCH_THREE_WIDE   
	input  [INDEX-1:0]       addr4_i,
	output [WIDTH-1:0]       data4_o,
	                         
	input  [INDEX-1:0]       addr5_i,
	output [WIDTH-1:0]       data5_o,
`endif                     
	                         
`ifdef DISPATCH_FOUR_WIDE   
	input  [INDEX-1:0]       addr6_i,
	output [WIDTH-1:0]       data6_o,
	                         
	input  [INDEX-1:0]       addr7_i,
	output [WIDTH-1:0]       data7_o,
`endif                     
	                         
`ifdef DISPATCH_FIVE_WIDE   
	input  [INDEX-1:0]       addr8_i,
	output [WIDTH-1:0]       data8_o,
	                         
	input  [INDEX-1:0]       addr9_i,
	output [WIDTH-1:0]       data9_o,
`endif                     
	                         
`ifdef DISPATCH_SIX_WIDE   
	input  [INDEX-1:0]       addr10_i,
	output [WIDTH-1:0]       data10_o,
	                         
	input  [INDEX-1:0]       addr11_i,
	output [WIDTH-1:0]       data11_o,
`endif                     
	                         
`ifdef DISPATCH_SEVEN_WIDE   
	input  [INDEX-1:0]       addr12_i,
	output [WIDTH-1:0]       data12_o,
	                         
	input  [INDEX-1:0]       addr13_i,
	output [WIDTH-1:0]       data13_o,
`endif                     
	                         
`ifdef DISPATCH_EIGHT_WIDE   
	input  [INDEX-1:0]       addr14_i,
	output [WIDTH-1:0]       data14_o,
	                         
	input  [INDEX-1:0]       addr15_i,
	output [WIDTH-1:0]       data15_o,
`endif                     
                           
                           
	input  [INDEX-1:0]       addr0wr_i,
	input  [WIDTH-1:0]       data0wr_i,
	input                    we0_i,
                           
`ifdef DISPATCH_TWO_WIDE   
	input  [INDEX-1:0]       addr1wr_i,
	input  [WIDTH-1:0]       data1wr_i,
	input                    we1_i,
`endif
                           
`ifdef DISPATCH_THREE_WIDE   
	input  [INDEX-1:0]       addr2wr_i,
	input  [WIDTH-1:0]       data2wr_i,
	input                    we2_i,
`endif
                           
`ifdef DISPATCH_FOUR_WIDE   
	input  [INDEX-1:0]       addr3wr_i,
	input  [WIDTH-1:0]       data3wr_i,
	input                    we3_i,
`endif
                           
`ifdef DISPATCH_FIVE_WIDE   
	input  [INDEX-1:0]       addr4wr_i,
	input  [WIDTH-1:0]       data4wr_i,
	input                    we4_i,
`endif
                           
`ifdef DISPATCH_SIX_WIDE   
	input  [INDEX-1:0]       addr5wr_i,
	input  [WIDTH-1:0]       data5wr_i,
	input                    we5_i,
`endif
                           
`ifdef DISPATCH_SEVEN_WIDE   
	input  [INDEX-1:0]       addr6wr_i,
	input  [WIDTH-1:0]       data6wr_i,
	input                    we6_i,
`endif
                           
`ifdef DISPATCH_EIGHT_WIDE   
	input  [INDEX-1:0]       addr7wr_i,
	input  [WIDTH-1:0]       data7wr_i,
	input                    we7_i,
`endif

	input                    clk,
	input                    reset

);

//synopsys translate_off

//`ifndef DYNAMIC_CONFIG

`ifdef DYNAMIC_CONFIG
  assign                   rmtReady_o = 1'b1;
`endif

  /* The ram reg */
  reg  [WIDTH-1:0]           ram [DEPTH-1:0];
  
  /* Read operation */
  assign data0_o     = ram[addr0_i];
  assign data1_o     = ram[addr1_i];
  
  `ifdef DISPATCH_TWO_WIDE
  assign data2_o     = ram[addr2_i];
  assign data3_o     = ram[addr3_i];
  `endif
  
  `ifdef DISPATCH_THREE_WIDE
  assign data4_o     = ram[addr4_i];
  assign data5_o     = ram[addr5_i];
  `endif
  
  `ifdef DISPATCH_FOUR_WIDE
  assign data6_o     = ram[addr6_i];
  assign data7_o     = ram[addr7_i];
  `endif
  
  `ifdef DISPATCH_FIVE_WIDE
  assign data8_o     = ram[addr8_i];
  assign data9_o     = ram[addr9_i];
  `endif
  
  `ifdef DISPATCH_SIX_WIDE
  assign data10_o    = ram[addr10_i];
  assign data11_o    = ram[addr11_i];
  `endif
  
  `ifdef DISPATCH_SEVEN_WIDE
  assign data12_o    = ram[addr12_i];
  assign data13_o    = ram[addr13_i];
  `endif
  
  `ifdef DISPATCH_EIGHT_WIDE
  assign data14_o    = ram[addr14_i];
  assign data15_o    = ram[addr15_i];
  `endif


  /* Write operation */
  always_ff @(posedge clk)
  begin
  	int i;
  
  	if (reset)
  	begin
  		for (i = 0; i < DEPTH; i++)
  		begin
  			ram[i] <= i;
  		end
  	end
  
  	else if (repairFlag_i)
  	begin
  		for (i = 0; i < N_PACKETS; i++)
  		begin
  			ram[repairAddr_i[i]] <= repairData_i[i];
  		end
  	end
  
  	else
  	begin
  		if (we0_i)
  		begin
  			ram[addr0wr_i] <= data0wr_i;
  		end
  
  `ifdef DISPATCH_TWO_WIDE
  		if (we1_i)
  		begin
  			ram[addr1wr_i] <= data1wr_i;
  		end
  `endif
  
  `ifdef DISPATCH_THREE_WIDE
  		if (we2_i)
  		begin
  			ram[addr2wr_i] <= data2wr_i;
  		end
  `endif
  
  `ifdef DISPATCH_FOUR_WIDE
  		if (we3_i)
  		begin
  			ram[addr3wr_i] <= data3wr_i;
  		end
  `endif
  
  `ifdef DISPATCH_FIVE_WIDE
  		if (we4_i)
  		begin
  			ram[addr4wr_i] <= data4wr_i;
  		end
  `endif
  
  `ifdef DISPATCH_SIX_WIDE
  		if (we5_i)
  		begin
  			ram[addr5wr_i] <= data5wr_i;
  		end
  `endif
  
  `ifdef DISPATCH_SEVEN_WIDE
  		if (we6_i)
  		begin
  			ram[addr6wr_i] <= data6wr_i;
  		end
  `endif
  
  `ifdef DISPATCH_EIGHT_WIDE
  		if (we7_i)
  		begin
  			ram[addr7wr_i] <= data7wr_i;
  		end
  `endif
  
  	end
  end

//`else // DYNAMIC_CONFIG
//
//  // Number of write ports should be mzximum of the two widths
//  localparam NUM_WR_PORTS = (`N_REPAIR_PACKETS > `DISPATCH_WIDTH) ? `N_REPAIR_PACKETS : `DISPATCH_WIDTH;
//
//  wire [`DISPATCH_WIDTH-1:0]              we;
//  wire [`DISPATCH_WIDTH-1:0][INDEX-1:0]   addrWr;
//  wire [`DISPATCH_WIDTH-1:0][WIDTH-1:0]   dataWr;
//
//  reg  [NUM_WR_PORTS-1:0]                 we_ram;
//  reg  [NUM_WR_PORTS-1:0][INDEX-1:0]      addrWr_ram;
//  reg  [NUM_WR_PORTS-1:0][WIDTH-1:0]      dataWr_ram;
//
//  wire [2*`DISPATCH_WIDTH-1:0][INDEX-1:0] addr;
//  wire [2*`DISPATCH_WIDTH-1:0][WIDTH-1:0] rdData;
//
//  reg  [NUM_WR_PORTS-1:0]                 writePortGated;
//  reg  [(2*`DISPATCH_WIDTH)-1:0]          readPortGated;
//  wire [`STRUCT_PARTS-1:0]                partitionGated;
//
//  // RMT is not partitioned
//  assign partitionGated = {`STRUCT_PARTS{1'b0}};
//
//
//    assign we[0] = we0_i;
//    assign addrWr[0] = addr0wr_i;
//    assign dataWr[0] = data0wr_i;
//    assign addr[0]  = addr0_i;
//    assign addr[1]  = addr1_i;
//
//  `ifdef DISPATCH_TWO_WIDE
//    assign we[1] = we1_i;
//    assign addrWr[1] = addr1wr_i;
//    assign dataWr[1] = data1wr_i;
//    assign addr[2]  = addr2_i;
//    assign addr[3]  = addr3_i;
//  `endif
//  
//  `ifdef DISPATCH_THREE_WIDE
//    assign we[2] = we2_i;
//    assign addrWr[2] = addr2wr_i;
//    assign dataWr[2] = data2wr_i;
//    assign addr[4]  = addr4_i;
//    assign addr[5]  = addr5_i;
//  `endif
//  
//  `ifdef DISPATCH_FOUR_WIDE
//    assign we[3] = we3_i;
//    assign addrWr[3] = addr3wr_i;
//    assign dataWr[3] = data3wr_i;
//    assign addr[6]  = addr6_i;
//    assign addr[7]  = addr7_i;
//  `endif
//  
//  `ifdef DISPATCH_FIVE_WIDE
//    assign we[4] = we4_i;
//    assign addrWr[4] = addr4wr_i;
//    assign dataWr[4] = data4wr_i;
//    assign addr[8]  = addr8_i;
//    assign addr[9]  = addr9_i;
//  `endif
//  
//  `ifdef DISPATCH_SIX_WIDE
//    assign we[5] = we5_i;
//    assign addrWr[5] = addr5wr_i;
//    assign dataWr[5] = data5wr_i;
//    assign addr[10]  = addr10_i;
//    assign addr[11]  = addr11_i;
//  `endif
//  
//  `ifdef DISPATCH_SEVEN_WIDE
//    assign we[6] = we6_i;
//    assign addrWr[6] = addr6wr_i;
//    assign dataWr[6] = data6wr_i;
//    assign addr[12]  = addr12_i;
//    assign addr[13]  = addr13_i;
//  `endif
//  
//  `ifdef DISPATCH_EIGHT_WIDE
//    assign we[7] = we7_i;
//    assign addrWr[7] = addr7wr_i;
//    assign dataWr[7] = data7wr_i;
//    assign addr[14]  = addr14_i;
//    assign addr[15]  = addr15_i;
//  `endif
//
//
//  //TODO: Write the reset state machine
//
//
//  // This does not use the partitioned RAM as
//  // the entire RAM is always active
//  RAM_CONFIGURABLE #(
//  	/* Parameters */
//  	.DEPTH(DEPTH),
//  	.INDEX(INDEX),
//  	.WIDTH(WIDTH),
//    .NUM_WR_PORTS(NUM_WR_PORTS),
//    .NUM_RD_PORTS(2*`DISPATCH_WIDTH),
//    .WR_PORTS_LOG(`DISPATCH_WIDTH_LOG),
//    .RESET_VAL(`RAM_RESET_SEQ),
//    .SEQ_START(0),   // Reset the RMT rams to contain first LOG_REG sequential mappings
//    .USE_PARTITIONED(0),
//    .USE_FLIP_FLOP(1),
//    .PARENT_MODULE("RMT")
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
//  	.addrWr_i(addrWr_ram),
//  	.dataWr_i(dataWr_ram),
//  
//  	.wrEn_i(we_ram),
//  
//  	.clk(clk),
//  	.reset(reset),
//    .ramReady_o(rmtReady_o)
//  );
//
//
//  /* Write operation */
//  always_comb
//  begin
//  	int i;
//  
//    // TODO: Currently ignores powergating wake up
//    // This might need to be changed depending upon the 
//    // repair policy. Whether write ports should be
//    // woken up or whether use only the existing write ports
//    // to write.
//    // NOTE: Writing to all ports should be OK as the read port
//    // rams that are power gated will not write anything anyways.
//    // Whereas the RAMs for the active read ports will write data
//    // and update ram_select correctly since these RAMs are not 
//    // powergated when the write ports were gated. Essentially,
//    // power gating a RAM depends only on whether a read port 
//    // is gated or not.
//  	if (repairFlag_i)
//  	begin
//      writePortGated = {NUM_WR_PORTS{1'b0}}; //Enable all ports
//      readPortGated  = {2*`DISPATCH_WIDTH{1'b0}};
//      we_ram = {NUM_WR_PORTS{1'b0}};
//  		for (i = 0; i < N_PACKETS; i++)
//  		begin
//        addrWr_ram[i]  = repairAddr_i[i];
//        dataWr_ram[i]  = repairData_i[i];
//        // Write only if register number is than the total number of
//        // architected registers
//        we_ram[i]   = (repairAddr_i[i] < `N_ARCH_REGS);
//  		end
//  	end
//    else
//    begin
//      for(i = 0; i < `DISPATCH_WIDTH; i++)
//        readPortGated[2*i +:2]   = {2{~dispatchLaneActive_i[i]}};
//
//
//      // Since num of wr ports canbe more than dispatch width, make sure no stray wrEn
//      for(i=0;i<NUM_WR_PORTS;i++)
//        if(i<`DISPATCH_WIDTH)
//        begin
//          writePortGated[i] = ~dispatchLaneActive_i[i];
//          addrWr_ram[i]     = addrWr[i];
//          dataWr_ram[i]     = dataWr[i];
//          we_ram[i]         = we[i];
//        end
//        else
//        begin
//          writePortGated[i] = 1'b1;
//          addrWr_ram[i]     = {INDEX{1'b0}};
//          dataWr_ram[i]     = {WIDTH{1'b0}};
//          we_ram[i]         = 1'b0;
//        end
//
//    end
//  end
//
//  /* Read operation */
//  assign data0_o     = rdData[0];
//  assign data1_o     = rdData[1];
//  
//  `ifdef DISPATCH_TWO_WIDE
//  assign data2_o     = rdData[2];
//  assign data3_o     = rdData[3];
//  `endif
//  
//  `ifdef DISPATCH_THREE_WIDE
//  assign data4_o     = rdData[4];
//  assign data5_o     = rdData[5];
//  `endif
//  
//  `ifdef DISPATCH_FOUR_WIDE
//  assign data6_o     = rdData[6];
//  assign data7_o     = rdData[7];
//  `endif
//  
//  `ifdef DISPATCH_FIVE_WIDE
//  assign data8_o     = rdData[8];
//  assign data9_o     = rdData[9];
//  `endif
//  
//  `ifdef DISPATCH_SIX_WIDE
//  assign data10_o     = rdData[10];
//  assign data11_o     = rdData[11];
//  `endif
//  
//  `ifdef DISPATCH_SEVEN_WIDE
//  assign data12_o     = rdData[12];
//  assign data13_o     = rdData[13];
//  `endif
//  
//  `ifdef DISPATCH_EIGHT_WIDE
//  assign data14_o     = rdData[14];
//  assign data15_o     = rdData[15];
//  `endif
//
// 
//
//`endif //DYNAMEIC_CONFIG

//synopsys translate_on

endmodule


