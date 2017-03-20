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
 1. result_o contains the result of the arithmetic operation.
 2. flags has following fields:
     (.) Executed  :"bit-2"
     (.) Exception :"bit-1"
     (.) Mispredict:"bit-0"
***************************************************************************/


module Simple_ALU (

    input  fuPkt                     exePacket_i,
    output reg                       toggleFlag_o, 

    input  [`SIZE_DATA-1:0]             data1_i,
    input  [`SIZE_DATA-1:0]             data2_i,
    input  [`SIZE_IMMEDIATE-1:0]        immd_i,
    input  [`SIZE_OPCODE_I-1:0]         opcode_i,

    output wbPkt                     wbPacket_o
    );


reg  [`SIZE_DATA-1:0]               result;
exeFlgs                          flags;


always_comb
begin
    wbPacket_o          = 0;

    /* wbPacket_o.seqNo    = exePacket_S.seqNo; */
    wbPacket_o.flags    = flags;
    wbPacket_o.logDest  = exePacket_i.logDest;
    wbPacket_o.phyDest  = exePacket_i.phyDest;
    wbPacket_o.destData = result;
    wbPacket_o.alID     = exePacket_i.alID;
    wbPacket_o.valid    = exePacket_i.valid;
end

always_comb
begin:ALU_OPERATION
    reg        [`SIZE_DATA-1:0]  sign_ex_immd;
    reg signed [`SIZE_DATA-1:0]  data_signed1;
    reg                          cout;

    sign_ex_immd   = {{16{immd_i[`SIZE_IMMEDIATE-1]}}, immd_i};

    result    = 0;
    cout      = 0;
    flags   = 0;
    toggleFlag_o    = 1'b0;

    case (opcode_i)

        `ADD:
        begin
            {cout,result}       = data1_i + data2_i;
            flags.exception   = cout;
            flags.executed    = 1'h1;
            flags.destValid   = 1'h1;
        end
        `ADDI:
        begin
            {cout,result}       = data1_i + sign_ex_immd;
            flags.exception   = cout;
            flags.executed    = 1'h1;
            flags.destValid   = 1'h1;
        end

        `ADDU:
        begin
            {cout,result}       = data1_i + data2_i;
            flags.executed    = 1'h1;
            flags.destValid   = 1'h1;
        end

        `ADDIU:
        begin
            {cout,result}       = data1_i + sign_ex_immd;
            flags.executed    = 1'h1;
            flags.destValid   = 1'h1;
        end

        `SUB:
        begin
            {cout,result}       = data1_i - data2_i;
            flags.exception   = cout;
            flags.executed    = 1'h1;
            flags.destValid   = 1'h1;
        end

        `SUBU:
        begin
            {cout,result}       = data1_i - data2_i;
            flags.executed    = 1'h1;
            flags.destValid   = 1'h1;
        end

        `MFHI:
        begin
            result              = data1_i;
            flags.executed    = 1'h1;
            flags.destValid   = 1'h1;
        end

        `MTHI:
        begin
            result              = data1_i;
            flags.executed    = 1'h1;
            flags.destValid   = 1'h1;
        end

        `MFLO:
        begin
            result              = data1_i;
            flags.executed    = 1'h1;
            flags.destValid   = 1'h1;
        end

        `MTLO:
        begin
            result              = data1_i;
            flags.executed    = 1'h1;
            flags.destValid   = 1'h1;
        end

        `AND_:
        begin
            result              = data1_i & data2_i;
            flags.executed    = 1'h1;
            flags.destValid   = 1'h1;
        end

        `ANDI:
        begin
            result              = data1_i & {16'b0,immd_i};
            flags.executed    = 1'h1;
            flags.destValid   = 1'h1;
        end

        `OR:
        begin
            result              = data1_i | data2_i;
            flags.executed    = 1'h1;
            flags.destValid   = 1'h1;
        end

        `ORI:
        begin
            result              = data1_i | {16'b0,immd_i};
            flags.executed    = 1'h1;
            flags.destValid   = 1'h1;
        end

        `XOR:
        begin
            result              = data1_i ^ data2_i;
            flags.executed    = 1'h1;
            flags.destValid   = 1'h1;
        end

        `XORI:
        begin
            result              = data1_i ^ {16'b0,immd_i};
            flags.executed    = 1'h1;
            flags.destValid   = 1'h1;
        end

        `NOR:
        begin
            result              = ~(data1_i | data2_i);
            flags.executed    = 1'h1;
            flags.destValid   = 1'h1;
        end

        `SLL:
        begin
            result              = data1_i << immd_i;
            flags.executed    = 1'h1;
            flags.destValid   = 1'h1;
        end

        `SLLV:
        begin
            result              = data2_i << (data1_i & 32'h1f);
            flags.executed    = 1'h1;
            flags.destValid   = 1'h1;
        end

        `SRL:
        begin
            result              = data1_i >> immd_i;
            flags.executed    = 1'h1;
            flags.destValid   = 1'h1;
        end

        `SRLV:
        begin
            result              = data2_i >> (data1_i & 32'h1f);
            flags.executed    = 1'h1;
            flags.destValid   = 1'h1;
        end

        `SRA:
        begin
            data_signed1        = data1_i;
            result              = data_signed1 >>> immd_i;
            flags.executed    = 1'h1;
            flags.destValid   = 1'h1;
        end

        `SRAV:
        begin
            data_signed1        = data2_i;
            result              = data_signed1 >>> (data1_i & 32'h1f);
            flags.executed    = 1'h1;
            flags.destValid   = 1'h1;
        end

        `SLT:
        begin
            case ({data1_i[31],data2_i[31]})
                2'b00: result     = (data1_i < data2_i);
                2'b01: result     = 1'b0;
                2'b10: result     = 1'b1;
                2'b11: result     = (data1_i < data2_i);
            endcase

            flags.executed    = 1'h1;
            flags.destValid   = 1'h1;
        end

        `SLTI:
        begin
            case ({data1_i[31], sign_ex_immd[31]})
                2'b00: result     = (data1_i < sign_ex_immd);
                2'b01: result     = 1'b0;
                2'b10: result     = 1'b1;
                2'b11: result     = (data1_i < sign_ex_immd);
            endcase

            flags.executed    = 1'h1;
            flags.destValid   = 1'h1;
        end

        `SLTU:
        begin
            result              = (data1_i < data2_i);
            flags.executed    = 1'h1;
            flags.destValid   = 1'h1;
        end

        `SLTIU:
        begin
            result              = (data1_i < {16'b0,immd_i});
            flags.executed    = 1'h1;
            flags.destValid   = 1'h1;
        end

        `LUI:
        begin
            result              = {immd_i,16'b0};
            flags.executed    = 1'h1;
            flags.destValid   = 1'h1;
        end

        `TOGGLE_S:
        begin
            result              = 0;
            flags.executed    = 1'h1;
            flags.destValid   = 1'h1; // Writes 0 to register 0
            toggleFlag_o      = 1'b1;
        end
        `NOP:
        begin
            flags.executed    = 1'h1;
        end
    endcase
end

endmodule
