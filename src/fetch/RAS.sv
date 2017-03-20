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


module RAS(
	input                       clk,
	input                       reset,

	input                       recoverFlag_i,
	input                       exceptionFlag_i,

	input                       stall_i,

	input [`SIZE_PC-1:0]        pc_i,

	input  [`BRANCH_TYPE-1:0]   updateBrType_i,
	input  [`SIZE_PC-1:0]       updatePC_i,
	input                       updateEn_i,

	input                       fs2RecoverFlag_i,
	input                       fs2MissedCall_i,

	input [`SIZE_PC-1:0]        fs2CallPC_i,
	input                       fs2MissedReturn_i,

	input                       pop_i,
	input                       push_i,
	input  [`SIZE_PC-1:0]       pushAddr_i,

	output [`SIZE_PC-1:0]       addrRAS_o
	);


// non-speculative ras signals ///////
reg  [`SIZE_RAS_LOG-1:0] arch_tos;
reg  [`SIZE_RAS_LOG-1:0] arch_tos_c;
reg  [`SIZE_RAS_LOG-1:0] arch_tos_next;
reg                      arch_push;
reg                      arch_pop;

// speculative ras signals ///////////
wire                     spec_push;
wire                     spec_pop;

reg  [`SIZE_RAS_LOG-1:0] spec_tos;
wire [`SIZE_RAS_LOG-1:0] spec_tos_n;
reg  [`SIZE_RAS_LOG-1:0] spec_tos_c;
reg  [`SIZE_RAS_LOG-1:0] spec_tos_CP;

reg                      stack_we;
reg  [`SIZE_PC-1:0]      stack_data_in;
wire [`SIZE_PC-1:0]      stack_data_out;


/* Output the target address in case of return instruction. */
assign addrRAS_o    =  stack_data_out;


/* Following combinational logic calculates the next spec_tos and the address to be
 * pushed on stack in case of call instruction. */
assign spec_push  = (push_i & ~stall_i & ~fs2RecoverFlag_i) | (fs2RecoverFlag_i & fs2MissedCall_i);
assign spec_pop   = (pop_i  & ~stall_i & ~fs2RecoverFlag_i) | (fs2RecoverFlag_i & fs2MissedReturn_i);

always_comb
begin : NEW_SPEC_TOS

	if (spec_push)
	begin
		spec_tos_c   = spec_tos + 1'h1;
	end
	
	else if (spec_pop)
	begin
		spec_tos_c   = spec_tos - 1'h1;
	end

	else if (fs2RecoverFlag_i & ~stall_i)
	begin
		spec_tos_c   = spec_tos_CP;
	end

	else
	begin
		spec_tos_c   = spec_tos;
	end
end



/* Following updates spec_tos and stack at every clock cycle. */
always_ff @(posedge clk or posedge reset)
begin : UPDATE_RAS
	if (reset)
	begin
		spec_tos        <= 0;
		spec_tos_CP     <= 0;
	end

	else if (recoverFlag_i || exceptionFlag_i)
	begin
		spec_tos        <= arch_tos_next;
		spec_tos_CP     <= arch_tos_next;
    end

    else
    begin
		spec_tos        <= spec_tos_c;

		if (fs2RecoverFlag_i & ~stall_i)
		begin
			spec_tos_CP   <= spec_tos_c;
		end

		else
		begin
			spec_tos_CP   <= spec_tos;
		end
	end
end

always_comb
begin
	stack_we      = 1'h0;
	stack_data_in = pushAddr_i;

	if (~reset && ~stall_i)
	begin

		if (fs2RecoverFlag_i && fs2MissedCall_i)
		begin
			stack_we      = 1'h1;
			stack_data_in = (fs2CallPC_i + 8);
		end

		else if (push_i && ~fs2RecoverFlag_i)
		begin
			stack_we      = 1'h1;
			stack_data_in = pushAddr_i;
		end
	end
end


assign spec_tos_n        = (fs2RecoverFlag_i & ~stall_i) ? spec_tos_CP : spec_tos;


// non-speculative ras signals ////////////////////////////
reg  [`SIZE_PC-1:0]     arch_pc;

// only push/pop when the cti queue issues an update
always_comb
begin
    arch_push   = updateEn_i & (updateBrType_i == `CALL);
    arch_pop    = updateEn_i & (updateBrType_i == `RETURN);

    if (updateEn_i & (updateBrType_i == `CALL))
        arch_tos_next   = arch_tos + 1;
    else if (updateEn_i & (updateBrType_i == `RETURN))
        arch_tos_next   = arch_tos - 1;
    else
        arch_tos_next   = arch_tos;

    arch_pc     = updatePC_i + 8;
    arch_tos_c  = arch_tos + 1;
end

always_ff @(posedge clk)
begin
    if (reset)
    begin
        arch_tos    <= 0;
    end

    else
    begin
        arch_tos    <= arch_tos_next;
    end
end
///////////////////////////////////////////////////////////

//RAM_1R2W #(
RAS_RAM #(
	.DEPTH      (`SIZE_RAS),
	.INDEX      (`SIZE_RAS_LOG),
	.WIDTH      (`SIZE_PC)
	)
	stack (

	.clk        (clk),
	.reset      (reset),
  .recoverFlag_i(recoverFlag_i|exceptionFlag_i),

	.addr0_i    (spec_tos_n),
	.data0_o    (stack_data_out),

	.addr0wr_i  (spec_tos_c),
	.data0wr_i  (stack_data_in),
	.we0_i      (stack_we),

	.addr1wr_i  (arch_tos_c),
	.data1wr_i  (arch_pc),
	.we1_i      (arch_push)
	);

endmodule
