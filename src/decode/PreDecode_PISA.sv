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


module PreDecode_PISA(

    input  fs2Pkt                    fs2Packet_i,

`ifdef DYNAMIC_CONFIG_AND_WIDTH
    input                            laneActive_i,
`endif
    output                           ctrlInst_o,
    output [`SIZE_PC-1:0]            predNPC_o,
    output [`BRANCH_TYPE-1:0]        ctrlType_o,
    output                           condBranch_o
    );

logic [`SIZE_OPCODE_P-1:0]         opcode;
logic [`SIZE_IMMEDIATE-1:0]        immed;
logic [`SIZE_TARGET-1:0]           target;
logic [`SIZE_RS-1:0]               rs;

/* wires and regs definition for combinational logic. */
reg  [`BRANCH_TYPE-1:0]            ctrlType;
reg  [`SIZE_PC-1:0]                predNPC;
reg                                ctrlInst;

assign ctrlInst_o = ctrlInst;
assign predNPC_o    = predNPC;
assign ctrlType_o   = ctrlType;
assign condBranch_o = (ctrlType == `COND_BRANCH);

/* Extract pieces from the instructions.  */
assign opcode  = fs2Packet_i.inst[`SIZE_INSTRUCTION-1:`SIZE_INSTRUCTION-`SIZE_OPCODE_P];
assign immed   = fs2Packet_i.inst[`SIZE_IMMEDIATE-1:0];
assign target  = fs2Packet_i.inst[`SIZE_TARGET-1:0];
assign rs      = fs2Packet_i.inst[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:
                                         `SIZE_RT+`SIZE_RD+`SIZE_RU];

always_comb
begin : PRE_DECODE_FOR_CTRL
    reg [`SIZE_DATA-1:0] sign_ex_immd;

    predNPC    = 0;
    ctrlType   = 0;
    ctrlInst = 1'b0;

    sign_ex_immd = {{14{immed[`SIZE_IMMEDIATE-1]}}, immed, 2'h0};

    case(opcode)

        `JUMP:
        begin
            predNPC    = (fs2Packet_i.pc & 32'hF0000000) |
                         ({4'h0,target, 2'h0});
            ctrlType   = `JUMP_TYPE;
            ctrlInst   = 1'b1;
        end

        `JAL:
        begin
            predNPC    = (fs2Packet_i.pc & 32'hF0000000) |
                         ({4'h0,target, 2'h0});
            ctrlType   = `CALL;
            ctrlInst   = 1'b1;
        end

        `JR:
        begin
            predNPC    = fs2Packet_i.takenPC;
            ctrlInst   = 1'b1;
            ctrlType   = (rs == `REG_RA) ? `RETURN : `JUMP_TYPE;
        end

        `JALR:
        begin
            predNPC    = fs2Packet_i.pc + 32'h8;
            ctrlType   = `CALL;
            ctrlInst   = 1'b1;
        end

        `BEQ:
        begin
            if (fs2Packet_i.predDir)
            begin
                predNPC  = fs2Packet_i.pc + 8 + sign_ex_immd;
            end

            else
            begin
                predNPC  = fs2Packet_i.pc + 8;
            end

            ctrlType   = `COND_BRANCH;
            ctrlInst   = 1'b1;
        end

        `BNE:
        begin
            if (fs2Packet_i.predDir)
            begin
                predNPC  = fs2Packet_i.pc + 8 + sign_ex_immd;
            end

            else
            begin
                predNPC  = fs2Packet_i.pc + 8;
            end

            ctrlType   = `COND_BRANCH;
            ctrlInst   = 1'b1;
        end

        `BLEZ:
        begin
            if (fs2Packet_i.predDir)
            begin
                predNPC  = fs2Packet_i.pc + 8 + sign_ex_immd;
            end

            else
            begin
                predNPC  = fs2Packet_i.pc + 8;
            end

            ctrlType   = `COND_BRANCH;
            ctrlInst   = 1'b1;
        end

        `BGTZ:
        begin
            if (fs2Packet_i.predDir)
            begin
                predNPC  = fs2Packet_i.pc + 8 + sign_ex_immd;
            end

            else
            begin
                predNPC  = fs2Packet_i.pc + 8;
            end

            ctrlType   = `COND_BRANCH;
            ctrlInst   = 1'b1;
        end

        `BLTZ:
        begin
            if (fs2Packet_i.predDir)
            begin
                predNPC  = fs2Packet_i.pc + 8 + sign_ex_immd;
            end

            else
            begin
                predNPC  = fs2Packet_i.pc + 8;
            end

            ctrlType   = `COND_BRANCH;
            ctrlInst   = 1'b1;
        end

        `BGEZ:
        begin
            if (fs2Packet_i.predDir)
            begin
                predNPC  = fs2Packet_i.pc + 8 + sign_ex_immd;
            end

            else
            begin
                predNPC  = fs2Packet_i.pc + 8;
            end

            ctrlType   = `COND_BRANCH;
            ctrlInst   = 1'b1;
        end

        `BC1T:
        begin
            predNPC    = fs2Packet_i.pc + 8 + sign_ex_immd;
            ctrlType   = `COND_BRANCH;
            ctrlInst   = 1'b1;
        end

        `BC1F:
        begin
            predNPC    = fs2Packet_i.pc + 8 + sign_ex_immd;
            ctrlType   = `COND_BRANCH;
            ctrlInst   = 1'b1;
        end

        `RET:
        begin
            predNPC    = (fs2Packet_i.pc & 32'hF0000000) |
                         ({4'h0,target, 2'h0});
            // JUMP_TYPE causes target to be saved in the BTB.
            // CALL would push to RAS
            // RETURN would pop RAS
            // COND_BRANCH is all that's left
            ctrlType   = `COND_BRANCH;
            ctrlInst   = 1'b1;
        end

    endcase
end


endmodule
