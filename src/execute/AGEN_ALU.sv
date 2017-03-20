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


/* Algorithm
 1. result_o contains the result of the address calculation operation.
***************************************************************************/


module AGEN_ALU (
	input [`SIZE_DATA-1:0]         data1_i,
	input [`SIZE_DATA-1:0]         data2_i,
	input [`SIZE_IMMEDIATE-1:0]    immd_i,
	input [`SIZE_OPCODE_I-1:0]     opcode_i,

	output [`SIZE_DATA-1:0]        address_o,
	output [`LDST_TYPES_LOG-1:0]   ldstSize_o,
	output exeFlgs                 flags_o
	);


reg [`SIZE_DATA-1:0]       address;
reg [`LDST_TYPES_LOG-1:0]  ldstSize;


assign address_o   = address;
assign ldstSize_o  = ldstSize;


always_comb
begin:ALU_OPERATION
	reg [`SIZE_DATA-1:0] sign_ex_immd;

	sign_ex_immd = {{16{immd_i[`SIZE_IMMEDIATE-1]}}, immd_i};

	address   = 0;
	ldstSize  = 0;
	flags_o   = 0;

	case(opcode_i)

		`LB:
		begin
			address   = data1_i + sign_ex_immd;
			ldstSize  = `LDST_BYTE;
			flags_o.ldSign       = 1'h1;
			flags_o.destValid = 1'h1;
		end

		`LBU:
		begin
			address   = data1_i + sign_ex_immd;
			ldstSize  = `LDST_BYTE;
			flags_o.destValid = 1'h1;
		end

		`LH:
		begin
			address   = data1_i + sign_ex_immd;
			ldstSize  = `LDST_HALF_WORD;
			flags_o.ldSign       = 1'h1;
			flags_o.destValid = 1'h1;
		end

		`LHU:
		begin
			address   = data1_i + sign_ex_immd;
			ldstSize  = `LDST_HALF_WORD;
			flags_o.destValid = 1'h1;
		end

		`LW:
		begin
			address   = data1_i + sign_ex_immd;
			ldstSize  = `LDST_WORD;
			flags_o.destValid = 1'h1;
		end

		`DLW_H:
		begin
			address   = data1_i + sign_ex_immd;
			ldstSize  = `LDST_WORD;
			flags_o.destValid = 1'h1;
		end

		`DLW_L:
		begin
			address   = data1_i + sign_ex_immd;
			ldstSize  = `LDST_WORD;
			flags_o.isFission    = 1'h1;
			flags_o.destValid = 1'h1;
		end

		`L_S:
		begin
			address   = data1_i + sign_ex_immd;
			ldstSize  = 0;
			flags_o.destValid = 1'h1;
		end

		`L_D:
		begin
			address   = data1_i + sign_ex_immd;
			ldstSize  = 0;
			flags_o.destValid = 1'h1;
		end

		`LWL:
		begin
			address   = data1_i + sign_ex_immd;
			ldstSize  = 0;
			flags_o.destValid = 1'h1;
		end

		`LWR:
		begin
			address   = data1_i + sign_ex_immd;
			ldstSize  = 0;
			flags_o.destValid = 1'h1;
		end

		`SB:
		begin
			address   = data1_i + sign_ex_immd;
			ldstSize  = `LDST_BYTE;
			flags_o.executed = 1'h1;
		end

		`SH:
		begin
			address   = data1_i + sign_ex_immd;
			ldstSize  = `LDST_HALF_WORD;
			flags_o.executed = 1'h1;
		end

		`SW:
		begin
			address   = data1_i + sign_ex_immd;
			ldstSize  = `LDST_WORD;
			flags_o.executed = 1'h1;
		end

		`DSW_H:
		begin
			address   = data1_i + sign_ex_immd;
			ldstSize  = `LDST_WORD;
			flags_o.executed = 1'h1;
		end

		`DSW_L:
		begin
			address   = data1_i + sign_ex_immd;
			ldstSize  = `LDST_WORD;
			flags_o.isFission = 1'h1;
			flags_o.executed  = 1'h1;
		end

		`DSZ:
		begin
			address   = data1_i + sign_ex_immd;
			ldstSize  = 0;
		end

		`S_S:
		begin
			address   = data1_i + sign_ex_immd;
			ldstSize  = 0;
		end

		`S_D:
		begin
			address   = data1_i + sign_ex_immd;
			ldstSize  = 0;
		end

		`SWL:
		begin
			address   = data1_i + sign_ex_immd;
			ldstSize  = 0;
		end

		`SWR:
		begin
			address   = data1_i + sign_ex_immd;
			ldstSize  = 0;
		end

    // NOTE: Need this default to make the case statement
    // full case and stopping synthesis from screwing up
    // RBRC
    default:
    begin
    end
	endcase
end

endmodule
