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


module Decode_PISA (

`ifdef DYNAMIC_CONFIG_AND_WIDTH
    input                             laneActive_i,
`endif

    input  decPkt                     decPacket_i,

    output renPkt                     ibPacket0_o,
    output renPkt                     ibPacket1_o
    );


/* Wires and regs definition for combinational logic. */
wire [`SIZE_INSTRUCTION-1:0]            instruction;
wire [`SIZE_PC-1:0]                     predNPC;

wire [`SIZE_OPCODE_P-1:0]               opcode;

reg                                     invalidate;

reg                                     valid_0;
reg [`SIZE_OPCODE_P-1:0]                opcode_0;
reg [`SIZE_RMT_LOG:0]                   instLogical1_0;
reg [`SIZE_RMT_LOG:0]                   instLogical2_0;
reg [`SIZE_RMT_LOG:0]                   instDest_0;
reg [`SIZE_SPECIAL_REG-1:0]             instSrcHL_0;
reg [`SIZE_SPECIAL_REG-1:0]             instDestHL_0;
reg [`SIZE_IMMEDIATE:0]                 instImmediate_0;
// Should be SIZE_TARGET and not SIZE_PC
// Difference should be offset when using instTarget_0
// RBRC: 07/11/2013
reg [`SIZE_TARGET-1:0]                  instTarget_0; 
reg [`INST_TYPES_LOG-1:0]               instFU_0;
reg [`LDST_TYPES_LOG-1:0]               instldstSize_0;
reg                                     instLoad_0;
reg                                     instStore_0;

reg                                     valid_1;
reg [`SIZE_OPCODE_P-1:0]                opcode_1;
reg [`SIZE_RMT_LOG:0]                   instLogical1_1;
reg [`SIZE_RMT_LOG:0]                   instLogical2_1;
reg [`SIZE_RMT_LOG:0]                   instDest_1;
reg [`SIZE_SPECIAL_REG-1:0]             instSrcHL_1;
reg [`SIZE_SPECIAL_REG-1:0]             instDestHL_1;
reg [`SIZE_IMMEDIATE:0]                 instImmediate_1;
reg [`SIZE_PC-1:0]                      instTarget_1;
reg [`INST_TYPES_LOG-1:0]               instFU_1;
reg [`LDST_TYPES_LOG-1:0]               instldstSize_1;
reg                                     instLoad_1;
reg                                     instStore_1;


always_comb
begin
    ibPacket0_o.seqNo         = decPacket_i.seqNo;
    ibPacket0_o.logDest       = instDest_0[`SIZE_RMT_LOG:1]; 
    ibPacket0_o.logDestValid = instDest_0[0];
    ibPacket0_o.logSrc1       = instLogical1_0[`SIZE_RMT_LOG:1]; 
    ibPacket0_o.logSrc1Valid = instLogical1_0[0];
    ibPacket0_o.logSrc2       = instLogical2_0[`SIZE_RMT_LOG:1]; 
    ibPacket0_o.logSrc2Valid = instLogical2_0[0];
    ibPacket0_o.pc             = decPacket_i.pc;
    ibPacket0_o.opcode         = opcode_0[`SIZE_OPCODE_I-1:0];
    ibPacket0_o.fu             = instFU_0;
    ibPacket0_o.immed          = instImmediate_0[`SIZE_IMMEDIATE:1];
    ibPacket0_o.immedValid    = instImmediate_0[0];
    ibPacket0_o.isLoad        = instLoad_0;
    ibPacket0_o.isStore       = instStore_0;
    ibPacket0_o.ldstSize      = instldstSize_0;
    ibPacket0_o.ctrlType      = decPacket_i.ctrlType;
    ibPacket0_o.ctiID         = decPacket_i.ctiID;
    ibPacket0_o.predNPC       = {{(`SIZE_PC-`SIZE_TARGET){1'b0}},instTarget_0}; //instTarget_0 is `SIZE_TARGET wide
    ibPacket0_o.predDir       = decPacket_i.predDir;
    ibPacket0_o.valid          = valid_0;

    ibPacket1_o.seqNo         = decPacket_i.seqNo;
    ibPacket1_o.logDest       = instDest_1[`SIZE_RMT_LOG:1]; 
    ibPacket1_o.logDestValid = instDest_1[0];
    ibPacket1_o.logSrc1       = instLogical1_1[`SIZE_RMT_LOG:1]; 
    ibPacket1_o.logSrc1Valid = instLogical1_1[0];
    ibPacket1_o.logSrc2       = instLogical2_1[`SIZE_RMT_LOG:1]; 
    ibPacket1_o.logSrc2Valid = instLogical2_1[0];
    ibPacket1_o.pc             = decPacket_i.pc;
    ibPacket1_o.opcode         = opcode_1[`SIZE_OPCODE_I-1:0];
    ibPacket1_o.fu             = instFU_1;
    ibPacket1_o.immed          = instImmediate_1[`SIZE_IMMEDIATE:1];
    ibPacket1_o.immedValid    = instImmediate_1[0];
    ibPacket1_o.isLoad        = instLoad_1;
    ibPacket1_o.isStore       = instStore_1;
    ibPacket1_o.ldstSize      = instldstSize_1;
    ibPacket1_o.ctrlType      = decPacket_i.ctrlType;
    ibPacket1_o.ctiID         = decPacket_i.ctiID;
    ibPacket1_o.predNPC         = instTarget_1;
    ibPacket1_o.predDir       = decPacket_i.predDir;
    ibPacket1_o.valid          = valid_1 & decPacket_i.valid;
end


/* Following extracts instructions from the packet, follows by opcode extraction
 * from the instructions.
 */
assign instruction           = decPacket_i.inst;
assign predNPC               = decPacket_i.predNPC;


/* Following extracts source registers, destination register, immediate field and
 * target address from instruction. Bit-0 of each wire is set to 1 if the field
 * is valid for the corresponding instruction.
 */
assign opcode     = instruction[`SIZE_INSTRUCTION-1:`SIZE_INSTRUCTION-`SIZE_OPCODE_P];

always @(*)
begin
  invalidate      = 1'h0;

  valid_0        = decPacket_i.valid;
  opcode_0        = opcode;
  instLogical1_0    = 0;
  instLogical2_0    = 0;
  instDest_0        = 0;
  instSrcHL_0        = 0;
  instDestHL_0        = 0;
  instImmediate_0    = 0;
  instTarget_0        = 0;
  instFU_0        = 0;
  instldstSize_0    = 0;
  instLoad_0        = 0;
  instStore_0        = 0;

  valid_1        = 0;
  opcode_1        = 0;
  instLogical1_1        = 0;
  instLogical2_1        = 0;
  instDest_1            = 0;
  instSrcHL_1           = 0;
  instDestHL_1          = 0;
  instImmediate_1       = 0;
  instTarget_1          = 0;
  instFU_1              = 0;
  instldstSize_1        = 0;
  instLoad_1            = 0;
  instStore_1           = 0;


  case(opcode)
    `JUMP: begin
          instLogical1_0  = 0;
          instLogical2_0  = 0;
          instDest_0      = 0;
          instImmediate_0 = 0;
          instTarget_0     = instruction[`SIZE_TARGET-1:0];
          instFU_0        = `CONTROL_TYPE;
        end

  `JAL: begin
          instLogical1_0  = 0;
          instLogical2_0  = 0;
          instDest_0      = {5'b11111,1'b1};
          instImmediate_0 = 0;
      instTarget_0    = instruction[`SIZE_TARGET-1:0];
          instFU_0        = `CONTROL_TYPE;
        end

   `JR: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = 0;
          instDest_0      = 0;
          instImmediate_0 = 0;
          instTarget_0    = decPacket_i.predNPC;
          instFU_0        = `CONTROL_TYPE;
        end

 `JALR: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = 0;
          instDest_0      = {instruction[`SIZE_RD+`SIZE_RU-1:`SIZE_RU],1'b1};
          instImmediate_0 = 0;
          instTarget_0    = decPacket_i.predNPC;
          instFU_0        = `CONTROL_TYPE;
        end

  `BEQ: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instDest_0      = 0;
          instImmediate_0 = {instruction[`SIZE_IMMEDIATE-1:0],1'b1};
          instTarget_0    = decPacket_i.predNPC;
          instFU_0        = `CONTROL_TYPE;
        end

  `BNE: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instDest_0      = 0;
          instImmediate_0 = {instruction[`SIZE_IMMEDIATE-1:0],1'b1};
          instTarget_0    = decPacket_i.predNPC;
          instFU_0        = `CONTROL_TYPE;
        end

 `BLEZ: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = 0;
          instDest_0      = 0;
          instImmediate_0 = {instruction[`SIZE_IMMEDIATE-1:0],1'b1};
          instTarget_0    = decPacket_i.predNPC;
          instFU_0        = `CONTROL_TYPE;
        end

 `BGTZ: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = 0;
          instDest_0      = 0;
          instImmediate_0 = {instruction[`SIZE_IMMEDIATE-1:0],1'b1};
          instTarget_0    = decPacket_i.predNPC;
          instFU_0        = `CONTROL_TYPE;
        end

 `BLTZ: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = 0;
          instDest_0      = 0;
          instImmediate_0 = {instruction[`SIZE_IMMEDIATE-1:0],1'b1};
          instTarget_0    = decPacket_i.predNPC;
          instFU_0        = `CONTROL_TYPE;
        end

 `BGEZ: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = 0;
          instDest_0      = 0;
          instImmediate_0 = {instruction[`SIZE_IMMEDIATE-1:0],1'b1};
          instTarget_0    = decPacket_i.predNPC;
          instFU_0        = `CONTROL_TYPE;
        end

    // This instruction is similar to a JUMP; however, the target can
    // change. Thus, the target shouldn't be stored in the BTB. This isn't a
    // real PISA instruction. Rather, the testbench uses it to return from a
    // subroutine (e.g. init_registers) 
    `RET: begin
          instLogical1_0  = 0;
          instLogical2_0  = 0;
          instDest_0      = 0;
          instImmediate_0 = 0;
          instTarget_0    = decPacket_i.predNPC;//instruction[`SIZE_TARGET-1:0];
          instFU_0        = `CONTROL_TYPE;
        end

   `LB: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = 0;
          instDest_0      = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instImmediate_0 = {instruction[`SIZE_IMMEDIATE-1:0],1'b1};
          instTarget_0    = 0;
          instFU_0        = `MEMORY_TYPE;
          instldstSize_0  = `LDST_BYTE;
          instLoad_0      = 1'b1;
        end

  `LBU: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = 0;
          instDest_0      = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instImmediate_0 = {instruction[`SIZE_IMMEDIATE-1:0],1'b1};
          instTarget_0    = 0;
          instFU_0        = `MEMORY_TYPE;
          instldstSize_0  = `LDST_BYTE;
          instLoad_0      = 1'b1;
        end

   `LH: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = 0;
          instDest_0      = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instImmediate_0 = {instruction[`SIZE_IMMEDIATE-1:0],1'b1};
          instTarget_0    = 0;
          instFU_0        = `MEMORY_TYPE;
          instldstSize_0  = `LDST_HALF_WORD;
          instLoad_0      = 1'b1;
        end

  `LHU: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = 0;
          instDest_0      = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instImmediate_0 = {instruction[`SIZE_IMMEDIATE-1:0],1'b1};
          instTarget_0    = 0;
          instFU_0        = `MEMORY_TYPE;
          instldstSize_0  = `LDST_HALF_WORD;
          instLoad_0      = 1'b1;
        end

   `LW: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = 0;
          instDest_0      = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instImmediate_0 = {instruction[`SIZE_IMMEDIATE-1:0],1'b1};
          instTarget_0    = 0;
          instFU_0        = `MEMORY_TYPE;
          instldstSize_0  = `LDST_WORD;
          instLoad_0      = 1'b1;
        end

   `LWL: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};  // SRC 2 and DEST are the same
          instDest_0      = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instImmediate_0 = {instruction[`SIZE_IMMEDIATE-1:0],1'b1};
          instTarget_0    = 0;
          instFU_0        = `MEMORY_TYPE;
          instldstSize_0  = `LDST_WORD;
          instLoad_0      = 1'b1;
        end

   `LWR: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};  // SRC 2 and DEST are the same
          instDest_0      = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instImmediate_0 = {instruction[`SIZE_IMMEDIATE-1:0],1'b1};
          instTarget_0    = 0;
          instFU_0        = `MEMORY_TYPE;
          instldstSize_0  = `LDST_WORD;
          instLoad_0      = 1'b1;
        end

  `DLW: begin
      // inst-fission performed for DLW
      //$display("DLW instruction occured, PC:%h",pc);
      opcode_0      = `DLW_L;
      instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = 0;
          instDest_0      = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instImmediate_0 = {instruction[`SIZE_IMMEDIATE-1:0],1'b1};
          instTarget_0    = 0;
          instFU_0        = `MEMORY_TYPE;
          instldstSize_0  = `LDST_WORD;
          instLoad_0      = 1'b1;

      valid_1       = 1'b1;
      opcode_1        = `DLW_H;
          instLogical1_1  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_1  = 0;
          instDest_1      = {(instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU]+1),1'b1};
          instImmediate_1 = {(instruction[`SIZE_IMMEDIATE-1:0]+4),1'b1};
          instTarget_1    = 0;
          instFU_1        = `MEMORY_TYPE;
          instldstSize_1  = `LDST_WORD;
          instLoad_1      = 1'b1;
    end

   `SB: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instDest_0      = 0;
          instImmediate_0 = {instruction[`SIZE_IMMEDIATE-1:0],1'b1};
          instTarget_0    = 0;
          instFU_0        = `MEMORY_TYPE;
          instldstSize_0  = `LDST_BYTE;
          instStore_0     = 1'b1;
        end

   `SH: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instDest_0      = 0;
          instImmediate_0 = {instruction[`SIZE_IMMEDIATE-1:0],1'b1};
          instTarget_0    = 0;
          instFU_0        = `MEMORY_TYPE;
          instldstSize_0  = `LDST_HALF_WORD;
          instStore_0     = 1'b1;
        end

   `SW: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instDest_0      = 0;
          instImmediate_0 = {instruction[`SIZE_IMMEDIATE-1:0],1'b1};
          instTarget_0    = 0;
          instFU_0        = `MEMORY_TYPE;
          instldstSize_0  = `LDST_WORD;
          instStore_0     = 1'b1;
        end

   `SWL: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instDest_0      = 0;
          instImmediate_0 = {instruction[`SIZE_IMMEDIATE-1:0],1'b1};
          instTarget_0    = 0;
          instFU_0        = `MEMORY_TYPE;
          instldstSize_0  = `LDST_WORD;
          instStore_0     = 1'b1;
        end

   `SWR: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instDest_0      = 0;
          instImmediate_0 = {instruction[`SIZE_IMMEDIATE-1:0],1'b1};
          instTarget_0    = 0;
          instFU_0        = `MEMORY_TYPE;
          instldstSize_0  = `LDST_WORD;
          instStore_0     = 1'b1;
        end

  `DSW: begin
      // inst-fission performed for DSW
          opcode_0        = `DSW_L;
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instDest_0      = 0;
          instImmediate_0 = {instruction[`SIZE_IMMEDIATE-1:0],1'b1};
          instTarget_0    = 0;
          instFU_0        = `MEMORY_TYPE;
          instldstSize_0  = `LDST_WORD;
          instStore_0     = 1'b1;

      valid_1       = 1'b1;
      opcode_1        = `DSW_H;
          instLogical1_1  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_1  = {(instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU]+1),1'b1};
          instDest_1      = 0;
          instImmediate_1 = {(instruction[`SIZE_IMMEDIATE-1:0]+4),1'b1};
          instTarget_1    = 0;
          instFU_1        = `MEMORY_TYPE;
          instldstSize_1  = `LDST_WORD;
          instStore_1     = 1'b1;
    end

  `ADD: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instDest_0      = {instruction[`SIZE_RD+`SIZE_RU-1:`SIZE_RU],1'b1};
          instImmediate_0 = 0;
          instTarget_0    = 0;
          instFU_0        = `SIMPLE_TYPE;
        end

 `ADDU: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instDest_0      = {instruction[`SIZE_RD+`SIZE_RU-1:`SIZE_RU],1'b1};
          instImmediate_0 = 0;
          instTarget_0    = 0;
          instFU_0        = `SIMPLE_TYPE;
        end

  `SUB: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instDest_0      = {instruction[`SIZE_RD+`SIZE_RU-1:`SIZE_RU],1'b1};
          instImmediate_0 = 0;
          instTarget_0    = 0;
          instFU_0        = `SIMPLE_TYPE;
        end

 `SUBU: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instDest_0      = {instruction[`SIZE_RD+`SIZE_RU-1:`SIZE_RU],1'b1};
          instImmediate_0 = 0;
          instTarget_0    = 0;
          instFU_0        = `SIMPLE_TYPE;
        end

 `MULT: begin
      // inst-fission performed for MULT
      //$display("MULT instruction occured, PC:%h",pc);
      opcode_0      = `MULT_L;
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instDest_0      = {`SIZE_RMT_LOG'd32,1'b1};
          instImmediate_0 = 0;
          instTarget_0    = 0;
          instFU_0        = `COMPLEX_TYPE;
          //instDestHL_0    = 2'b10;

      valid_1      = 1'b1;
      opcode_1        = `MULT_H;
          instLogical1_1  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_1  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instDest_1      = {`SIZE_RMT_LOG'd33,1'b1};
          instImmediate_1 = 0;
          instTarget_1    = 0;
          instFU_1        = `COMPLEX_TYPE;
          //instDestHL_1    = 2'b11;
        end

`MULTU: begin
      // inst-fission performed for MULTU
      //$display("MULTU instruction occured, PC:%h",pc);
      opcode_0      = `MULTU_L;
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instDest_0      = {`SIZE_RMT_LOG'd32,1'b1};
          instImmediate_0 = 0;
          instTarget_0    = 0;
          instFU_0        = `COMPLEX_TYPE;
          //instDestHL_0    = 2'b10;

      valid_1      = 1'b1;
      opcode_1        = `MULTU_H;
          instLogical1_1  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_1  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instDest_1      = {`SIZE_RMT_LOG'd33,1'b1};
          instImmediate_1 = 0;
          instTarget_1    = 0;
          instFU_1        = `COMPLEX_TYPE;
          //instDestHL_0    = 2'b11;
        end

  `DIV: begin
      // inst-fission performed for DIV
      //$display("DIV instruction occured, PC:%h",pc);
      opcode_0      = `DIV_L;
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instDest_0      = {`SIZE_RMT_LOG'd32,1'b1};
          instImmediate_0 = 0;
          instTarget_0    = 0;
          instFU_0        = `COMPLEX_TYPE;
          //instDestHL_0    = 2'b10;

      valid_1      = 1'b1;
      opcode_1        = `DIV_H;
          instLogical1_1  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_1  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instDest_1      = {`SIZE_RMT_LOG'd33,1'b1};
          instImmediate_1 = 0;
          instTarget_1    = 0;
          instFU_1        = `COMPLEX_TYPE;
          //instDestHL_1    = 2'b11;
        end

 `DIVU: begin
      // inst-fission performed for DIVU
      //$display("DIVU instruction occured, PC:%h",pc);
      opcode_0      = `DIVU_L;
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instDest_0      = {`SIZE_RMT_LOG'd32,1'b1};
          instImmediate_0 = 0;
          instTarget_0    = 0;
          instFU_0        = `COMPLEX_TYPE;
          //instDestHL_0    = 2'b10;

      valid_1         = 1'b1;
          opcode_1        = `DIVU_H;
          instLogical1_1  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_1  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instDest_1      = {`SIZE_RMT_LOG'd33,1'b1};
          instImmediate_1 = 0;
          instTarget_1    = 0;
          instFU_1        = `COMPLEX_TYPE;
          //instDestHL_1    = 2'b11;
        end

 `MFHI: begin
          instLogical1_0  = {`SIZE_RMT_LOG'd33,1'b1};
          instLogical2_0  = 0;
          instDest_0      = {instruction[`SIZE_RD+`SIZE_RU-1:`SIZE_RU],1'b1};
          instImmediate_0 = 0;
          instTarget_0    = 0;
          instFU_0        = `SIMPLE_TYPE;
      //instSrcHL_0     = 2'b11;
        end

 `MFLO: begin
          instLogical1_0  = {`SIZE_RMT_LOG'd32,1'b1};
          instLogical2_0  = 0;
          instDest_0      = {instruction[`SIZE_RD+`SIZE_RU-1:`SIZE_RU],1'b1};
          instImmediate_0 = 0;
          instTarget_0    = 0;
          instFU_0        = `SIMPLE_TYPE;
      //instSrcHL_0     = 2'b10;
        end

 `MTHI: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = 0;
          instDest_0      = {`SIZE_RMT_LOG'd33,1'b1};
          instImmediate_0 = 0;
          instTarget_0    = 0;
          instFU_0        = `SIMPLE_TYPE;
          //instDestHL_0    = 2'b11;
        end

 `MTLO: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = 0;
          instDest_0      = {`SIZE_RMT_LOG'd32,1'b1};
          instImmediate_0 = 0;
          instTarget_0    = 0;
          instFU_0        = `SIMPLE_TYPE;
          //instDestHL_0    = 2'b10;
        end

  `AND_: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instDest_0      = {instruction[`SIZE_RD+`SIZE_RU-1:`SIZE_RU],1'b1};
          instImmediate_0 = 0;
          instTarget_0    = 0;
          instFU_0        = `SIMPLE_TYPE;
        end

   `OR: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instDest_0      = {instruction[`SIZE_RD+`SIZE_RU-1:`SIZE_RU],1'b1};
          instImmediate_0 = 0;
          instTarget_0    = 0;
          instFU_0        = `SIMPLE_TYPE;
        end

  `XOR: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instDest_0      = {instruction[`SIZE_RD+`SIZE_RU-1:`SIZE_RU],1'b1};
          instImmediate_0 = 0;
          instTarget_0    = 0;
          instFU_0        = `SIMPLE_TYPE;
        end

  `NOR: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instDest_0      = {instruction[`SIZE_RD+`SIZE_RU-1:`SIZE_RU],1'b1};
          instImmediate_0 = 0;
          instTarget_0    = 0;
          instFU_0        = `SIMPLE_TYPE;
        end

  `SLL: begin
          instLogical1_0  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = 0;
          instDest_0      = {instruction[`SIZE_RD+`SIZE_RU-1:`SIZE_RU],1'b1};
          instImmediate_0 = {instruction[`SIZE_RU-1:0],1'b1};
          instTarget_0    = 0;
          instFU_0        = `SIMPLE_TYPE;
        end

  `SRL: begin
          instLogical1_0  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = 0;
          instDest_0      = {instruction[`SIZE_RD+`SIZE_RU-1:`SIZE_RU],1'b1};
          instImmediate_0 = {instruction[`SIZE_RU-1:0],1'b1};
          instTarget_0    = 0;
          instFU_0        = `SIMPLE_TYPE;
        end

  `SRA: begin
          instLogical1_0  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = 0;
          instDest_0      = {instruction[`SIZE_RD+`SIZE_RU-1:`SIZE_RU],1'b1};
          instImmediate_0 = {instruction[`SIZE_RU-1:0],1'b1};
          instTarget_0    = 0;
          instFU_0        = `SIMPLE_TYPE;
        end

  `SLT: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instDest_0      = {instruction[`SIZE_RD+`SIZE_RU-1:`SIZE_RU],1'b1};
          instImmediate_0 = 0;
          instTarget_0    = 0;
          instFU_0        = `SIMPLE_TYPE;
        end

 `SLTU: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instDest_0      = {instruction[`SIZE_RD+`SIZE_RU-1:`SIZE_RU],1'b1};
          instImmediate_0 = 0;
          instTarget_0    = 0;
          instFU_0        = `SIMPLE_TYPE;
        end

 `ADDI: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = 0;
          instDest_0      = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instImmediate_0 = {instruction[`SIZE_IMMEDIATE-1:0],1'b1};
          instTarget_0    = 0;
          instFU_0        = `SIMPLE_TYPE;
        end

`ADDIU: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = 0;
          instDest_0      = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instImmediate_0 = {instruction[`SIZE_IMMEDIATE-1:0],1'b1};
          instTarget_0    = 0;
          instFU_0        = `SIMPLE_TYPE;
        end

 `ANDI: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = 0;
          instDest_0      = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instImmediate_0 = {instruction[`SIZE_IMMEDIATE-1:0],1'b1};
          instTarget_0    = 0;
          instFU_0        = `SIMPLE_TYPE;
        end

  `ORI: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = 0;
          instDest_0      = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instImmediate_0 = {instruction[`SIZE_IMMEDIATE-1:0],1'b1};
          instTarget_0    = 0;
          instFU_0        = `SIMPLE_TYPE;
        end

 `XORI: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = 0;
          instDest_0      = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instImmediate_0 = {instruction[`SIZE_IMMEDIATE-1:0],1'b1};
          instTarget_0    = 0;
          instFU_0        = `SIMPLE_TYPE;
        end

 `SLLV: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instDest_0      = {instruction[`SIZE_RD+`SIZE_RU-1:`SIZE_RU],1'b1};
          instImmediate_0 = 0;
          instTarget_0    = 0;
          instFU_0        = `SIMPLE_TYPE;
        end

 `SRLV: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instDest_0      = {instruction[`SIZE_RD+`SIZE_RU-1:`SIZE_RU],1'b1};
          instImmediate_0 = 0;
          instTarget_0    = 0;
          instFU_0        = `SIMPLE_TYPE;
        end

 `SRAV: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instDest_0      = {instruction[`SIZE_RD+`SIZE_RU-1:`SIZE_RU],1'b1};
          instImmediate_0 = 0;
          instTarget_0    = 0;
          instFU_0        = `SIMPLE_TYPE;
        end

 `SLTI: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = 0;
          instDest_0      = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instImmediate_0 = {instruction[`SIZE_IMMEDIATE-1:0],1'b1};
          instTarget_0    = 0;
          instFU_0        = `SIMPLE_TYPE;
        end

`SLTIU: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = 0;
          instDest_0      = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instImmediate_0 = {instruction[`SIZE_IMMEDIATE-1:0],1'b1};
          instTarget_0    = 0;
          instFU_0        = `SIMPLE_TYPE;
        end

  `NOP: begin
          instLogical1_0  = 0;
          instLogical2_0  = 0;
          instDest_0      = 0;
          instImmediate_0 = 0;
          instTarget_0    = 0;
          instFU_0        = `SIMPLE_TYPE;
        end

  `LUI: begin
      instLogical1_0  = 0;
          instLogical2_0  = 0;
          instDest_0      = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instImmediate_0 = {instruction[`SIZE_IMMEDIATE-1:0],1'b1};
          instTarget_0    = 0;
          instFU_0        = `SIMPLE_TYPE;
    end

 `SYSCALL: begin
      //$display("\nDecode: PC:%x SYSCALL Encountered...",pc);
      instLogical1_0  = 0;
          instLogical2_0  = 0;
          instDest_0      = 0;
          instImmediate_0 = 0;
          instTarget_0    = 0;
          instFU_0        = `COMPLEX_TYPE;
       end

 `TOGGLE_S: begin
          instLogical1_0  = 0;
          instLogical2_0  = 0;
          instDest_0      = 1;    // Non writable register 0 as destination
          instImmediate_0 = 0;
          instTarget_0    = 0;
          instFU_0        = `SIMPLE_TYPE;
        end

 `TOGGLE_C: begin
          instLogical1_0  = 0;
          instLogical2_0  = 0;
          instDest_0      = 1;    // Non writable register 0 as destination
          instImmediate_0 = 0;
          instTarget_0    = 0;
          instFU_0        = `COMPLEX_TYPE;
        end

 default: begin
          valid_0         = 1'h0;
       //$display("\nWARNING: PC:%x Opcode %x Not Found in Decode Unit",pc,opcode);
         //$finish;
      end
  endcase

end


endmodule

