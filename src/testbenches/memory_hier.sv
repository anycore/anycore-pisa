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


module memory_hier (
	input                                   icClk,
	input                                   dcClk,
	input                                   reset,

	input  [31:0]                           icPC_i   [0:`FETCH_WIDTH-1],
	input                                   icInstReq_i,
	output reg [63:0]                       icInst_o [0:`FETCH_WIDTH-1],

`ifdef INST_CACHE
  input  [`ICACHE_SIZE_MEM_ADDR-1:0]      ic2memReqAddr_i,      // memory read address
  input                                   ic2memReqValid_i,     // memory read enable
  output [`ICACHE_TAG_BITS-1:0]           mem2icTag_o,          // tag of the incoming data
  output [`ICACHE_INDEX_BITS-1:0]         mem2icIndex_o,        // index of the incoming data
  output [`ICACHE_LINE_SIZE-1:0]          mem2icData_o,         // requested data
  output                                  mem2icRespValid_o,    // requested data is ready
`endif

`ifdef DATA_CACHE
  // cache-to-memory interface for Loads
  input  [`DCACHE_SIZE_MEM_ADDR-1:0]      dc2memLdAddr_i,  // memory read address
  input                                   dc2memLdValid_i, // memory read enable

  // memory-to-cache interface for Loads
  output [`DCACHE_TAG_BITS-1:0]           mem2dcLdTag_o,       // tag of the incoming datadetermine
  output [`DCACHE_INDEX_BITS-1:0]         mem2dcLdIndex_o,     // index of the incoming data
  output [`DCACHE_LINE_SIZE-1:0]          mem2dcLdData_o,      // requested data
  output                                  mem2dcLdValid_o,     // indicates the requested data is ready

  // cache-to-memory interface for stores
  input  [`DCACHE_SIZE_ST_ADDR-1:0]       dc2memStAddr_i,  // memory write address
  input  [`SIZE_DATA-1:0]                 dc2memStData_i,  // memory write address
  input  [3:0]                            dc2memStByteEn_i,  // memory write address
  input                                   dc2memStValid_i, // memory write enable

  // memory-to-cache interface for stores
  output                                  mem2dcStComplete_o,
`endif

	input  [31:0]                           ldAddr_i,
	output reg [31:0]                       ldData_o,
	input                                   ldEn_i,

	input  [31:0]                           stAddr_i,
	input  [31:0]                           stData_i,
	input  [3:0]                            stEn_i
);


//`ifndef SCRATCH_PAD
/* I-Cache */
//always_ff @(negedge icClk)
always_comb
begin
	int i;
	for (i = 0; i < `FETCH_WIDTH; i++)
	begin
    if(icInstReq_i)
    begin
  		icInst_o[i]   = {`READ_OPCODE(icPC_i[i]), `READ_OPERAND(icPC_i[i])};
    end
	end
end



reg  [31:0]   stData;

/* D-Cache */
always_comb
begin
	/* Load */
	if (ldEn_i)
	begin
		ldData_o   = `READ_WORD(ldAddr_i);
	end

	/* Store */
  if(|stEn_i)
  	stData = `READ_WORD(stAddr_i);
  else
    stData = 32'h0;


	if (stEn_i[0])
		stData[7:0]                      = stData_i[7:0];

	if (stEn_i[1])
		stData[15:8]                     = stData_i[15:8];

	if (stEn_i[2])
		stData[23:16]                    = stData_i[23:16];

	if (stEn_i[3])
		stData[31:24]                    = stData_i[31:24];
end

always_ff @ (posedge dcClk)
begin
	/* Write request */
	if (~reset && |stEn_i)
	begin
		`WRITE_WORD(stData, stAddr_i);
	end
end
//`endif

`ifdef INST_CACHE
  l2_icache l2_inst_cache (
      .clk                                (icClk),
      .reset                              (reset),
  
      .run_i                              (1'b1),
  
      .mem_addr0_i                        ({ic2memReqAddr_i, {(`ICACHE_OFFSET_BITS+`ICACHE_BYTE_OFFSET_LOG){1'b0}}}),
      .mem_re0_i                          (ic2memReqValid_i),
  
      .mem_data0_o                        (mem2icData_o),
      .mem_data_ready0_o                  (mem2icRespValid_o),
      .mem_tag0_o                         (mem2icTag_o),
      .mem_index0_o                       (mem2icIndex_o)
  );
`endif

`ifdef DATA_CACHE
  l2_dcache l2_data_cache (
      .clk                                (dcClk),
      .reset                              (reset),
  
      .run_i                              (1'b1),
  
      .mem_addr0_i                        ({dc2memLdAddr_i, {(`DCACHE_OFFSET_BITS+`DCACHE_BYTE_OFFSET_LOG){1'b0}}}),
      .mem_re0_i                          (dc2memLdValid_i),
  
      .mem_data0_o                        (mem2dcLdData_o),
      .mem_data_ready0_o                  (mem2dcLdValid_o),
      .mem_tag0_o                         (mem2dcLdTag_o),
      .mem_index0_o                       (mem2dcLdIndex_o),


      .mem_wr_addr0_i                     ({dc2memStAddr_i, {`DCACHE_BYTE_OFFSET_LOG{1'b0}}}),
      .mem_we0_i                          (dc2memStValid_i),
  
      .mem_wr_data0_i                     (dc2memStData_i),
      .mem_wr_byte_en0_i                  (dc2memStByteEn_i),
      .mem_wr_done0_o                     (mem2dcStComplete_o)

  );
`endif
endmodule


