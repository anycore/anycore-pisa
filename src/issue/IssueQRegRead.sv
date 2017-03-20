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

module IssueQRegRead(

	input                                 clk,
	input                                 reset,
`ifdef DYNAMIC_CONFIG
  input [`ISSUE_WIDTH-1:0]              laneActive_i, 
	output reg [`ISSUE_WIDTH-1:0]        valid_bundle_o,
`endif

	input                                 flush_i,

	/* Payload and Destination of incoming instructions */
	input  payloadPkt                    rrPacket_i [0:`ISSUE_WIDTH-1],
	output payloadPkt                    rrPacket_o [0:`ISSUE_WIDTH-1]
	);

  // LANE: Per Lane Logic
`ifdef DYNAMIC_CONFIG_AND_WIDTH
  genvar i;
  generate
    for(i = 0; i < `ISSUE_WIDTH; i++)
    begin:PIPEREG

      PipeLineReg 
      #(.WIDTH(`PAYLOAD_PKT_SIZE),.CLKGATE(`PIPEREG_CLK_GATE)) iqRRReg
      (
        .clk(clk),
        .reset(reset | flush_i),
        .stall_i(1'b0),
        .clkEn_i(laneActive_i[i]),
        .pwrEn_i(laneActive_i[i]),
        .data_i(rrPacket_i[i]),
        .data_o(rrPacket_o[i])
      );
    
    // TODO: Emulate isolation cell for valid bit

    end
  endgenerate
`else        
  always_ff @(posedge clk)
  begin
  	int i;
  
  	if (reset || flush_i)
  	begin
  		for (i = 0; i < `ISSUE_WIDTH; i++)
  		begin
  			rrPacket_o[i]      <= 0;
  		end
  	end
  
  	else
  	begin
  		for (i = 0; i < `ISSUE_WIDTH; i++)
  		begin
  			if (rrPacket_i[i].valid)
  			begin
  				rrPacket_o[i]      <= rrPacket_i[i];
  			end
  
  			rrPacket_o[i].valid  <= rrPacket_i[i].valid;
  		end
  	end
  end
`endif

`ifdef DYNAMIC_CONFIG
 always_comb 
 begin
  int i;
  for (i = 0; i < `ISSUE_WIDTH; i++)
  begin
    `ifdef DYNAMIC_CONFIG_AND_WIDTH
      valid_bundle_o[i] = rrPacket_i[i].valid & laneActive_i[i];
    `else
      valid_bundle_o[i] = rrPacket_i[i].valid;
    `endif
  end
 end
`endif
endmodule
