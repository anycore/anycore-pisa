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


module l2_dcache #(
    parameter MISS_PENALTY = 2
) (
    input                                   clk,
    input                                   reset,

  `ifdef DATA_CACHE
    input      [31:0]                       mem_addr0_i,
    output reg [`DCACHE_LINE_SIZE-1:0]      mem_data0_o,
    input                                   mem_re0_i,
    output                                  mem_data_ready0_o,
    output reg [`DCACHE_TAG_BITS-1:0]       mem_tag0_o,
    output reg [`DCACHE_INDEX_BITS-1:0]     mem_index0_o,

    input      [31:0]                       mem_wr_addr0_i,
    input                                   mem_we0_i,
  
    input      [`SIZE_DATA-1:0]             mem_wr_data0_i,
    input      [3:0]                        mem_wr_byte_en0_i,
    output reg                              mem_wr_done0_o,
  `endif

    input                                   run_i
);

`ifdef DATA_CACHE
 
	/* Store */
  logic [`SIZE_DATA-1:0] mem_wr_data0;

  always @ (*)
  begin
    if(mem_we0_i)
    begin
    	mem_wr_data0 = `READ_WORD(mem_wr_addr0_i);
      if(mem_wr_addr0_i[31])
        $display("Out of range address 0x%08x\n",mem_wr_addr0_i);
    end
    else
      mem_wr_data0 = 32'h0;


	  if (mem_wr_byte_en0_i[0])
	  	mem_wr_data0[7:0]                      = mem_wr_data0_i[7:0];

	  if (mem_wr_byte_en0_i[1])
	  	mem_wr_data0[15:8]                     = mem_wr_data0_i[15:8];

	  if (mem_wr_byte_en0_i[2])
	  	mem_wr_data0[23:16]                    = mem_wr_data0_i[23:16];

	  if (mem_wr_byte_en0_i[3])
	  	mem_wr_data0[31:24]                    = mem_wr_data0_i[31:24];
  end

  always_ff @ (posedge clk)
  begin
  	/* Write request */
    if(reset)
      mem_wr_done0_o  <=  1'b0;
  	else if (mem_we0_i)
  	begin
  		`WRITE_WORD(mem_wr_data0, mem_wr_addr0_i);
      mem_wr_done0_o  <=  1'b1;
  	end
    else
      mem_wr_done0_o  <=  1'b0;
  end
  
  `ifdef PRINT
    always @ (posedge clk)
    begin
        if (~reset & mem_we0_i)
        begin
            $fwrite(top.sim_fd, "[%0d] [D$ Write] mem_wr_addr0: 0x%08x ", `CYCLE_COUNT, mem_wr_addr0_i);
            $fwrite(top.sim_fd, "mem_wr_data0: 0x%08x\n", mem_wr_data0_i);
            $fwrite(top.sim_fd, "mem_wr_byte_en0: 0x%b\n", mem_wr_byte_en0_i);
        end
    end
  `endif



  /* Load */
  logic  [`SIZE_PC-1:0]                          dcache_prev_addr;
  logic                                          mem_re0_i_d;
  
  integer i;
  
  initial
  begin
      mem_re0_i_d =  1'b0;
  end
  
  always @ (posedge clk)
  begin
      if (mem_re0_i)
      begin
          dcache_prev_addr                <= mem_addr0_i;
      end
      mem_re0_i_d <=  mem_re0_i;
  end
  
  
  /* D-Cache */
  // Read again whenever there is a new read request 
  // as data might have been changed by stores
  always @ (mem_re0_i_d)
  begin
      if(dcache_prev_addr[31] != 1'b1)
      begin
        for (i = 0; i < `DCACHE_WORDS_IN_LINE; i = i + 1)
        begin
            mem_data0_o[i*`SIZE_DATA+:`SIZE_DATA]             = `READ_WORD(dcache_prev_addr+i*4);
        end
      end
      else
      begin
        // Return fake data without reading if address is out of range.
        // Since only half the main memory is instantiated, out of range 
        // addresses will cause a crash. Out of range addresses are generated 
        // due to out of order execution.
        // NOTE: This is a problem only in simulation and not on a real system.
        for (i = 0; i < `DCACHE_WORDS_IN_LINE; i = i + 1)
        begin
            mem_data0_o[i*`SIZE_DATA+:`SIZE_DATA]             = 32'hdeadbeef;
        end
      end
  
      mem_tag0_o      = dcache_prev_addr[`DCACHE_INDEX_BITS+`DCACHE_OFFSET_BITS+2 +: `DCACHE_TAG_BITS];
      mem_index0_o    = dcache_prev_addr[`DCACHE_OFFSET_BITS+2 +: `DCACHE_INDEX_BITS];
  end
 
  /* D-Cache Delay */
  reg [MISS_PENALTY-1:0]              dc_delay_cnt = 0;
  
  always @ (posedge clk)
  begin
      if (reset)
      begin
          dc_delay_cnt                       <= 0;
          /* $display("[%0t] reset (dc_delay_cnt: %d)", $time, dc_delay_cnt); */
      end
  
      else if (~run_i)
      begin
          /* $display("[%0t] run (dc_delay_cnt: %d)", $time, dc_delay_cnt); */
      end
  
      else if (mem_re0_i)
      begin
          dc_delay_cnt                       <= 1;
          /* $display("[%0t] mem_re0_i (dc_delay_cnt: %d)", $time, dc_delay_cnt); */
      end
  
      else if (|dc_delay_cnt)
      begin
          dc_delay_cnt                       <= dc_delay_cnt << 1;
          /* $display("[%0t] dc_delay_cnt (dc_delay_cnt: %d)", $time, dc_delay_cnt); */
      end
  end
  
  assign mem_data_ready0_o               = dc_delay_cnt[MISS_PENALTY-1];
  
  
  `ifdef PRINT
    always @ (posedge clk)
    begin
        if (mem_addr0_i != dcache_prev_addr)
        begin
            $fwrite(top.sim_fd, "[%0d] [I$ Read] mem_addr0: 0x%08x ", `CYCLE_COUNT, mem_addr0_i);
            $fwrite(top.sim_fd, "mem_data0: 0x%x\n", mem_data0_o);
        end
    end
  `endif

`endif //`ifdef DATA_CACHE

endmodule


