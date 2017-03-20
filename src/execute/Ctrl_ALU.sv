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
 1.
 2. flags_o has following fields:
    (.) Executed  :"bit-2"
    (.) Exception :"bit-1"
    (.) Mispredict:"bit-0"
***************************************************************************/


module Ctrl_ALU (
    input  [`SIZE_DATA-1:0]        data1_i,
    input  [`SIZE_DATA-1:0]        data2_i,
    input  [`SIZE_IMMEDIATE-1:0]   immd_i,
    input  [`SIZE_OPCODE_I-1:0]    opcode_i,
    input  [`SIZE_PC-1:0]          predNPC_i,
    input                          predDir_i,
    input  [`SIZE_PC-1:0]          pc_i,

    output [`SIZE_PC-1:0]          result_o,
    output [`SIZE_PC-1:0]          nextPC_o,
    output                         direction_o,
    output exeFlgs                 flags_o
    );



reg  [`SIZE_PC-1:0]              result;
reg  [`SIZE_PC-1:0]              nextPC;
reg                              direction;
exeFlgs                          flags;


assign result_o                = result;
assign nextPC_o                = nextPC;
assign direction_o             = direction;
assign flags_o                 = flags;


always_comb
begin:ALU_OPERATION
    reg  [`SIZE_PC-1:0]   pc_p8;
    reg  [`SIZE_PC-1:0]   pc_pImmd;
    reg  [`SIZE_DATA-1:0] sign_ex_immd;
    reg                   mispredict;

    sign_ex_immd = {{14{immd_i[`SIZE_IMMEDIATE-1]}}, immd_i, 2'h0};
    mispredict  = 1'b0;  //Default to avoid latch RBRC: 07/12/2013

    pc_p8     = pc_i + 8;
    pc_pImmd  = pc_i + 8 + sign_ex_immd;

    result    = 0;
    nextPC    = 0;
    direction = 0;
    flags     = 0;

    case(opcode_i)

        `JUMP:
        begin
            direction       = 1'h1;
            nextPC          = (pc_i & 32'hF000_0000) | 
                              ({4'b0000,predNPC_i[`SIZE_TARGET-1:0], 2'h0});
                   
            flags.executed  = 1'h1;
            flags.isControl = 1'h1;
        end

        `JAL:
        begin
            direction       = 1'h1;
            result          = pc_p8;
            nextPC          = (pc_i & 32'hF000_0000) | 
                              ({4'b0000,predNPC_i[`SIZE_TARGET-1:0],2'b00});
            flags.executed  = 1'h1;
            flags.destValid = 1'h1;
            flags.isControl = 1'h1;
        end

        `JR:
        begin
            direction        = 1'h1;
            mispredict       = (data1_i != predNPC_i);
            nextPC           = data1_i;
            flags.mispredict = mispredict;
            flags.executed   = 1'h1;
            flags.isControl  = 1'h1;
        end

        `JALR:
        begin
            direction       = 1'h1;
            result           = pc_p8;
            mispredict       = (data1_i != predNPC_i);
            nextPC           = data1_i;
            flags.mispredict = mispredict;
            flags.executed   = 1'h1;
            flags.destValid  = 1'h1;
            flags.isControl  = 1'h1;
        end

        `BEQ:
        begin
            direction         = (data1_i == data2_i);
            nextPC            = (direction) ? pc_pImmd : pc_p8;
            mispredict        = (direction != predDir_i);

            flags.mispredict  = mispredict;
            flags.executed    = 1'h1;
            flags.isPredicted = 1'h1;
            flags.isControl   = 1'h1;
        end

        `BNE:
        begin
            direction         = (data1_i != data2_i);
            nextPC            = (direction) ? pc_pImmd : pc_p8;
            mispredict        = (direction != predDir_i);
            flags.mispredict  = mispredict;
            flags.executed    = 1'h1;
            flags.isPredicted = 1'h1;
            flags.isControl   = 1'h1;
        end

        `BLEZ:
        begin
            direction         = ((data1_i[31] == 1'b1) || (data1_i == 0));
            nextPC            = (direction) ? pc_pImmd : pc_p8;
            mispredict        = (direction != predDir_i);
            flags.mispredict  = mispredict;
            flags.executed    = 1'h1;
            flags.isPredicted = 1'h1;
            flags.isControl   = 1'h1;
        end

        `BGTZ:
        begin
            direction         = ((data1_i[31] == 1'b0) && (data1_i != 0));
            nextPC            = (direction) ? pc_pImmd : pc_p8;
            mispredict        = (direction != predDir_i);
            flags.mispredict  = mispredict;
            flags.executed    = 1'h1;
            flags.isPredicted = 1'h1;
            flags.isControl   = 1'h1;
        end

        `BLTZ:
        begin
            direction         = (data1_i[31] == 1'b1);
            nextPC            = (direction) ? pc_pImmd : pc_p8;
            mispredict        = (direction != predDir_i);
            flags.mispredict  = mispredict;
            flags.executed    = 1'h1;
            flags.isPredicted = 1'h1;
            flags.isControl   = 1'h1;
        end

        `BGEZ:
        begin
            direction         = ((data1_i[31] == 1'b0) || (data1_i == 0));
            nextPC            = (direction) ? pc_pImmd : pc_p8;
            mispredict        = (direction != predDir_i);
            flags.mispredict  = mispredict;
            flags.executed    = 1'h1;
            flags.isPredicted = 1'h1;
            flags.isControl   = 1'h1;
        end

        `BC1F:
        begin
            flags.executed    = 1'h1;
        end

        `BC1T:
        begin
            flags.executed   = 1'h1;
        end

        `RET:
        begin
            direction       = 1'h1;
            nextPC          = predNPC_i; 
            //nextPC          = (pc_i & 32'hF000_0000) | 
            //                  ({4'b0000,predNPC_i[`SIZE_TARGET-1:0], 2'h0});
                   
            // target isn't saved in the btb so this always mispredicts
            flags.mispredict  = 1'h1;
            flags.isPredicted = 1'h1;
            flags.executed  = 1'h1;
            flags.isControl = 1'h1;
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
